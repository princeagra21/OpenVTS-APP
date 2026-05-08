import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';

@immutable
class SettingsProfileData {
  const SettingsProfileData({
    required this.profileId,
    required this.name,
    required this.username,
    required this.verified,
    required this.emailVerified,
    required this.phoneVerified,
    required this.imageUrl,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.companyName,
    required this.companyWebsite,
    required this.companyId,
    required this.primaryColor,
    required this.customDomain,
    required this.socialLabels,
    required this.socialLinks,
    required this.address,
    required this.createdParts,
    required this.updatedParts,
  });

  const SettingsProfileData.empty()
    : profileId = '',
      name = '-',
      username = '-',
      verified = false,
      emailVerified = false,
      phoneVerified = false,
      imageUrl = '',
      email = '-',
      phone = '-',
      whatsapp = '',
      companyName = '-',
      companyWebsite = '-',
      companyId = '-',
      primaryColor = '-',
      customDomain = '-',
      socialLabels = const [],
      socialLinks = const {},
      address = '-',
      createdParts = const ['—', '—'],
      updatedParts = const ['—', '—'];

  final String profileId;
  final String name;
  final String username;
  final bool verified;
  final bool emailVerified;
  final bool phoneVerified;
  final String imageUrl;
  final String email;
  final String phone;
  final String whatsapp;
  final String companyName;
  final String companyWebsite;
  final String companyId;
  final String primaryColor;
  final String customDomain;
  final List<String> socialLabels;
  final Map<String, dynamic> socialLinks;
  final String address;
  final List<String> createdParts;
  final List<String> updatedParts;
}

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
