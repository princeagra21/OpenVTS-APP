import 'package:fleet_stack/modules/superadmin/components/admin/credit_history/credit_history_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/documents_tab/documents_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/navigate.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_box.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/profile_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/role_tab.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/setting_tab/setting.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/vehicles_tab/vehicles_tab.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart'
    show AppLayout;
import 'package:flutter/material.dart';

class AdministratorDetailsScreen extends StatefulWidget {
  // Made stateful to manage tab state
  final String id;

  const AdministratorDetailsScreen({super.key, required this.id});

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
  CancelToken? _headerToken;
  ApiClient? _api;
  SuperadminRepository? _repo;

  final List<String> tabs = [
    "Profile",
    "Credit History",
    "Documents",
    "Vehicles",
    "Setting",
    "Roles",
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
    return AppLayout(
      title: "ADMINISTRATOR",
      subtitle: _headerLoading ? "Loading..." : _headerName,
      showLeftAvatar: false,
      leftAvatarText: _headerInitials,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileBox(
              adminId: widget.id,
              onProfileUpdated: () {
                setState(() {
                  _profileReloadNonce++;
                });
                _loadHeader();
              },
            ), // Assuming this is always visible as a header
            const SizedBox(height: 24),
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
            ),
          ],
        );
      case "Credit History":
        return Column(
          children: [
            const SizedBox(height: 24),
            CreditHistoryTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );
      case "Documents":
        return Column(
          children: [
            const SizedBox(height: 24),
            DocumentsTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );

      case "Vehicles":
        return Column(
          children: [
            const SizedBox(height: 24),
            VehiclesTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );

      case "Setting":
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminSettingsTab(adminId: widget.id),
            const SizedBox(height: 24),
          ],
        );

      case "Roles":
        return Column(
          children: [
            const SizedBox(height: 24),
            RolesTab(adminId: widget.id),
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
