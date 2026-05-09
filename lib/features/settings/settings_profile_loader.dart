import 'package:dio/dio.dart';
import 'package:open_vts/core/models/admin_profile.dart';
import 'package:open_vts/core/models/superadmin_profile.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/admin_profile_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_profile_repository.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';

class SettingsProfileDataLoader {
  const SettingsProfileDataLoader({
    required this.adminRepo,
    required this.userRepo,
    required this.superadminRepo,
    this.onProfileLoaded,
  });

  final AdminProfileRepository? adminRepo;
  final UserProfileRepository? userRepo;
  final SuperadminRepository? superadminRepo;
  final void Function(dynamic profile)? onProfileLoaded;

  Future<Result<SettingsProfileData>> loadProfile(
    SettingsRole role,
    CancelToken cancelToken,
  ) async {
    switch (role) {
      case SettingsRole.admin:
        final result = await adminRepo!.getMyProfile(cancelToken: cancelToken);
        return result.when(
          success: (profile) {
            onProfileLoaded?.call(profile);
            return Result.ok(
              _mapAdminLikeProfile(profile, useGranularVerification: true),
            );
          },
          failure: (error) => Result.fail(error),
        );

      case SettingsRole.user:
        final result = await userRepo!.getMyProfile(cancelToken: cancelToken);
        return result.when(
          success: (profile) {
            onProfileLoaded?.call(profile);
            return Result.ok(
              _mapAdminLikeProfile(profile, useGranularVerification: false),
            );
          },
          failure: (error) => Result.fail(error),
        );

      case SettingsRole.superadmin:
        final result = await superadminRepo!.getSuperadminProfile(
          cancelToken: cancelToken,
        );
        return result.when(
          success: (profile) {
            onProfileLoaded?.call(null); // No admin profile for superadmin
            return Result.ok(_mapSuperadminProfile(profile));
          },
          failure: (error) => Result.fail(error),
        );
    }
  }

  SettingsProfileData _mapAdminLikeProfile(
    AdminProfile profile, {
    required bool useGranularVerification,
  }) {
    final company = _companyMap(profile);
    final socialLinks = company['socialLinks'] is Map
        ? Map<String, dynamic>.from((company['socialLinks'] as Map).cast())
        : const <String, dynamic>{};

    final emailVerified = useGranularVerification
        ? profile.emailVerified
        : profile.isVerified;
    final phoneVerified = useGranularVerification
        ? profile.phoneVerified
        : profile.isVerified;

    return SettingsProfileData(
      profileId: profile.id,
      name: _display(profile.fullName),
      username: _usernameLabel(profile.username),
      verified: profile.isVerified,
      emailVerified: emailVerified,
      phoneVerified: phoneVerified,
      imageUrl: _extractProfileImageUrl(profile.raw),
      email: _display(profile.email),
      phone: _display(profile.phone),
      whatsapp: _extractWhatsapp(profile.raw),
      companyName: _display(company['name']?.toString() ?? profile.companyName),
      companyWebsite: _display(
        company['websiteUrl']?.toString() ?? profile.website,
      ),
      companyId: _display(company['id']?.toString()),
      primaryColor: _display(company['primaryColor']?.toString()),
      customDomain: _display(company['customDomain']?.toString()),
      socialLabels: _socialLabels(company),
      socialLinks: socialLinks,
      address: _display(_fullAddress(profile)),
      createdParts: _formatDateTimeParts(profile.createdAt),
      updatedParts: _formatDateTimeParts(
        profile.lastLoginAt.isNotEmpty
            ? profile.lastLoginAt
            : profile.lastLogin,
      ),
    );
  }

  SettingsProfileData _mapSuperadminProfile(SuperadminProfile profile) {
    return SettingsProfileData(
      profileId: profile.id,
      name: _display(profile.fullName),
      username: _usernameLabel(profile.username),
      verified: profile.isVerified ?? false,
      emailVerified: profile.isVerified ?? false,
      phoneVerified: profile.isVerified ?? false,
      imageUrl: _extractProfileImageUrl(profile.raw),
      email: _display(profile.email),
      phone: _display(profile.phone),
      whatsapp: _extractWhatsapp(profile.raw),
      companyName: '',
      companyWebsite: '',
      companyId: '',
      primaryColor: '',
      customDomain: '',
      socialLabels: const [],
      socialLinks: const {},
      address: _display(_superadminAddress(profile)),
      createdParts: _formatDateTimeParts(profile.createdAt),
      updatedParts: _formatDateTimeParts(_superadminUpdatedAt(profile)),
    );
  }

  String _display(String? value) => value?.trim() ?? '';

  String _usernameLabel(String username) => '@$username';

  String _extractProfileImageUrl(Map<String, dynamic> raw) {
    final sources = <Map<String, dynamic>>[raw];
    final level1 = raw['data'];
    if (level1 is Map) {
      final level1Map = Map<String, dynamic>.from(level1.cast());
      sources.add(level1Map);
      final level2 = level1Map['data'];
      if (level2 is Map) {
        sources.add(Map<String, dynamic>.from(level2.cast()));
      }
    }

    const keys = ['profileImage', 'profile_image', 'image', 'avatar'];
    for (final map in sources) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        return text;
      }
    }
    return '';
  }

  String _extractWhatsapp(Map<String, dynamic> raw) {
    final sources = <Map<String, dynamic>>[raw];
    final level1 = raw['data'];
    if (level1 is Map) {
      final level1Map = Map<String, dynamic>.from(level1.cast());
      sources.add(level1Map);
      final level2 = level1Map['data'];
      if (level2 is Map) {
        sources.add(Map<String, dynamic>.from(level2.cast()));
      }
    }

    const keys = ['whatsapp', 'whatsappNumber', 'whatsapp_number'];
    for (final map in sources) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        return text;
      }
    }

    return '';
  }

  Map<String, dynamic> _companyMap(AdminProfile profile) {
    final companies = profile.data['companies'];
    if (companies is List && companies.isNotEmpty) {
      final first = companies.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first.cast());
      }
    }
    return const {};
  }

  String _fullAddress(AdminProfile profile) {
    final data = profile.data;
    final address = data['address'];
    if (address is Map) {
      final map = Map<String, dynamic>.from(address.cast());
      final full = (map['fullAddress'] ?? map['fulladdress'] ?? '')
          .toString()
          .trim();
      if (full.isNotEmpty) return full;
      final line = (map['addressLine'] ?? '').toString().trim();
      if (line.isNotEmpty) return line;
    }

    final parts = <String>[
      profile.addressLine.trim(),
      profile.city.trim(),
      profile.state.trim(),
      profile.country.trim(),
      profile.pincode.trim(),
    ].where((e) => e.isNotEmpty && e != '-').toList();

    return parts.join(', ');
  }

  String _superadminAddress(SuperadminProfile profile) {
    final address = profile.address;
    final full = (address['fullAddress'] ?? address['fulladdress'] ?? '')
        .toString()
        .trim();
    if (full.isNotEmpty) return full;
    final line = (address['addressLine'] ?? profile.addressLine)
        .toString()
        .trim();
    if (line.isNotEmpty) return line;
    return '';
  }

  String _superadminUpdatedAt(SuperadminProfile profile) {
    if (profile.lastLogin.isNotEmpty) return profile.lastLogin;
    final level1 = profile.raw['data'];
    if (level1 is Map) {
      final level2 = level1['data'];
      if (level2 is Map) {
        final updated = level2['updatedAt']?.toString().trim() ?? '';
        if (updated.isNotEmpty) return updated;
      }
    }
    return '';
  }

  List<String> _socialLabels(Map<String, dynamic> company) {
    final links = company['socialLinks'];
    if (links is Map) {
      return links.keys
          .map((k) => k.toString())
          .where((k) => k.trim().isNotEmpty)
          .map((k) {
            final lower = k.trim();
            if (lower.isEmpty) return '';
            return lower[0].toUpperCase() + lower.substring(1);
          })
          .where((k) => k.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<String> _formatDateTimeParts(String dateTime) {
    if (dateTime.isEmpty) return const [];
    try {
      final dt = DateTime.parse(dateTime);
      return [
        dt.day.toString().padLeft(2, '0'),
        dt.month.toString().padLeft(2, '0'),
        dt.year.toString(),
      ];
    } catch (_) {
      return const [];
    }
  }
}