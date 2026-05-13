import 'package:open_vts/features/superadmin/presentation/components/admin/localization/localization.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/navigate.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/documents_tab/documents_tab.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/profile_tab.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/payments_tab/admin_payments_tab.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/vehicles_tab/admin_vehicles_tab.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/credit_history/admin_credit_history_tab.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/setting_tab/setting.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/activity_tab/admin_activity_tab.dart';
import 'package:open_vts/features/superadmin/presentation/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/features/superadmin/di/superadmin_admin_providers.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AdministratorDetailsScreen extends ConsumerStatefulWidget {
  // Made stateful to manage tab state
  final String id;
  final bool? initialActive;

  const AdministratorDetailsScreen({
    super.key,
    required this.id,
    this.initialActive,
  });

  @override
  ConsumerState<AdministratorDetailsScreen> createState() =>
      _AdministratorDetailsScreenState();
}

class _AdministratorDetailsScreenState
    extends ConsumerState<AdministratorDetailsScreen> {
  String selectedTab = "Profile";
  final int _profileReloadNonce = 0;
  int _detailReloadNonce = 0;
  bool _headerLoading = false;
  String _headerName = 'Admin Details';
  bool _statusChanged = false;

  final List<String> tabs = [
    "Profile",
    "Documents",
    "Credit History",
    "Payments",
    "Vehicles",
    "Settings",
    "Admin Activity",
  ];

  @override
  void initState() {
    super.initState();
    _loadHeader();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _safe(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  Future<void> _loadHeader() async {
    if (!mounted) return;
    updateLocalUiState(this, () => _headerLoading = true);

    final res = await ref.read(getSuperadminAdminDetailUseCaseProvider)(widget.id);
    if (!mounted) return;
    res.when(
      success: (profile) {
        final name = _safe(profile.name, fallback: _safe(profile.username, fallback: 'Admin Details'));
        updateLocalUiState(this, () {
          _headerLoading = false;
          _headerName = name;
        });
      },
      failure: (_) => updateLocalUiState(this, () => _headerLoading = false),
    );
  }

  Future<void> _refreshDetails() async {
    await _loadHeader();
    if (!mounted) return;
    updateLocalUiState(this, () => _detailReloadNonce++);
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
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onRefresh: _refreshDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      updateLocalUiState(this, () {
                        selectedTab = newTab;
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  KeyedSubtree(
                    key: ValueKey('detail_${selectedTab}_$_detailReloadNonce'),
                    child: _buildTabContent(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
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
      case "Documents":
        return Column(
          children: [
            const SizedBox(height: 24),
            DocumentsTab(adminId: widget.id),
            const SizedBox(height: 24),
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
            SuperadminLocalizationScreen(),
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
            AdminPaymentsTab(adminId: widget.id, adminName: _headerName),
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
