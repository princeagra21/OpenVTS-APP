import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/models/admin_list_item.dart';
import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/new_ticket/new_ticket_state.dart';
import 'package:open_vts/features/support/new_ticket/new_ticket_validators.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';

class NewTicketController extends ChangeNotifier {
  late final NewTicketState _state;

  NewTicketController({
    required this.role,
    required this.config,
    required this.repository,
    this.preSelectedUser,
    this.forMyTickets = false,
  }) {
    _state = NewTicketState(
      role: role,
      selectedCategory: _categoryOptions.first,
      selectedPriority: _priorityOptions.first,
      titleController: TextEditingController(),
      messageController: TextEditingController(),
    );

    if (role == SupportRole.admin) {
      if (forMyTickets) {
        _state = _state.copyWith(selectedUser: null);
      } else if (preSelectedUser != null) {
        _state = _state.copyWith(selectedUser: preSelectedUser);
      } else {
        loadUsers();
      }
    }

    if (role == SupportRole.superadmin) {
      loadAdmins();
    }
  }

  final SupportRole role;
  final SupportRoleConfig config;
  final SupportRepositoryAdapter repository;
  final AdminUserListItem? preSelectedUser;
  final bool forMyTickets;

  NewTicketState _state;
  NewTicketState get state => _state;

  final CancelToken _cancelToken = CancelToken();

  List<String> get _categoryOptions {
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

  List<String> get _priorityOptions {
    switch (role) {
      case SupportRole.admin:
        return const <String>['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
      case SupportRole.user:
        return const <String>['LOW', 'MEDIUM', 'HIGH'];
      case SupportRole.superadmin:
        return const <String>['LOW', 'MEDIUM', 'HIGH'];
    }
  }

  bool get showAttachmentSection {
    if (role == SupportRole.admin) {
      return forMyTickets;
    }
    return role == SupportRole.superadmin;
  }

  void dispose() {
    _cancelToken.cancel('NewTicketController disposed');
    _state.titleController?.dispose();
    _state.messageController?.dispose();
  }

  Future<void> loadUsers() async {
    _state = _state.copyWith(loadingAssignees: true);
    notifyListeners();

    try {
      final result = await AppContainer.instance.adminUsersRepository.getUsers(
        page: 1,
        limit: 200,
        cancelToken: _cancelToken,
      );

      result.when(
        success: (items) {
          _state = _state.copyWith(
            users: items,
            loadingAssignees: false,
          );
          notifyListeners();
        },
        failure: (error) {
          _state = _state.copyWith(loadingAssignees: false);
          notifyListeners();
          _handleAssigneeError(error);
        },
      );
    } catch (_) {
      _state = _state.copyWith(loadingAssignees: false);
      notifyListeners();
      _handleAssigneeError(null);
    }
  }

  Future<void> loadAdmins() async {
    _state = _state.copyWith(loadingAssignees: true);
    notifyListeners();

    try {
      final result = await AppContainer.instance.superadminRepository.getAdmins(
        page: 1,
        limit: 200,
        cancelToken: _cancelToken,
      );

      result.when(
        success: (items) {
          _state = _state.copyWith(
            admins: items,
            loadingAssignees: false,
          );
          notifyListeners();
        },
        failure: (error) {
          _state = _state.copyWith(loadingAssignees: false);
          notifyListeners();
          _handleAssigneeError(error);
        },
      );
    } catch (_) {
      _state = _state.copyWith(loadingAssignees: false);
      notifyListeners();
      _handleAssigneeError(null);
    }
  }

  void _handleAssigneeError(Object? error) {
    if (_state.assigneeErrorShown) return;
    _state = _state.copyWith(assigneeErrorShown: true);
    // Error handling will be done in the screen
  }

  void selectUser(AdminUserListItem? user) {
    _state = _state.copyWith(selectedUser: user);
    notifyListeners();
  }

  void selectAdmin(AdminListItem? admin) {
    _state = _state.copyWith(selectedAdmin: admin);
    notifyListeners();
  }

  void selectCategory(String? category) {
    _state = _state.copyWith(selectedCategory: category);
    notifyListeners();
  }

  void selectPriority(String? priority) {
    _state = _state.copyWith(selectedPriority: priority);
    notifyListeners();
  }

  Future<void> pickAttachment() async {
    if (_state.submitting) return;

    if (role == SupportRole.superadmin && _state.attachments.length >= 5) {
      // Warning will be shown in screen
      return;
    }

    final file = await pickSingleFilePayload();
    if (file == null) return;

    if (role == SupportRole.superadmin && file.bytes.length > 5 * 1024 * 1024) {
      // Warning will be shown in screen
      return;
    }

    final newAttachments = List<PickedFilePayload>.from(_state.attachments)
      ..add(file);
    _state = _state.copyWith(attachments: newAttachments);
    notifyListeners();
  }

  void removeAttachment(PickedFilePayload file) {
    if (_state.submitting) return;
    final newAttachments = List<PickedFilePayload>.from(_state.attachments)
      ..remove(file);
    _state = _state.copyWith(attachments: newAttachments);
    notifyListeners();
  }

  Future<bool> submit() async {
    final title = _state.titleController?.text.trim() ?? '';
    final message = _state.messageController?.text.trim() ?? '';

    final assigneeError = NewTicketValidators.validateAssignee(
      _state.selectedUser,
      _state.selectedAdmin,
      role,
      forMyTickets,
    );
    if (assigneeError != null) return false;

    final titleError = NewTicketValidators.validateTitle(title, role);
    if (titleError != null) return false;

    final messageError = NewTicketValidators.validateMessage(message, role);
    if (messageError != null) return false;

    final categoryError = NewTicketValidators.validateCategory(_state.selectedCategory);
    if (categoryError != null) return false;

    final priorityError = NewTicketValidators.validatePriority(_state.selectedPriority);
    if (priorityError != null) return false;

    final attachmentError = NewTicketValidators.validateAttachments(_state.attachments, role);
    if (attachmentError != null) return false;

    _state = _state.copyWith(submitting: true);
    notifyListeners();

    final draft = SupportCreateTicketDraft(
      title: title,
      message: message,
      category: _state.selectedCategory,
      priority: _state.selectedPriority,
      userId: role == SupportRole.admin && !forMyTickets ? _state.selectedUser?.id : null,
      adminId: role == SupportRole.superadmin ? _state.selectedAdmin?.id : null,
      attachments: showAttachmentSection ? _state.attachments : const <PickedFilePayload>[],
    );

    final result = await repository.createTicket(draft, cancelToken: _cancelToken);

    _state = _state.copyWith(submitting: false);
    notifyListeners();

    return result.isSuccess;
  }
}