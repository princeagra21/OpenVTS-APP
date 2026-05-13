import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/features/settings/domain/config/settings_role_config.dart';
import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';
import 'package:open_vts/features/settings/presentation/controllers/settings_content_state.dart';
import 'package:open_vts/features/settings/presentation/controllers/settings_profile_loader.dart';

class SettingsContentControllerParams {
  const SettingsContentControllerParams({
    required this.config,
    required this.profileLoader,
  });

  final SettingsRoleConfig config;
  final SettingsProfileDataLoader profileLoader;
}

final settingsContentControllerProvider = StateNotifierProvider.autoDispose
    .family<SettingsContentController, SettingsViewState, SettingsContentControllerParams>((ref, params) {
  return SettingsContentController(
    config: params.config,
    profileLoader: params.profileLoader,
  )..loadProfile();
});

class SettingsContentController extends StateNotifier<SettingsViewState> {
  SettingsContentController({
    required this.config,
    required SettingsProfileDataLoader profileLoader,
  }) : _profileLoader = profileLoader,
       super(const SettingsViewState());

  final SettingsRoleConfig config;
  final SettingsProfileDataLoader _profileLoader;
  int _loadVersion = 0;

  String? get errorMessage => state.errorMessage;
  SettingsSectionId get selectedSection => state.selectedSection;
  bool get loadingProfile => state.loadingProfile;
  SettingsProfileData? get profile => state.profile;

  void selectSection(SettingsSectionId section) {
    if (state.selectedSection == section) return;
    state = state.copyWith(selectedSection: section);
  }

  Future<void> loadProfile() async {
    final version = ++_loadVersion;
    state = state.copyWith(loadingProfile: true, errorMessage: null);

    try {
      final result = await _profileLoader.loadProfile(
        config.role,
        AppCancellationHandle(),
      );
      if (!mounted || version != _loadVersion) return;
      result.when(
        success: (profile) {
          state = state.copyWith(profile: profile, loadingProfile: false);
        },
        failure: (error) {
          state = state.copyWith(errorMessage: error.toString(), loadingProfile: false);
        },
      );
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(errorMessage: 'Failed to load profile', loadingProfile: false);
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}
