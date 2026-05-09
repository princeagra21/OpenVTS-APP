import 'package:flutter/material.dart';

enum SettingsSectionId { profile, localization, settings }

class SettingsSectionModel {
  const SettingsSectionModel({
    required this.id,
    required this.label,
    required this.icon,
  });

  final SettingsSectionId id;
  final String label;
  final IconData icon;
}

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
