import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';

class NewTicketValidators {
  static String? validateTitle(String? value, SupportRole role) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    final trimmed = value.trim();
    if (role == SupportRole.superadmin && trimmed.length > 30) {
      return 'Title must be 30 characters or less';
    }
    if (role != SupportRole.superadmin && trimmed.length > 60) {
      return 'Title must be 60 characters or less';
    }
    return null;
  }

  static String? validateMessage(String? value, SupportRole role) {
    if (value == null || value.trim().isEmpty) {
      return 'Message is required';
    }
    final trimmed = value.trim();
    if (role == SupportRole.superadmin) {
      if (trimmed.length < 10) {
        return 'Message must be at least 10 characters';
      }
      if (trimmed.length > 1000) {
        return 'Message must be 1000 characters or less';
      }
    }
    return null;
  }

  static String? validateAssignee(
    SupportAssigneeOption? selectedUser,
    SupportAssigneeOption? selectedAdmin,
    SupportRole role,
    bool forMyTickets,
  ) {
    if (role == SupportRole.admin && !forMyTickets && selectedUser == null) {
      return 'Select a user first';
    }
    if (role == SupportRole.superadmin && selectedAdmin == null) {
      return 'Select an admin';
    }
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Select a category';
    }
    return null;
  }

  static String? validatePriority(String? value) {
    if (value == null || value.isEmpty) {
      return 'Select a priority';
    }
    return null;
  }

  static String? validateAttachments(
    List<PickedFilePayload> attachments,
    SupportRole role,
  ) {
    if (role == SupportRole.superadmin) {
      if (attachments.length > 5) {
        return 'Max 5 files allowed';
      }
      for (final file in attachments) {
        if (file.bytes.length > 5 * 1024 * 1024) {
          return 'Max file size is 5MB';
        }
      }
    }
    return null;
  }
}
