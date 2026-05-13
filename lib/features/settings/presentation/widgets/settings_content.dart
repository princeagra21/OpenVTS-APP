import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/top_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/features/settings/di/settings_access_providers.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_components.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/features/settings/presentation/controllers/settings_action_handler.dart';
import 'package:open_vts/features/settings/presentation/controllers/settings_content_controller.dart';
import 'package:open_vts/features/settings/presentation/controllers/settings_content_state.dart';
import 'package:open_vts/features/settings/presentation/widgets/settings_navigation_grid.dart';
import 'package:open_vts/features/settings/domain/config/settings_role_config.dart';
import 'package:open_vts/features/settings/presentation/routing/settings_route_resolver.dart';
import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';
import 'package:open_vts/features/settings/presentation/controllers/settings_profile_loader.dart';
import 'package:open_vts/features/settings/presentation/routing/settings_section_router.dart';
import 'package:open_vts/features/settings/presentation/sections/settings_application_section.dart';
import 'package:open_vts/features/settings/presentation/sections/settings_localization_section.dart';
import 'package:open_vts/features/settings/presentation/sections/settings_profile_section.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class RoleAwareSettingsContent extends ConsumerStatefulWidget {
  const RoleAwareSettingsContent({super.key, required this.role});

  final SettingsRole role;

  @override
  ConsumerState<RoleAwareSettingsContent> createState() =>
      _RoleAwareSettingsContentState();
}

class _RoleAwareSettingsContentState extends ConsumerState<RoleAwareSettingsContent> {
  late final SettingsRoleConfig _config;
  late final SettingsSectionRouter _sectionRouter;
  late final SettingsProfileDataLoader _profileLoader;
  late final SettingsContentControllerParams _controllerParams;

  dynamic _adminOrUserProfile;
  SettingsViewState _viewState = const SettingsViewState();

  @override
  void initState() {
    super.initState();
    _config = SettingsRouteResolver.configForRole(widget.role);
    final loader = ref.read(settingsProfileLoaderProvider(widget.role));
    _profileLoader = loader.copyWith(
      onProfileLoaded: (profile) => _adminOrUserProfile = profile,
    );
    _controllerParams = SettingsContentControllerParams(
      config: _config,
      profileLoader: _profileLoader,
    );

    _sectionRouter = const SettingsSectionRouter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(settingsContentControllerProvider(_controllerParams).notifier)
          .loadProfile();
      if (widget.role == SettingsRole.superadmin) {
        _loadPushState();
      }
    });
  }


  void _showError(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
  }

  Future<void> _loadPushState() async {
    final state = await ref.read(settingsPushServiceProvider).getStatus();
    if (!mounted) return;
    updateLocalUiState(this, 
      () => _viewState = _viewState.copyWith(pushState: state.enabledByUser),
    );
  }

  SettingsActionHandler _buildActionHandler() {
    final deps = ref.read(settingsActionDepsProvider);
    return SettingsActionHandler(
      role: widget.role,
      controller: ref.read(settingsContentControllerProvider(_controllerParams).notifier),
      adminRepo: deps.admin,
      userRepo: deps.user,
      superadminRepo: deps.superadmin,
      adminOrUserProfile: _adminOrUserProfile is AdminProfile
          ? _adminOrUserProfile as AdminProfile
          : null,
    );
  }

  void _updateViewState(SettingsViewState state) {
    if (!mounted) return;
    updateLocalUiState(this, () => _viewState = state);
  }

  Future<void> _onEditProfile() async {
    final profile = ref.read(settingsContentControllerProvider(_controllerParams)).profile;
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
    if (changed) await ref.read(settingsContentControllerProvider(_controllerParams).notifier).loadProfile();
  }

  Future<void> _onUpdatePassword() async {
    final profile = ref.read(settingsContentControllerProvider(_controllerParams)).profile;
    if (profile == null) {
      OpenVtsFeedback.warning(context, 'Profile is still loading.');
      return;
    }

    final changed = await SettingsRouteResolver.openUpdatePassword(
      context: context,
      role: widget.role,
      profile: profile,
    );
    if (changed) await ref.read(settingsContentControllerProvider(_controllerParams).notifier).loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;

    final provider = settingsContentControllerProvider(_controllerParams);
    final settingsState = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen(provider.select((value) => value.errorMessage), (previous, next) {
      if (next == null) {
        _viewState = _viewState.copyWith(errorShown: false);
        return;
      }
      if (_viewState.errorShown) return;
      _viewState = _viewState.copyWith(errorShown: true);
      _showError(next);
    });

    final selectedSection = settingsState.selectedSection;
    final profile = settingsState.profile;
    final loading = settingsState.loadingProfile;

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
                          onSectionSelected: controller.selectSection,
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
                top: 0,
                left: 0,
                right: 0,
                child: TopBar(
                  title: 'Settings',
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
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
          onRetryProfile: ref.read(settingsContentControllerProvider(_controllerParams).notifier).loadProfile,
        );
      case SettingsSectionId.localization:
        return SettingsLocalizationSection(role: widget.role);
      case SettingsSectionId.settings:
        return SettingsApplicationSection(role: widget.role);
    }
  }
}
