import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_list_item.dart';
import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/support_role_config.dart';

class NewTicketState {
  const NewTicketState({
    required this.role,
    this.submitting = false,
    this.loadingAssignees = false,
    this.assigneeErrorShown = false,
    this.attachments = const [],
    this.users = const [],
    this.admins = const [],
    this.selectedUser,
    this.selectedAdmin,
    this.selectedCategory,
    this.selectedPriority,
    this.titleController,
    this.messageController,
  });

  final SupportRole role;
  final bool submitting;
  final bool loadingAssignees;
  final bool assigneeErrorShown;
  final List<PickedFilePayload> attachments;
  final List<AdminUserListItem> users;
  final List<AdminListItem> admins;
  final AdminUserListItem? selectedUser;
  final AdminListItem? selectedAdmin;
  final String? selectedCategory;
  final String? selectedPriority;
  final TextEditingController? titleController;
  final TextEditingController? messageController;

  NewTicketState copyWith({
    bool? submitting,
    bool? loadingAssignees,
    bool? assigneeErrorShown,
    List<PickedFilePayload>? attachments,
    List<AdminUserListItem>? users,
    List<AdminListItem>? admins,
    AdminUserListItem? selectedUser,
    AdminListItem? selectedAdmin,
    String? selectedCategory,
    String? selectedPriority,
    TextEditingController? titleController,
    TextEditingController? messageController,
  }) {
    return NewTicketState(
      role: role,
      submitting: submitting ?? this.submitting,
      loadingAssignees: loadingAssignees ?? this.loadingAssignees,
      assigneeErrorShown: assigneeErrorShown ?? this.assigneeErrorShown,
      attachments: attachments ?? this.attachments,
      users: users ?? this.users,
      admins: admins ?? this.admins,
      selectedUser: selectedUser ?? this.selectedUser,
      selectedAdmin: selectedAdmin ?? this.selectedAdmin,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      titleController: titleController ?? this.titleController,
      messageController: messageController ?? this.messageController,
    );
  }
}
