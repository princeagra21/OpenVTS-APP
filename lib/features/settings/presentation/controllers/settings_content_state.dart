import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';

class SettingsViewState {
  const SettingsViewState({
    this.pushState,
    this.pushActionLoading = false,
    this.emailOtpLoading = false,
    this.whatsappOtpLoading = false,
    this.errorShown = false,
    this.loadingProfile = false,
    this.profile,
    this.errorMessage,
    this.selectedSection = SettingsSectionId.profile,
  });

  final bool? pushState;
  final bool pushActionLoading;
  final bool emailOtpLoading;
  final bool whatsappOtpLoading;
  final bool errorShown;
  final bool loadingProfile;
  final SettingsProfileData? profile;
  final String? errorMessage;
  final SettingsSectionId selectedSection;

  SettingsViewState copyWith({
    bool? pushState,
    bool? pushActionLoading,
    bool? emailOtpLoading,
    bool? whatsappOtpLoading,
    bool? errorShown,
    bool? loadingProfile,
    SettingsProfileData? profile,
    String? errorMessage,
    SettingsSectionId? selectedSection,
  }) {
    return SettingsViewState(
      pushState: pushState ?? this.pushState,
      pushActionLoading: pushActionLoading ?? this.pushActionLoading,
      emailOtpLoading: emailOtpLoading ?? this.emailOtpLoading,
      whatsappOtpLoading: whatsappOtpLoading ?? this.whatsappOtpLoading,
      errorShown: errorShown ?? this.errorShown,
      loadingProfile: loadingProfile ?? this.loadingProfile,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedSection: selectedSection ?? this.selectedSection,
    );
  }
}
