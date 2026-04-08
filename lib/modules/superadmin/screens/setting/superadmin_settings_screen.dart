import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/localization/localization.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/setting_tab/superadmin_settings_tab.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/services/push_notifications_service.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SuperAdminSettingsScreen extends StatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  State<SuperAdminSettingsScreen> createState() =>
      _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState extends State<SuperAdminSettingsScreen> {
  String selectedTab = "Profile";
  final List<String> tabs = [
    "Profile",
    "Localization",
    "Settings",
  ];

  SuperadminProfile? _profile;
  bool _loadingProfile = false;
  bool _errorShown = false;
  CancelToken? _profileToken;
  bool _pushActionLoading = false;
  PushDeviceState? _pushState;
  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPushState();
  }

  @override
  void dispose() {
    _profileToken?.cancel('SuperAdminSettingsScreen disposed');
    super.dispose();
  }

  void _ensureRepo() {
    if (_api != null) return;
    _api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo = SuperadminRepository(api: _api!);
  }

  Future<void> _loadPushState() async {
    final state = await PushNotificationsService.instance.getStatus();
    if (!mounted) return;
    setState(() {
      _pushState = state;
    });
  }

  Future<void> _openNotificationSettings() async {
    final uri = Uri.parse('app-settings:');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Open your device settings and allow notifications for this app.",
        ),
      ),
    );
  }

  Future<void> _handlePushRegister() async {
    if (_pushActionLoading) return;
    setState(() => _pushActionLoading = true);
    final res = await PushNotificationsService.instance.enable();
    if (!mounted) return;
    res.when(
      success: (state) {
        setState(() {
          _pushState = state;
          _pushActionLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Push enabled.')));
      },
      failure: (err) async {
        setState(() => _pushActionLoading = false);
        final msg = err is ApiException
            ? (err.message ?? 'Push could not be enabled.')
            : 'Push could not be enabled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        if (err is ApiException &&
            err.message.toLowerCase().contains('permission')) {
          await _showPushPermissionDialog();
        }
      },
    );
  }

  Future<void> _handlePushUnregister() async {
    if (_pushActionLoading) return;
    setState(() => _pushActionLoading = true);
    final res = await PushNotificationsService.instance.disable();
    if (!mounted) return;
    res.when(
      success: (_) async {
        await _loadPushState();
        if (!mounted) return;
        setState(() => _pushActionLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Push disabled.')));
      },
      failure: (err) {
        setState(() => _pushActionLoading = false);
        final msg = err is ApiException
            ? (err.message ?? 'Push could not be disabled.')
            : 'Push could not be disabled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
  }

  Future<void> _showPushPermissionDialog() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (_) => const _PushSettingsDialog(),
    );
    if (shouldOpen == true) {
      await _openNotificationSettings();
    }
  }

  Future<void> _confirmPushAction() async {
    final state =
        _pushState ?? await PushNotificationsService.instance.getStatus();
    if (!mounted) return;

    if (state.registered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const _PushUnregisterDialog(),
      );
      if (confirmed == true) {
        await _handlePushUnregister();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _PushRegisterDialog(),
    );
    if (confirmed == true) {
      await _handlePushRegister();
    }
  }

  Future<void> _handlePushTest() async {
    final state =
        _pushState ?? await PushNotificationsService.instance.getStatus();
    if (!mounted) return;

    if (!state.registered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const _PushRegisterDialog(
          title: 'Enable push to test?',
          message:
              'Push is not enabled yet. Turn it on so we can send a test notification to this device.',
          confirmLabel: 'Enable',
        ),
      );
      if (confirmed == true) {
        await _handlePushRegister();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _PushTestDialog(),
    );
    if (confirmed != true) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test push queued.')));
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

  String _extractProfileImageUrl(SuperadminProfile? profile) {
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

  String _extractWhatsapp(SuperadminProfile? profile) {
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

  Future<void> _loadProfile() async {
    _profileToken?.cancel('Reload profile');
    final token = CancelToken();
    _profileToken = token;

    if (!mounted) return;
    setState(() => _loadingProfile = true);

    try {
      _ensureRepo();
      final res = await _repo!.getSuperadminProfile(cancelToken: token);
      if (!mounted) return;
      res.when(
        success: (profile) {
          setState(() {
            _loadingProfile = false;
            _profile = profile;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingProfile = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to load profile.'
                  : "Couldn't load profile.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load profile.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width);
    final double topPadding = MediaQuery.of(context).padding.top;

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
                    NavigateBox(
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
                        companyName: _display(_profile?.companyName),
                        companyWebsite: _display(_profile?.website),
                        companyId: _display(
                          _profile?.company['id']?.toString(),
                        ),
                        primaryColor: _display(
                          _profile?.company['primaryColor']?.toString(),
                        ),
                        customDomain: _display(
                          _profile?.company['customDomain']?.toString(),
                        ),
                        socialLabels: _profile?.socialLabels ?? const [],
                        socialLinks: _profile?.company['socialLinks'] is Map
                            ? Map<String, dynamic>.from(
                                (_profile?.company['socialLinks'] as Map).cast(),
                              )
                            : const {},
                        createdParts: _formatDateTimeParts(
                          _profile?.createdAt,
                        ),
                        updatedParts: _formatDateTimeParts(
                          _profile?.lastLogin.isNotEmpty == true
                              ? _profile?.lastLogin
                              : _profile?.raw['data']?['data']?['updatedAt']
                                  ?.toString(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PushDiagnosticsCard(
                        state: _pushState,
                        loading: _pushActionLoading,
                        onConfirmAction: _confirmPushAction,
                        onSendTest: _handlePushTest,
                      ),
                    ],
                    if (selectedTab == 'Localization') ...[
                      const SizedBox(height: 16),
                      const LocalizationHeader(),
                      const SizedBox(height: 24),
                    ],
                    if (selectedTab == 'Settings') ...[
                      const SizedBox(height: 16),
                      const SuperadminSettingsTab(),
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
              child: const SuperAdminHomeAppBar(
                title: 'Settings',
                leadingIcon: Icons.settings,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavigateBox extends StatelessWidget {
  final String selectedTab;
  final List<String> tabs;
  final ValueChanged<String> onTabSelected;

  const NavigateBox({
    super.key,
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
            "System Settings",
            style: GoogleFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Manage platform configuration",
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
                    child: SmallTab(
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

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final double fontSize;
  final double iconSize;
  final VoidCallback onTap;

  const SmallTab({
    super.key,
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
              color: primary
                  ? cs.primary
                  : cs.onSurface.withOpacity(0.12),
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
                        style: AppUtils.headlineSmallBase.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profile',
                        style: AppUtils.bodySmallBase.copyWith(
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
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                actionButton(
                  icon: Icons.lock_outline,
                  label: 'Password',
                  onTap: () {},
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
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = 13 * scale;
    final double timeSize = 12 * scale;

    Widget cell({
      required String label,
      required String date,
      required String time,
    }) {
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
                  style: AppUtils.bodySmallBase.copyWith(
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
                  style: AppUtils.bodySmallBase.copyWith(
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
                  style: AppUtils.bodySmallBase.copyWith(
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
                  style: AppUtils.bodySmallBase.copyWith(
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
                  style: AppUtils.bodySmallBase.copyWith(
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
                  style: AppUtils.bodySmallBase.copyWith(
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
              style: AppUtils.bodySmallBase.copyWith(
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
                style: AppUtils.bodySmallBase.copyWith(
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
                      style: AppUtils.bodySmallBase.copyWith(
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
                      style: AppUtils.headlineSmallBase.copyWith(
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
                      style: AppUtils.bodySmallBase.copyWith(
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

class _PushDiagnosticsCard extends StatelessWidget {
  final PushDeviceState? state;
  final bool loading;
  final VoidCallback onConfirmAction;
  final VoidCallback onSendTest;

  const _PushDiagnosticsCard({
    required this.state,
    required this.loading,
    required this.onConfirmAction,
    required this.onSendTest,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double headingFs = 18 * scale;
    final double subtitleFs = 12 * scale;
    final double alertFs = 12 * scale;

    final permissionLabel = state == null
        ? 'Checking...'
        : (!state!.supported
            ? 'Unsupported'
            : (state!.registered
                ? 'Allowed'
                : (state!.askedOnce ? 'Blocked' : 'Not requested')));
    final tokenLabel = state == null
        ? '—'
        : (state!.token?.isNotEmpty == true ? 'Registered' : 'None');
    final showPermissionWarning =
        state != null && state!.supported && !state!.enabledByUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Push Diagnostics",
            style: GoogleFonts.roboto(
              fontSize: headingFs,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Notification permission and push state",
            style: GoogleFonts.roboto(
              fontSize: subtitleFs,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double gap = 10;
              final double cellWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: "Permission",
                      value: permissionLabel,
                      scale: scale,
                      width: width,
                      colorScheme: cs,
                    ),
                  ),
                  SizedBox(
                    width: cellWidth,
                    child: _pushInfoBox(
                      title: "Server Tokens",
                      value: tokenLabel,
                      scale: scale,
                      width: width,
                      colorScheme: cs,
                    ),
                  ),
                ],
              );
            },
          ),
          if (showPermissionWarning) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16 * scale,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Notifications are blocked. Open your device settings and allow notifications, then click 'Re-register push'.",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: alertFs,
                        height: 17 / 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onConfirmAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    (state?.registered ?? false)
                        ? Icons.notifications_off
                        : Icons.refresh,
                    size: 16 * scale,
                    color: cs.onPrimary,
                  ),
                  label: Text(
                    (state?.registered ?? false)
                        ? "Unregister"
                        : "Re-register",
                    style: GoogleFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onSendTest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: cs.onSurface.withOpacity(0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.send,
                    size: 16 * scale,
                    color: cs.onSurface,
                  ),
                  label: Text(
                    "Send push test",
                    style: GoogleFonts.roboto(
                      fontSize: 14 * scale,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pushInfoBox({
    required String title,
    required String value,
    required double scale,
    required double width,
    required ColorScheme colorScheme,
  }) {
    final double labelFs = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueFs = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: labelFs,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PushSettingsDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _PushSettingsDialog({
    this.title = 'Enable push notifications?',
    this.message =
        'Enable push notifications to get important updates and alerts on this device.',
    this.confirmLabel = 'Open settings',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmLabel,
            style: GoogleFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _PushRegisterDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _PushRegisterDialog({
    this.title = 'Enable push notifications?',
    this.message =
        'Enable push notifications to get important updates and alerts on this device.',
    this.confirmLabel = 'Enable',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            confirmLabel,
            style: GoogleFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _PushUnregisterDialog extends StatelessWidget {
  const _PushUnregisterDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Unregister push?',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        'This device will stop receiving push notifications.',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Unregister',
            style: GoogleFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}

class _PushTestDialog extends StatelessWidget {
  const _PushTestDialog();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Send test push?',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        'We will send a test notification to this device.',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w500,
          color: cs.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.roboto(color: cs.onSurface),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Send',
            style: GoogleFonts.roboto(color: cs.onPrimary),
          ),
        ),
      ],
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
    final double avatarSize = 44 * scale;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(width) + 1;
    final double labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final double valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceVariant
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_outline,
                        size: 22 * scale,
                        color: cs.onSurface,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      size: 22 * scale,
                      color: cs.onSurface,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account',
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loading ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.headlineSmallBase.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppUtils.bodySmallBase.copyWith(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withOpacity(0.6),
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
