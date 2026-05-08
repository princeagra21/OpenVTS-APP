import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/modules/superadmin/components/admin/localization/localization.dart';
import 'package:open_vts/modules/superadmin/components/admin/setting_tab/superadmin_settings_tab.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:dio/dio.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/models/superadmin_profile.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/modules/superadmin/components/admin/profile_tab/edit_admin_profile_screen.dart';
import 'package:open_vts/modules/superadmin/components/admin/profile_tab/update_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_colors.dart';
import 'package:open_vts/core/navigation/app_routes.dart';
import 'package:open_vts/core/network/api_paths.dart';

part 'superadmin_settings_screen_navigation.dart';
part 'superadmin_settings_screen_profile_sections.dart';

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
  bool _emailOtpLoading = false;
  bool _whatsappOtpLoading = false;
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
    _api = ApiClientProvider.create();
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
    if (value.startsWith(AppRoutes.root)) return '$baseUrl$value';
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

  String _fullAddress(SuperadminProfile? profile) {
    if (profile == null) return '';
    final address = profile.address;
    final full = (address['fullAddress'] ?? address['fulladdress'] ?? '')
        .toString()
        .trim();
    if (full.isNotEmpty) return full;
    final line = (address['addressLine'] ?? profile.addressLine).toString().trim();
    if (line.isNotEmpty) return line;
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

  String _responseMessage(Object? data, {String fallback = 'Request completed.'}) {
    if (data is Map) {
      final root = data.cast<dynamic, dynamic>();
      final direct = root['message']?.toString().trim();
      if (direct != null && direct.isNotEmpty) return direct;
      final d = root['data'];
      if (d is Map) {
        final nested = d['message']?.toString().trim();
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return fallback;
  }

  Future<void> _requestEmailOtp() async {
    if (_emailOtpLoading) return;
    _ensureRepo();
    setState(() => _emailOtpLoading = true);
    final res = await _api!.post(ApiPaths.path('/superadmin/profile/verify/email/request'));
    if (!mounted) return;
    setState(() => _emailOtpLoading = false);
    res.when(
      success: (data) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_responseMessage(data, fallback: 'Email OTP request sent.'))),
        );
      },
      failure: (err) {
        final msg = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : 'Failed to request email OTP.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _requestWhatsappOtp() async {
    if (_whatsappOtpLoading) return;
    _ensureRepo();
    setState(() => _whatsappOtpLoading = true);
    final res = await _api!.post(ApiPaths.path('/superadmin/profile/verify/whatsapp/request'));
    if (!mounted) return;
    setState(() => _whatsappOtpLoading = false);
    res.when(
      success: (data) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_responseMessage(data, fallback: 'WhatsApp OTP request sent.'))),
        );
      },
      failure: (err) {
        final msg = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : 'Failed to request WhatsApp OTP.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width);
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
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
                        profileId: _profile?.id ?? '',
                        name: _display(_profile?.fullName),
                        username: _usernameLabel(_profile?.username),
                        verified: _profile?.isVerified ?? false,
                        imageUrl: _extractProfileImageUrl(_profile),
                        loading: _loadingProfile,
                        emailOtpLoading: _emailOtpLoading,
                        whatsappOtpLoading: _whatsappOtpLoading,
                        onRequestEmailOtp: _requestEmailOtp,
                        onRequestWhatsappOtp: _requestWhatsappOtp,
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
                        address: _display(_fullAddress(_profile)),
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
                  ? OpenVtsColors.panelDark
                  : OpenVtsColors.panelLight,
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

