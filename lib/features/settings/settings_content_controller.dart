import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/repositories/admin_profile_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_profile_repository.dart';
import 'package:open_vts/features/settings/settings_content_state.dart';
import 'package:open_vts/features/settings/settings_profile_loader.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';

class SettingsContentController extends ChangeNotifier {
  SettingsContentController({
    required this.config,
    required this.profileLoader,
    required this.adminRepo,
    required this.userRepo,
    required this.superadminRepo,
  });

  final SettingsRoleConfig config;
  final SettingsProfileDataLoader profileLoader;
  final AdminProfileRepository? adminRepo;
  final UserProfileRepository? userRepo;
  final SuperadminRepository? superadminRepo;

  SettingsViewState _state = const SettingsViewState();
  SettingsViewState get state => _state;

  String? get errorMessage => _state.errorMessage;

  SettingsSectionId get selectedSection => _state.selectedSection;
  bool get loadingProfile => _state.loadingProfile;
  SettingsProfileData? get profile => _state.profile;

  void selectSection(SettingsSectionId section) {
    _state = _state.copyWith(selectedSection: section);
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _state = _state.copyWith(loadingProfile: true, errorMessage: null);
    notifyListeners();

    final cancelToken = CancelToken();
    try {
      final result = await profileLoader.loadProfile(config.role, cancelToken);
      result.when(
        success: (profile) {
          _state = _state.copyWith(
            profile: profile,
            loadingProfile: false,
          );
        },
        failure: (error) {
          _state = _state.copyWith(
            errorMessage: error.toString(),
            loadingProfile: false,
          );
        },
      );
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to load profile',
        loadingProfile: false,
      );
    }
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }
}