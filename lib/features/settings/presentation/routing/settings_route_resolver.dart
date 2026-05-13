import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/features/settings/domain/config/settings_role_config.dart';
import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';
import 'package:open_vts/features/admin/presentation/components/admin/application_setting/application_setting.dart';
import 'package:open_vts/features/admin/presentation/components/admin/edit_admin_profile_screen.dart'
    as admin_profile;
import 'package:open_vts/features/admin/presentation/components/admin/localization/localization.dart';
import 'package:open_vts/features/admin/presentation/components/admin/update_password_screen.dart'
    as admin_password;
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/localization/localization.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/edit_admin_profile_screen.dart'
    as superadmin_profile;
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/update_password_screen.dart'
    as superadmin_password;
import 'package:open_vts/features/superadmin/presentation/components/admin/setting_tab/superadmin_settings_tab.dart';
import 'package:open_vts/features/superadmin/presentation/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/features/user/presentation/components/appbars/user_home_appbar.dart';
import 'package:open_vts/features/user/presentation/screens/localization/localization.dart';
import 'package:open_vts/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart'
    as user_profile;
import 'package:open_vts/features/user/presentation/screens/profile/widget/update_password_screen.dart'
    as user_password;

class SettingsRouteResolver {
  const SettingsRouteResolver._();

  static SettingsRoleConfig configForRole(SettingsRole role) {
    switch (role) {
      case SettingsRole.admin:
        return SettingsRoleConfigs.admin;
      case SettingsRole.user:
        return SettingsRoleConfigs.user;
      case SettingsRole.superadmin:
        return SettingsRoleConfigs.superadmin;
    }
  }

  static Widget buildRoleAppBar({
    required BuildContext context,
    required SettingsRole role,
  }) {
    switch (role) {
      case SettingsRole.admin:
        return AdminHomeAppBar(
          title: 'Settings',
          leadingIcon: Icons.settings,
          onClose: () => context.go(AppRoutePaths.adminHome),
        );
      case SettingsRole.user:
        return UserHomeAppBar(
          title: 'Settings',
          leadingIcon: Icons.settings,
          onClose: () => context.go(AppRoutePaths.userHome),
        );
      case SettingsRole.superadmin:
        return const SuperAdminHomeAppBar(
          title: 'Settings',
          leadingIcon: Icons.settings,
        );
    }
  }

  static Widget buildLocalizationSection(SettingsRole role) {
    switch (role) {
      case SettingsRole.admin:
        return const AdminLocalizationScreen();
      case SettingsRole.user:
        return const UserLocalizationScreen();
      case SettingsRole.superadmin:
        return const SuperadminLocalizationScreen();
    }
  }

  static Widget buildSettingsSection(SettingsRole role) {
    switch (role) {
      case SettingsRole.admin:
        return const ApplicationHeader();
      case SettingsRole.user:
        return const SizedBox.shrink();
      case SettingsRole.superadmin:
        return const SuperadminSettingsTab();
    }
  }

  static Future<bool> openEditProfile({
    required BuildContext context,
    required SettingsRole role,
    required SettingsProfileData profile,
    required AdminProfile? adminOrUserProfile,
  }) async {
    switch (role) {
      case SettingsRole.admin:
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => admin_profile.EditAdminProfileScreen(
              initialProfile: adminOrUserProfile,
            ),
          ),
        );
        return changed == true;
      case SettingsRole.user:
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => user_profile.EditAdminProfileScreen(
              initialProfile: adminOrUserProfile,
            ),
          ),
        );
        return changed == true;
      case SettingsRole.superadmin:
        if (profile.profileId.isEmpty) return false;
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => superadmin_profile.EditAdminProfileScreen(
              adminId: profile.profileId,
            ),
          ),
        );
        return false;
    }
  }

  static Future<bool> openUpdatePassword({
    required BuildContext context,
    required SettingsRole role,
    required SettingsProfileData profile,
  }) async {
    switch (role) {
      case SettingsRole.admin:
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const admin_password.UpdatePasswordScreen(),
          ),
        );
        return changed == true;
      case SettingsRole.user:
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const user_password.UpdatePasswordScreen(),
          ),
        );
        return changed == true;
      case SettingsRole.superadmin:
        if (profile.profileId.isEmpty) return false;
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => superadmin_password.UpdatePasswordScreen(
              adminId: profile.profileId,
            ),
          ),
        );
        return false;
    }
  }
}
