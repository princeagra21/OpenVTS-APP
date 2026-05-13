import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';

class NewTicketState {
  const NewTicketState({
    required this.role,
    this.submitting = false,
    this.loadingAssignees = false,
    this.submitSucceeded = false,
    this.attachments = const [],
    this.users = const [],
    this.admins = const [],
    this.selectedUser,
    this.selectedAdmin,
    this.selectedCategory,
    this.selectedPriority,
    this.errorMessage,
  });

  final SupportRole role;
  final bool submitting;
  final bool loadingAssignees;
  final bool submitSucceeded;
  final List<PickedFilePayload> attachments;
  final List<SupportAssigneeOption> users;
  final List<SupportAssigneeOption> admins;
  final SupportAssigneeOption? selectedUser;
  final SupportAssigneeOption? selectedAdmin;
  final String? selectedCategory;
  final String? selectedPriority;
  final String? errorMessage;

  NewTicketState copyWith({
    bool? submitting,
    bool? loadingAssignees,
    bool? submitSucceeded,
    List<PickedFilePayload>? attachments,
    List<SupportAssigneeOption>? users,
    List<SupportAssigneeOption>? admins,
    SupportAssigneeOption? selectedUser,
    bool clearSelectedUser = false,
    SupportAssigneeOption? selectedAdmin,
    bool clearSelectedAdmin = false,
    String? selectedCategory,
    String? selectedPriority,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NewTicketState(
      role: role,
      submitting: submitting ?? this.submitting,
      loadingAssignees: loadingAssignees ?? this.loadingAssignees,
      submitSucceeded: submitSucceeded ?? this.submitSucceeded,
      attachments: attachments ?? this.attachments,
      users: users ?? this.users,
      admins: admins ?? this.admins,
      selectedUser: clearSelectedUser ? null : selectedUser ?? this.selectedUser,
      selectedAdmin: clearSelectedAdmin ? null : selectedAdmin ?? this.selectedAdmin,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
