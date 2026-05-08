import 'package:flutter/foundation.dart';
import 'package:open_vts/core/navigation/app_routes.dart';
import 'package:open_vts/features/support/support_permissions.dart';

enum SupportRole { admin, user, superadmin }

@immutable
class SupportRoleConfig {
  const SupportRoleConfig({
    required this.role,
    required this.title,
    required this.homeRoute,
    required this.permissions,
  });

  final SupportRole role;
  final String title;
  final String homeRoute;
  final SupportPermissions permissions;
}

class SupportRoleConfigs {
  const SupportRoleConfigs._();

  static const admin = SupportRoleConfig(
    role: SupportRole.admin,
    title: 'Support Inbox',
    homeRoute: AppRoutes.adminHome,
    permissions: SupportPermissions(
      canViewMyTicketsTab: true,
      canUpdateStatus: true,
      canSendInternalNotes: true,
      canCreateTicketForOtherUsers: true,
      canOpenFullscreenChat: false,
    ),
  );

  static const user = SupportRoleConfig(
    role: SupportRole.user,
    title: 'Support Inbox',
    homeRoute: AppRoutes.userHome,
    permissions: SupportPermissions(
      canViewMyTicketsTab: false,
      canUpdateStatus: false,
      canSendInternalNotes: false,
      canCreateTicketForOtherUsers: false,
      canOpenFullscreenChat: false,
    ),
  );

  static const superadmin = SupportRoleConfig(
    role: SupportRole.superadmin,
    title: 'Support Inbox',
    homeRoute: AppRoutes.superadminHome,
    permissions: SupportPermissions(
      canViewMyTicketsTab: false,
      canUpdateStatus: true,
      canSendInternalNotes: true,
      canCreateTicketForAdmins: true,
      canOpenFullscreenChat: true,
    ),
  );
}
