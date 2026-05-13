import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/utils/presentation_result.dart';
import 'package:open_vts/features/settings/domain/config/settings_role_config.dart';
import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';

typedef SettingsProfileLoader = Future<Result<SettingsProfileData>> Function();

class SettingsControllerState {
  const SettingsControllerState({
    required this.selectedSection,
    this.loadingProfile = false,
    this.profile = const SettingsProfileData.empty(),
    this.errorMessage,
  });

  final SettingsSectionId selectedSection;
  final bool loadingProfile;
  final SettingsProfileData profile;
  final String? errorMessage;

  SettingsControllerState copyWith({
    SettingsSectionId? selectedSection,
    bool? loadingProfile,
    SettingsProfileData? profile,
    Object? errorMessage = _unchanged,
  }) {
    return SettingsControllerState(
      selectedSection: selectedSection ?? this.selectedSection,
      loadingProfile: loadingProfile ?? this.loadingProfile,
      profile: profile ?? this.profile,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
    );
  }
}

class SettingsControllerParams {
  const SettingsControllerParams({required this.config, required this.profileLoader});

  final SettingsRoleConfig config;
  final SettingsProfileLoader profileLoader;
}

final settingsControllerProvider = StateNotifierProvider.autoDispose
    .family<SettingsController, SettingsControllerState, SettingsControllerParams>((ref, params) {
  return SettingsController(config: params.config, profileLoader: params.profileLoader)..loadProfile();
});

class SettingsController extends StateNotifier<SettingsControllerState> {
  SettingsController({required this.config, required SettingsProfileLoader profileLoader})
      : _profileLoader = profileLoader,
        super(SettingsControllerState(selectedSection: config.availableSections.first.id));

  final SettingsRoleConfig config;
  final SettingsProfileLoader _profileLoader;
  int _loadVersion = 0;

  void selectSection(SettingsSectionId id) {
    if (state.selectedSection == id) return;
    state = state.copyWith(selectedSection: id);
  }

  Future<void> loadProfile() async {
    final version = ++_loadVersion;
    state = state.copyWith(loadingProfile: true, errorMessage: null);
    try {
      final result = await _profileLoader();
      if (!mounted || version != _loadVersion) return;
      result.when(
        success: (profile) => state = state.copyWith(profile: profile, loadingProfile: false, errorMessage: null),
        failure: (_) => state = state.copyWith(
          profile: const SettingsProfileData.empty(),
          loadingProfile: false,
          errorMessage: "Couldn't load profile.",
        ),
      );
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(
        profile: const SettingsProfileData.empty(),
        loadingProfile: false,
        errorMessage: "Couldn't load profile.",
      );
    }
  }
}

const Object _unchanged = Object();
