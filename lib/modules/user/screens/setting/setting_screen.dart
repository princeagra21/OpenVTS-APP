import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_profile_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:fleet_stack/modules/user/screens/localization/localization.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/edit_admin_profile_screen.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/update_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String selectedTab = 'Profile';
  final List<String> tabs = [
    'Profile',
    'Localization',
  ];

  AdminProfile? _profile;
  bool _loadingProfile = false;
  bool _errorShown = false;
  CancelToken? _loadToken;
  ApiClient? _api;
  UserProfileRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _loadToken?.cancel('User settings disposed');
    super.dispose();
  }

  Future<void> _loadProfile() async {
    _loadToken?.cancel('Reload profile');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingProfile = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= UserProfileRepository(api: _api!);

      final res = await _repo!.getMyProfile(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          setState(() {
            _profile = profile;
            _loadingProfile = false;
            _errorShown = false;
          });
        },
        failure: (_) {
          if (!mounted) return;
          setState(() {
            _profile = null;
            _loadingProfile = false;
          });
          if (_errorShown) return;
          _errorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load profile.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loadingProfile = false;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load profile.")),
      );
    }
  }

  String _display(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _usernameLabel(String? value) {
    final text = _display(value);
    if (text == '-') return '-';
    return text.startsWith('@') ? text : '@$text';
  }

  String _buildAbsoluteUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }
    final baseUrl = AppConfig.fromDartDefine().baseUrl;
    if (baseUrl.isEmpty) return '';
    if (value.startsWith('/')) return '$baseUrl$value';
    return '$baseUrl/$value';
  }

  String _extractProfileImageUrl(AdminProfile? profile) {
    if (profile == null) return '';
    final raw = profile.raw;
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
    const keys = [
      'profileUrl',
      'profileurl',
      'profile_url',
      'avatarUrl',
      'avatar_url',
      'avatar',
      'photoUrl',
      'photo_url',
      'imageUrl',
      'image_url',
      'profileImage',
      'profile_image',
    ];
    for (final map in sources) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        return _buildAbsoluteUrl(text);
      }
    }
    return '';
  }

  String _extractWhatsapp(AdminProfile? profile) {
    if (profile == null) return '';
    final raw = profile.raw;
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

  List<String> _formatDateTimeParts(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return const ['—', '—'];
    final dt = DateTime.tryParse(text)?.toLocal();
    if (dt == null) return const ['—', '—'];
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${dt.month}/${dt.day}/${dt.year}';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:${two(dt.minute)} $ampm';
    return [date, time];
  }

  Map<String, dynamic> _companyMap(AdminProfile? profile) {
    if (profile == null) return const {};
    final data = profile.data;
    final companies = data['companies'];
    if (companies is List && companies.isNotEmpty) {
      final first = companies.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first.cast());
      }
    }
    return const {};
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

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width);
    final double topPadding = MediaQuery.of(context).padding.top;

    final company = _companyMap(_profile);
    final socialLinks = company['socialLinks'] is Map
        ? Map<String, dynamic>.from((company['socialLinks'] as Map).cast())
        : const <String, dynamic>{};

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
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
                    _NavigateBox(
                      selectedTab: selectedTab,
                      tabs: tabs,
                      onTabSelected: (newTab) {
                        setState(() {
                          selectedTab = newTab;
                        });
                      },
                    ),
                    if (selectedTab == 'Profile') ...[
                      const SizedBox(height: 16),
                      _ProfileOverviewHeader(
                        name: _display(_profile?.fullName),
                        username: _usernameLabel(_profile?.username),
                        verified: _profile?.isVerified ?? false,
                        imageUrl: _extractProfileImageUrl(_profile),
                        loading: _loadingProfile,
                        email: _display(_profile?.email),
                        phone: _display(_profile?.phone),
                        whatsapp: _extractWhatsapp(_profile),
                        companyName: _display(
                          company['name']?.toString() ?? _profile?.companyName,
                        ),
                        companyWebsite: _display(
                          company['websiteUrl']?.toString() ??
                              _profile?.website,
                        ),
                        companyId: _display(company['id']?.toString()),
                        primaryColor: _display(
                          company['primaryColor']?.toString(),
                        ),
                        customDomain: _display(
                          company['customDomain']?.toString(),
                        ),
                        socialLabels: _socialLabels(company),
                        socialLinks: socialLinks,
                        createdParts: _formatDateTimeParts(
                          _profile?.createdAt,
                        ),
                        updatedParts: _formatDateTimeParts(
                          _profile?.lastLoginAt.isNotEmpty == true
                              ? _profile?.lastLoginAt
                              : _profile?.lastLogin,
                        ),
                        onEdit: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditAdminProfileScreen(
                                initialProfile: _profile,
                              ),
                            ),
                          );
                          if (changed == true) {
                            await _loadProfile();
                          }
                        },
                        onPassword: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UpdatePasswordScreen(),
                            ),
                          );
                          if (changed == true) {
                            await _loadProfile();
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (selectedTab == 'Localization') ...[
                      const SizedBox(height: 16),
                      const LocalizationHeader(),
                      const SizedBox(height: 24),
                    ],
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
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFF5F5F7),
              child: UserHomeAppBar(
                title: 'Settings',
                leadingIcon: Icons.settings,
                onClose: () => context.go('/user/home'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigateBox extends StatelessWidget {
  final String selectedTab;
  final List<String> tabs;
  final ValueChanged<String> onTabSelected;

  const _NavigateBox({
    required this.selectedTab,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSubtitle = 12 * scale;
    final double fsTab = 13 * scale;
    final double fsTabIcon = 14 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
            style: GoogleFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage admin configuration',
            style: GoogleFonts.roboto(
              fontSize: fsSubtitle,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: tabs.map((tab) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _SettingsTab(
                      label: tab,
                      selected: selectedTab == tab,
                      icon: _iconFor(tab),
                      fontSize: fsTab,
                      iconSize: fsTabIcon,
                      onTap: () => onTabSelected(tab),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData? _iconFor(String tab) {
    final t = tab.toLowerCase();
    if (t == 'profile') return Icons.person_outline;
    if (t == 'localization') return Icons.language;
    if (t == 'settings') return Icons.tune;
    return null;
  }
}

class _SettingsTab extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final double fontSize;
  final double iconSize;
  final VoidCallback onTap;

  const _SettingsTab({
    required this.label,
    required this.selected,
    required this.icon,
    required this.fontSize,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : cs.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize,
                  color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: fontSize,
                  height: 18 / 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOverviewHeader extends StatelessWidget {
  final String name;
  final String username;
  final bool verified;
  final String imageUrl;
  final bool loading;
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
  final List<String> createdParts;
  final List<String> updatedParts;
  final VoidCallback onEdit;
  final VoidCallback onPassword;

  const _ProfileOverviewHeader({
    required this.name,
    required this.username,
    required this.verified,
    required this.imageUrl,
    required this.loading,
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
    required this.createdParts,
    required this.updatedParts,
    required this.onEdit,
    required this.onPassword,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(width) + 2;
    final double subtitleSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double buttonFont = 12 * scale;
    final double iconSize = subtitleSize + 6;

    Widget actionButton({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool primary = false,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primary ? cs.primary : Colors.transparent,
            border: Border.all(
              color: primary ? cs.primary : cs.onSurface.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: iconSize,
                color: primary ? cs.onPrimary : cs.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: buttonFont,
                  height: 16 / 12,
                  fontWeight: FontWeight.w600,
                  color: primary ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmer(width: 90, height: 16, radius: 6),
                      const SizedBox(height: 6),
                      AppShimmer(width: 60, height: 12, radius: 6),
                    ],
                  ),
                ),
                AppShimmer(width: 72, height: 32, radius: 10),
                const SizedBox(width: 8),
                AppShimmer(width: 88, height: 32, radius: 10),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: GoogleFonts.roboto(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profile',
                        style: GoogleFonts.roboto(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                actionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  primary: true,
                  onTap: onEdit,
                ),
                const SizedBox(width: 8),
                actionButton(
                  icon: Icons.lock_outline,
                  label: 'Password',
                  onTap: onPassword,
                ),
              ],
            ),
          const SizedBox(height: 16),
          _ProfileAccountCard(
            name: name,
            username: username,
            verified: verified,
            imageUrl: imageUrl,
            loading: loading,
          ),
          const SizedBox(height: 12),
          _ProfileDatesGrid(
            loading: loading,
            createdDate: createdParts.isNotEmpty ? createdParts[0] : '—',
            createdTime: createdParts.length > 1 ? createdParts[1] : '—',
            updatedDate: updatedParts.isNotEmpty ? updatedParts[0] : '—',
            updatedTime: updatedParts.length > 1 ? updatedParts[1] : '—',
          ),
          const SizedBox(height: 12),
          _ProfileEmailCard(
            email: email,
            verified: verified,
            loading: loading,
          ),
          const SizedBox(height: 12),
          _ProfilePhoneCard(
            phone: phone,
            verified: verified,
            loading: loading,
          ),
          if (!loading &&
              whatsapp.trim().isNotEmpty &&
              whatsapp.trim() != '-' &&
              whatsapp.trim() != phone.trim()) ...[
            const SizedBox(height: 12),
            _ProfileWhatsappCard(
              phone: whatsapp,
              loading: loading,
            ),
          ],
          const SizedBox(height: 12),
          _ProfileCompanyCard(
            companyName: companyName,
            companyWebsite: companyWebsite,
            companyId: companyId,
            primaryColor: primaryColor,
            customDomain: customDomain,
            socialLabels: socialLabels,
            socialLinks: socialLinks,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _ProfileDatesGrid extends StatelessWidget {
  final bool loading;
  final String createdDate;
  final String createdTime;
  final String updatedDate;
  final String updatedTime;

  const _ProfileDatesGrid({
    required this.loading,
    required this.createdDate,
    required this.createdTime,
    required this.updatedDate,
    required this.updatedTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    final double timeSize = AdaptiveUtils.getSubtitleFontSize(width) - 3;

    Widget cell({required String label, required String date, required String time}) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.onSurface.withOpacity(0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: labelSize,
                height: 14 / 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loading ? '—' : date,
              style: GoogleFonts.roboto(
                fontSize: valueSize,
                height: 18 / 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loading ? '—' : time,
              style: GoogleFonts.roboto(
                fontSize: timeSize,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AdaptiveUtils.getLeftSectionSpacing(width) + 6;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: cell(
                label: 'Updated',
                date: updatedDate,
                time: updatedTime,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: cell(
                label: 'Created',
                date: createdDate,
                time: createdTime,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileEmailCard extends StatelessWidget {
  final String email;
  final bool verified;
  final bool loading;

  const _ProfileEmailCard({
    required this.email,
    required this.verified,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceVariant
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.mail_outline,
              size: 18 * scale,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email',
                  style: GoogleFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(
                    verified ? Icons.verified : Icons.error_outline,
                    size: 14 * scale,
                    color: verified ? cs.primary : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verified ? 'Verified' : 'Unverified',
                    style: GoogleFonts.roboto(
                      fontSize: 12 * scale,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: verified ? cs.primary : cs.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfilePhoneCard extends StatelessWidget {
  final String phone;
  final bool verified;
  final bool loading;

  const _ProfilePhoneCard({
    required this.phone,
    required this.verified,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceVariant
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.phone_outlined,
              size: 18 * scale,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone',
                  style: GoogleFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(
                    verified ? Icons.verified : Icons.error_outline,
                    size: 14 * scale,
                    color: verified ? cs.primary : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verified ? 'Verified' : 'Unverified',
                    style: GoogleFonts.roboto(
                      fontSize: 12 * scale,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: verified ? cs.primary : cs.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileWhatsappCard extends StatelessWidget {
  final String phone;
  final bool loading;

  const _ProfileWhatsappCard({
    required this.phone,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceVariant
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.chat_bubble_outline,
              size: 18 * scale,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp',
                  style: GoogleFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCompanyCard extends StatelessWidget {
  final String companyName;
  final String companyWebsite;
  final String companyId;
  final String primaryColor;
  final String customDomain;
  final List<String> socialLabels;
  final Map<String, dynamic> socialLinks;
  final bool loading;

  const _ProfileCompanyCard({
    required this.companyName,
    required this.companyWebsite,
    required this.companyId,
    required this.primaryColor,
    required this.customDomain,
    required this.socialLabels,
    required this.socialLinks,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(width) - 1;

    Widget infoRow(String label, String value) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                loading ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      );
    }

    String? _socialUrl(String label) {
      final key = label.toLowerCase().replaceAll(' ', '');
      final byKey = socialLinks[key]?.toString();
      if (byKey != null && byKey.trim().isNotEmpty) return byKey;
      for (final entry in socialLinks.entries) {
        if (entry.key.toString().toLowerCase() == key) {
          final v = entry.value?.toString() ?? '';
          if (v.trim().isNotEmpty) return v;
        }
      }
      return null;
    }

    Future<void> _openUrl(String url) async {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.onSurface.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36 * scale,
                height: 36 * scale,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? cs.surfaceVariant
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.apartment,
                  size: 18 * scale,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company',
                      style: GoogleFonts.roboto(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading ? '—' : companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading ? '—' : companyWebsite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!loading && socialLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: socialLabels.map((label) {
                final url = _socialUrl(label);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: url == null ? null : () => _openUrl(url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontSize: 13 * scale,
                        height: 18 / 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Column(
            children: [
              infoRow('Company ID', companyId),
              const SizedBox(height: 10),
              infoRow('Primary Color', primaryColor),
              const SizedBox(height: 10),
              infoRow('Custom Domain', customDomain),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAccountCard extends StatelessWidget {
  final String name;
  final String username;
  final bool verified;
  final String imageUrl;
  final bool loading;

  const _ProfileAccountCard({
    required this.name,
    required this.username,
    required this.verified,
    required this.imageUrl,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double nameSize = AdaptiveUtils.getSubtitleFontSize(width) + 2;
    final double handleSize = AdaptiveUtils.getTitleFontSize(width) - 1;

    Widget initialsAvatar(String text) {
      final initials = text.trim().isEmpty || text.trim() == '-'
          ? '—'
          : text
              .split(RegExp(r'\s+'))
              .where((e) => e.isNotEmpty)
              .take(2)
              .map((e) => e[0])
              .join()
              .toUpperCase();
      return CircleAvatar(
        radius: 28 * scale,
        backgroundColor: cs.primary,
        child: Text(
          initials,
          style: GoogleFonts.roboto(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w700,
            color: cs.onPrimary,
          ),
        ),
      );
    }

    Widget imageAvatar(String url) {
      return CircleAvatar(
        radius: 28 * scale,
        backgroundColor: cs.surfaceVariant,
        backgroundImage: NetworkImage(url),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          if (loading)
            const AppShimmer(width: 56, height: 56, radius: 28)
          else if (imageUrl.trim().isNotEmpty)
            imageAvatar(imageUrl)
          else
            initialsAvatar(name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loading ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: nameSize,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: handleSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? cs.surfaceVariant
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(
                    verified ? Icons.verified : Icons.error_outline,
                    size: 14 * scale,
                    color: verified ? cs.primary : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verified ? 'Verified' : 'Unverified',
                    style: GoogleFonts.roboto(
                      fontSize: 12 * scale,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: verified ? cs.primary : cs.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
