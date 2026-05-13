import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/use_cases/create_new_support_ticket_use_case.dart';
import 'package:open_vts/features/support/domain/use_cases/load_support_assignees_use_case.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_state.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_validators.dart';

class NewTicketArgs {
  const NewTicketArgs({
    required this.role,
    this.preSelectedUser,
    this.forMyTickets = false,
  });

  final SupportRole role;
  final AdminUserListItem? preSelectedUser;
  final bool forMyTickets;

  @override
  bool operator ==(Object other) {
    return other is NewTicketArgs &&
        other.role == role &&
        other.forMyTickets == forMyTickets &&
        other.preSelectedUser?.id == preSelectedUser?.id;
  }

  @override
  int get hashCode => Object.hash(role, forMyTickets, preSelectedUser?.id);
}

class NewTicketController extends StateNotifier<NewTicketState> {
  NewTicketController({
    required NewTicketArgs args,
    required LoadSupportAssigneesUseCase loadAssigneesUseCase,
    required CreateNewSupportTicketUseCase createTicketUseCase,
  })  : _args = args,
        _loadAssigneesUseCase = loadAssigneesUseCase,
        _createTicketUseCase = createTicketUseCase,
        super(
          NewTicketState(
            role: args.role,
            selectedCategory: _categoryOptions(args.role).first,
            selectedPriority: _priorityOptions(args.role).first,
            selectedUser: _preselected(args.preSelectedUser),
          ),
        ) {
    unawaited(loadAssignees());
  }

  final NewTicketArgs _args;
  final LoadSupportAssigneesUseCase _loadAssigneesUseCase;
  final CreateNewSupportTicketUseCase _createTicketUseCase;

  SupportRole get role => _args.role;
  bool get forMyTickets => _args.forMyTickets;

  List<String> get categoryOptions => _categoryOptions(role);
  List<String> get priorityOptions => _priorityOptions(role);

  bool get showAttachmentSection {
    if (role == SupportRole.admin) return forMyTickets;
    return role == SupportRole.superadmin;
  }

  Future<void> loadAssignees() async {
    if (role == SupportRole.user) return;
    if (role == SupportRole.admin && (forMyTickets || _args.preSelectedUser != null)) {
      return;
    }

    state = state.copyWith(
      loadingAssignees: true,
      submitSucceeded: false,
      clearError: true,
    );
    final result = await _loadAssigneesUseCase(role);
    state = result.when(
      success: (items) => role == SupportRole.superadmin
          ? state.copyWith(admins: items, loadingAssignees: false)
          : state.copyWith(users: items, loadingAssignees: false),
      failure: (error) => state.copyWith(
        loadingAssignees: false,
        errorMessage: _message(error),
      ),
    );
  }

  void selectUser(SupportAssigneeOption? user) {
    state = state.copyWith(selectedUser: user, clearError: true);
  }

  void selectAdmin(SupportAssigneeOption? admin) {
    state = state.copyWith(selectedAdmin: admin, clearError: true);
  }

  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category, clearError: true);
  }

  void selectPriority(String? priority) {
    state = state.copyWith(selectedPriority: priority, clearError: true);
  }

  Future<void> pickAttachment() async {
    if (state.submitting) return;
    if (role == SupportRole.superadmin && state.attachments.length >= 5) {
      state = state.copyWith(errorMessage: 'Max 5 files allowed');
      return;
    }
    final file = await pickSingleFilePayload();
    if (file == null) return;
    if (role == SupportRole.superadmin && file.bytes.length > 5 * 1024 * 1024) {
      state = state.copyWith(errorMessage: 'Max file size is 5MB');
      return;
    }
    state = state.copyWith(
      attachments: [...state.attachments, file],
      clearError: true,
    );
  }

  void removeAttachment(PickedFilePayload file) {
    if (state.submitting) return;
    state = state.copyWith(
      attachments: state.attachments.where((item) => item != file).toList(),
      clearError: true,
    );
  }

  Future<bool> submit({required String title, required String message}) async {
    if (state.submitting) return false;

    final validationError = validate(title: title, message: message);
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(
      submitting: true,
      submitSucceeded: false,
      clearError: true,
    );

    final draft = SupportCreateTicketDraft(
      title: title.trim(),
      message: message.trim(),
      category: state.selectedCategory,
      priority: state.selectedPriority,
      userId: role == SupportRole.admin && !forMyTickets
          ? state.selectedUser?.id
          : null,
      adminId: role == SupportRole.superadmin ? state.selectedAdmin?.id : null,
      attachments: showAttachmentSection
          ? state.attachments
          : const <PickedFilePayload>[],
    );

    final result = await _createTicketUseCase(
      role: role,
      forMyTickets: forMyTickets,
      draft: draft,
    );

    state = result.when(
      success: (_) => state.copyWith(submitting: false, submitSucceeded: true),
      failure: (error) => state.copyWith(
        submitting: false,
        submitSucceeded: false,
        errorMessage: _message(error),
      ),
    );
    return state.submitSucceeded;
  }

  String? validate({required String title, required String message}) {
    return NewTicketValidators.validateAssignee(
          state.selectedUser,
          state.selectedAdmin,
          role,
          forMyTickets,
        ) ??
        NewTicketValidators.validateTitle(title, role) ??
        NewTicketValidators.validateMessage(message, role) ??
        NewTicketValidators.validateCategory(state.selectedCategory) ??
        NewTicketValidators.validatePriority(state.selectedPriority) ??
        NewTicketValidators.validateAttachments(state.attachments, role);
  }

  static SupportAssigneeOption? _preselected(AdminUserListItem? user) {
    if (user == null) return null;
    return SupportAssigneeOption(
      id: user.id,
      name: user.fullName.isNotEmpty ? user.fullName : user.email,
      role: 'USER',
      email: user.email.isEmpty ? null : user.email,
      subtitle: user.email.isEmpty ? null : user.email,
    );
  }

  static List<String> _categoryOptions(SupportRole role) {
    switch (role) {
      case SupportRole.admin:
        return const <String>[
          'INSTALLATION',
          'SERVER',
          'BILLING',
          'MAPS',
          'TECHNICAL',
          'GENERAL',
          'OTHER',
        ];
      case SupportRole.user:
        return const <String>[
          'SERVER',
          'NOTIFICATION',
          'INSTALLATION',
          'MAPS',
          'BILLING',
          'OTHERS',
        ];
      case SupportRole.superadmin:
        return const <String>['BILLING', 'TECHNICAL', 'OTHER'];
    }
  }

  static List<String> _priorityOptions(SupportRole role) {
    switch (role) {
      case SupportRole.admin:
        return const <String>['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
      case SupportRole.user:
      case SupportRole.superadmin:
        return const <String>['LOW', 'MEDIUM', 'HIGH'];
    }
  }

  static String _message(AppError error) => error.message;
}
