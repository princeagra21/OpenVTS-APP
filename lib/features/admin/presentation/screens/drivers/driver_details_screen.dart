import 'package:open_vts/features/admin/presentation/screens/drivers/widget/admin_driver_documents_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/drivers/widget/admin_driver_profile_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/drivers/widget/admin_driver_users_tab.dart';
import 'package:open_vts/features/admin/presentation/components/admin/navigate.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_driver_providers.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_driver_detail_controller.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AdminDriverDetailsScreen extends ConsumerStatefulWidget {
  final String id;

  const AdminDriverDetailsScreen({super.key, required this.id});

  @override
  ConsumerState<AdminDriverDetailsScreen> createState() =>
      _AdminDriverDetailsScreenState();
}

class _AdminDriverDetailsScreenState extends ConsumerState<AdminDriverDetailsScreen> {
  // Confirmed endpoints:
  // - GET /admin/drivers/:id
  // - GET /admin/documents/driver/:id
  // - GET /admin/drivers/linkedusers/:id
  static const List<String> _tabs = <String>['Profile', 'Documents', 'Users'];

  String _selectedTab = 'Profile';

  bool _documentsLoaded = false;
  bool _usersLoaded = false;



  @override
  void initState() {
    super.initState();
  }

  void _selectTab(String tab) {
    if (_selectedTab == tab) return;
    updateLocalUiState(this, () => _selectedTab = tab);
    _ensureSelectedTabLoaded(tab);
  }

  void _ensureSelectedTabLoaded(String tab) {
    final controller = ref.read(adminDriverDetailControllerProvider(widget.id).notifier);
    switch (tab) {
      case 'Documents':
        if (!_documentsLoaded) {
          _documentsLoaded = true;
          controller.loadDocuments();
        }
        break;
      case 'Users':
        if (!_usersLoaded) {
          _usersLoaded = true;
          controller.loadUsers();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _loadDetails() async {
    await ref.read(adminDriverDetailControllerProvider(widget.id).notifier).loadDetail();
  }

  Future<void> _loadUsers() async {
    _usersLoaded = true;
    await ref.read(adminDriverDetailControllerProvider(widget.id).notifier).loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bodyFs = AdaptiveUtils.getTitleFontSize(screenWidth) - 1;
    final smallFs = AdaptiveUtils.getTitleFontSize(screenWidth) - 3;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
        ? 10.0
        : 12.0;

    final detailState = ref.watch(adminDriverDetailControllerProvider(widget.id));
    final headerName =
        (detailState.detail?.fullName ?? detailState.detail?.username ?? 'Driver Details').trim();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
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
                  selectedTab: _selectedTab,
                  tabs: _tabs,
                  title: 'Driver mobile screens',
                  subtitle: 'Switch between the driver screens below.',
                  onTabSelected: _selectTab,
                ),
                const SizedBox(height: 4),
                _buildTabContent(bodyFs, smallFs, detailState),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: AdminHomeAppBar(
              title: headerName.isEmpty ? 'Driver Details' : headerName,
              leadingIcon: Symbols.badge,
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(double bodyFs, double smallFs, AdminDriverDetailState detailState) {
    switch (_selectedTab) {
      case 'Documents':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminDriverDocumentsTab(driverId: widget.id),
            const SizedBox(height: 24),
          ],
        );
      case 'Users':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminDriverUsersTab(
              items: detailState.linkedUsers,
              loading: detailState.isLoadingUsers,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
              driverId: widget.id,
              repository: ref.read(adminDriverRepositoryProvider),
              onRefreshLinkedUsers: _loadUsers,
            ),
            const SizedBox(height: 24),
          ],
        );
      case 'Profile':
      default:
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminDriverProfileTab(
              details: detailState.detail,
              loading: detailState.isLoadingDetail,
              bodyFontSize: bodyFs,
              driverId: widget.id,
              onRefresh: _loadDetails,
            ),
            const SizedBox(height: 24),
          ],
        );
    }
  }
}


