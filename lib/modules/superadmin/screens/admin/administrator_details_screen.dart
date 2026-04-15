import 'package:fleet_stack/modules/superadmin/components/admin/localization/localization.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_box.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/profile_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/payments_tab/admin_payments_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/vehicles_tab/admin_vehicles_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/credit_history/admin_credit_history_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/setting_tab/setting.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/activity_tab/admin_activity_tab.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class AdministratorDetailsScreen extends StatefulWidget {
  // Made stateful to manage tab state
  final String id;
  final bool? initialActive;

  const AdministratorDetailsScreen({
    super.key,
    required this.id,
    this.initialActive,
  });

  @override
  State<AdministratorDetailsScreen> createState() =>
      _AdministratorDetailsScreenState();
}

class _AdministratorDetailsScreenState
    extends State<AdministratorDetailsScreen> {
  String selectedTab = "Profile";
  int _profileReloadNonce = 0;
  bool _headerLoading = false;
  String _headerName = 'Admin Details';
  String _headerInitials = 'AD';
  bool _statusChanged = false;
  CancelToken? _headerToken;
  ApiClient? _api;
  SuperadminRepository? _repo;

  final List<String> tabs = [
    "Profile",
    "Credit History",
    "Payments",
    "Vehicles",
    "Settings",
    "Role",
    "Admin Activity",
  ];

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  @override
  void dispose() {
    _headerToken?.cancel('AdministratorDetailsScreen disposed');
    super.dispose();
  }

  String _safe(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _initials(String value) {
    final t = value.trim();
    if (t.isEmpty || t == '-') return 'AD';
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'AD';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  Future<void> _loadHeader() async {
    _headerToken?.cancel('Reload administrator header');
    final token = CancelToken();
    _headerToken = token;

    if (!mounted) return;
    setState(() => _headerLoading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdminProfile(widget.id, cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          final name = _safe(
            profile.fullName,
            fallback: _safe(profile.username, fallback: 'Admin Details'),
          );
          setState(() {
            _headerLoading = false;
            _headerName = name;
            _headerInitials = _initials(name);
          });
        },
        failure: (_) {
          if (!mounted) return;
          setState(() => _headerLoading = false);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _headerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              horizontalPadding,
              84,
            ),
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
            const SizedBox(height: 4),
            _buildTabContent(), // Dynamic content based on selected tab
            const SizedBox(height: 24),
          ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: SuperAdminHomeAppBar(
              title: _headerLoading ? "Loading..." : _headerName,
              leadingIcon: Symbols.verified_user,
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(_statusChanged);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case "Profile":
        return Column(
          children: [
            const SizedBox(height: 24),
            ProfileTab(
              key: ValueKey('profile_${widget.id}_$_profileReloadNonce'),
              adminId: widget.id,
              onStatusChanged: () => _statusChanged = true,
              initialActive: widget.initialActive,
            ),
          ],
        );
      case "Settings":
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminSettingsTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );
      case "Localization":
        return Column(
          children: const [
            SizedBox(height: 24),
            LocalizationHeader(),
            SizedBox(height: 24),
          ],
        );
      case "Credit History":
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminCreditHistoryTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );
      case "Payments":
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminPaymentsTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );
      case "Vehicles":
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminVehiclesTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );
      case "Role":
        return Column(
          children: const [
            SizedBox(height: 24),
            Center(child: Text('Coming soon')),
            SizedBox(height: 24),
          ],
        );
      case "Admin Activity":
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminActivityTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// Temporary placeholder widget - replace with your actual content widgets
class PlaceholderContent extends StatelessWidget {
  final String label;

  const PlaceholderContent({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
