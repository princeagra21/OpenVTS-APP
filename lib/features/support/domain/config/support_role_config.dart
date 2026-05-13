import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/features/support/domain/permissions/support_permissions.dart';

enum SupportRole { admin, user, superadmin }

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

  static SupportRoleConfig forRole(SupportRole role) {
    switch (role) {
      case SupportRole.admin:
        return admin;
      case SupportRole.user:
        return user;
      case SupportRole.superadmin:
        return superadmin;
    }
  }

  static const admin = SupportRoleConfig(
    role: SupportRole.admin,
    title: 'Support Inbox',
    homeRoute: AppRoutePaths.adminHome,
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
    homeRoute: AppRoutePaths.userHome,
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
    homeRoute: AppRoutePaths.superadminHome,
    permissions: SupportPermissions(
      canViewMyTicketsTab: false,
      canUpdateStatus: true,
      canSendInternalNotes: true,
      canCreateTicketForAdmins: true,
      canOpenFullscreenChat: true,
    ),
  );
}
