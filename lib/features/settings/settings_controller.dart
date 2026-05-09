import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';

typedef SettingsProfileLoader = Future<Result<SettingsProfileData>> Function(
  CancelToken cancelToken,
);

class SettingsController extends ChangeNotifier {
  SettingsController({
    required this.config,
    required this.profileLoader,
  }) : _selectedSection = config.availableSections.first.id;

  final SettingsRoleConfig config;
  final SettingsProfileLoader profileLoader;

  SettingsSectionId _selectedSection;
  bool _loadingProfile = false;
  SettingsProfileData _profile = const SettingsProfileData.empty();
  String? _errorMessage;
  CancelToken? _profileToken;

  SettingsSectionId get selectedSection => _selectedSection;
  bool get loadingProfile => _loadingProfile;
  SettingsProfileData get profile => _profile;
  String? get errorMessage => _errorMessage;

  void selectSection(SettingsSectionId id) {
    if (_selectedSection == id) return;
    _selectedSection = id;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _profileToken?.cancel('Reload profile');
    final token = CancelToken();
    _profileToken = token;

    _loadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await profileLoader(token);
      if (token.isCancelled) return;

      result.when(
        success: (profile) {
          _profile = profile;
          _loadingProfile = false;
          _errorMessage = null;
        },
        failure: (_) {
          _profile = const SettingsProfileData.empty();
          _loadingProfile = false;
          _errorMessage = "Couldn't load profile.";
        },
      );
      notifyListeners();
    } catch (_) {
      if (token.isCancelled) return;
      _profile = const SettingsProfileData.empty();
      _loadingProfile = false;
      _errorMessage = "Couldn't load profile.";
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _profileToken?.cancel('SettingsController disposed');
    super.dispose();
  }
}
