import 'package:flutter/material.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/models/admin_profile.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/settings/settings_action_handler.dart';
import 'package:open_vts/features/settings/settings_content_controller.dart';
import 'package:open_vts/features/settings/settings_content_state.dart';
import 'package:open_vts/features/settings/settings_navigation_grid.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_route_resolver.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';
import 'package:open_vts/features/settings/settings_profile_loader.dart';
import 'package:open_vts/features/settings/settings_section_router.dart';
import 'package:open_vts/features/settings/sections/settings_application_section.dart';
import 'package:open_vts/features/settings/sections/settings_localization_section.dart';
import 'package:open_vts/features/settings/sections/settings_profile_section.dart';

class RoleAwareSettingsContent extends StatefulWidget {
  const RoleAwareSettingsContent({super.key, required this.role});

  final SettingsRole role;

  @override
  State<RoleAwareSettingsContent> createState() =>
      _RoleAwareSettingsContentState();
}

class _RoleAwareSettingsContentState extends State<RoleAwareSettingsContent> {
  late final SettingsRoleConfig _config;
  late final SettingsContentController _controller;
  late final SettingsSectionRouter _sectionRouter;
  late final SettingsProfileDataLoader _profileLoader;

  dynamic _adminOrUserProfile;
  SettingsViewState _viewState = const SettingsViewState();

  @override
  void initState() {
    super.initState();
    _config = SettingsRouteResolver.configForRole(widget.role);
    final adminRepo = AppContainer.instance.adminProfileRepository;
    final userRepo = AppContainer.instance.userProfileRepository;
    final superadminRepo = AppContainer.instance.superadminRepository;
    _profileLoader = SettingsProfileDataLoader(
      adminRepo: adminRepo,
      userRepo: userRepo,
      superadminRepo: superadminRepo,
      onProfileLoaded: (profile) => _adminOrUserProfile = profile,
    );
    _controller = SettingsContentController(
      config: _config,
      profileLoader: _profileLoader,
      adminRepo: adminRepo,
      userRepo: userRepo,
      superadminRepo: superadminRepo,
    )..addListener(_handleControllerChange);

    _sectionRouter = const SettingsSectionRouter();

    _controller.loadProfile();
    if (widget.role == SettingsRole.superadmin) {
      _loadPushState();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    final message = _controller.errorMessage;
    if (message == null) {
      _viewState = _viewState.copyWith(errorShown: false);
      return;
    }
    if (_viewState.errorShown || !mounted) return;

    _viewState = _viewState.copyWith(errorShown: true);
    _showError(message);
  }

  void _showError(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
  }

  Future<void> _loadPushState() async {
    final state = await PushNotificationsService.instance.getStatus();
    if (!mounted) return;
    setState(
      () => _viewState = _viewState.copyWith(pushState: state.enabledByUser),
    );
  }

  SettingsActionHandler _buildActionHandler() {
    return SettingsActionHandler(
      role: widget.role,
      controller: _controller,
      adminRepo: AppContainer.instance.adminProfileRepository,
      userRepo: AppContainer.instance.userProfileRepository,
      superadminRepo: AppContainer.instance.superadminRepository,
      adminOrUserProfile: _adminOrUserProfile is AdminProfile
          ? _adminOrUserProfile as AdminProfile
          : null,
    );
  }

  void _updateViewState(SettingsViewState state) {
    if (!mounted) return;
    setState(() => _viewState = state);
  }

  Future<void> _onEditProfile() async {
    final profile = _controller.profile;
    if (profile == null) {
      OpenVtsFeedback.warning(context, 'Profile is still loading.');
      return;
    }

    final changed = await SettingsRouteResolver.openEditProfile(
      context: context,
      role: widget.role,
      profile: profile,
      adminOrUserProfile: _adminOrUserProfile is AdminProfile
          ? _adminOrUserProfile as AdminProfile
          : null,
    );
    if (changed) await _controller.loadProfile();
  }

  Future<void> _onUpdatePassword() async {
    final profile = _controller.profile;
    if (profile == null) {
      OpenVtsFeedback.warning(context, 'Profile is still loading.');
      return;
    }

    final changed = await SettingsRouteResolver.openUpdatePassword(
      context: context,
      role: widget.role,
      profile: profile,
    );
    if (changed) await _controller.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final selectedSection = _controller.selectedSection;
        final profile = _controller.profile;
        final loading = _controller.loadingProfile;

        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? OpenVtsColors.panelDark
              : OpenVtsColors.panelLight,
          body: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    topPadding + AppUtils.appBarHeightCustom + 10,
                    padding,
                    padding,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsNavigationGrid(
                          config: _config,
                          selectedSection: selectedSection,
                          onSectionSelected: _controller.selectSection,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(selectedSection, loading, profile),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: padding,
                right: padding,
                top: 0,
                child: Container(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? OpenVtsColors.panelDark
                      : OpenVtsColors.panelLight,
                  child: _sectionRouter.buildRoleAppBar(
                    context: context,
                    role: widget.role,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    SettingsSectionId section,
    bool loading,
    SettingsProfileData? profile,
  ) {
    if (profile == null && section == SettingsSectionId.profile) {
      return const SizedBox.shrink();
    }

    switch (section) {
      case SettingsSectionId.profile:
        return SettingsProfileSection(
          role: widget.role,
          profile: profile!,
          loading: loading,
          viewState: _viewState,
          actionHandler: _buildActionHandler(),
          onEditProfile: _onEditProfile,
          onUpdatePassword: _onUpdatePassword,
          onViewStateChanged: _updateViewState,
          onRetryProfile: _controller.loadProfile,
        );
      case SettingsSectionId.localization:
        return SettingsLocalizationSection(role: widget.role);
      case SettingsSectionId.settings:
        return SettingsApplicationSection(role: widget.role);
    }
  }
}
