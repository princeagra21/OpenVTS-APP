import 'package:open_vts/core/error/error_presenter.dart';
import 'package:open_vts/features/admin/presentation/components/admin/navigate.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_user_detail_controller.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_activity_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_details_ui.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_documents_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_drivers_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_payments_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_profile_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_tickets_tab.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/admin_user_vehicles_tab.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class UserDetailsScreen extends ConsumerStatefulWidget {
  final String id;
  final String? name;

  const UserDetailsScreen({
    super.key,
    required this.id,
    this.name,
  });

  @override
  ConsumerState<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserDetailsScreen> {
  String _selectedTab = 'Profile';
  int _detailReloadNonce = 0;
  String? _lastErrorMessage;

  final List<String> _tabs = const [
    'Profile',
    'Vehicles',
    'Drivers',
    'Documents',
    'Tickets',
    'Payments',
    'Activity Logs',
  ];

  void _showErrorOnce(Object? error, String fallback) {
    if (!mounted || error == null) return;
    final message = ErrorPresenter.message(error, fallback: fallback);
    if (_lastErrorMessage == message) return;
    _lastErrorMessage = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget tabSelectionCard(
    BuildContext context, {
    required String selectedTab,
    required List<String> tabs,
    required String title,
    required String subtitle,
    required ValueChanged<String> onTabSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? OpenVtsColors.panelDarkAlt : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final selected = tab == selectedTab;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => onTabSelected(tab),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary
                            : isDark
                                ? Colors.white.withOpacity(0.06)
                                : OpenVtsColors.panelLightAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTab(String tab) {
    if (_selectedTab == tab) return;

    updateLocalUiState(this, () => _selectedTab = tab);
    _ensureSelectedTabLoaded(tab);
  }

  void _ensureSelectedTabLoaded(String tab) {
    final state = ref.read(adminUserDetailControllerProvider(widget.id));
    final controller = ref.read(adminUserDetailControllerProvider(widget.id).notifier);
    switch (tab) {
      case 'Vehicles':
        if (!state.vehiclesLoaded && !state.isLoadingVehicles) {
          controller.loadVehicles();
        }
        break;
      case 'Drivers':
        if (!state.driversLoaded && !state.isLoadingDrivers) {
          controller.loadDrivers();
        }
        break;
      case 'Payments':
        if (!state.paymentsLoaded && !state.isLoadingPayments) {
          controller.loadPayments();
        }
        break;
      case 'Documents':
        if (!state.documentsLoaded && !state.isLoadingDocuments) {
          controller.loadDocuments();
        }
        break;
      case 'Tickets':
        if (!state.ticketsLoaded && !state.isLoadingTickets) {
          controller.loadTickets();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _refreshDetails() async {
    await ref
        .read(adminUserDetailControllerProvider(widget.id).notifier)
        .refreshActiveTab(_selectedTab);

    if (mounted) {
      updateLocalUiState(this, () => _detailReloadNonce++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailProvider = adminUserDetailControllerProvider(widget.id);
    final state = ref.watch(detailProvider);

    ref.listen<AdminUserDetailState>(detailProvider, (previous, next) {
      if (next.error == null || previous?.error == next.error) return;
      _showErrorOnce(next.error, "Couldn't load user details.");
    });

    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;
    final scale = (width / 420).clamp(0.9, 1.0);
    final bodyFs = 14 * scale;
    final smallFs = 12 * scale;

    final headerName =
        widget.name?.trim().isNotEmpty == true ? widget.name! : 'User Details';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
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
                      selectedTab: _selectedTab,
                      tabs: _tabs,
                      title: 'User mobile screens',
                      subtitle: 'Switch between the user screens below.',
                      onTabSelected: _selectTab,
                    ),
                    const SizedBox(height: 4),
                    KeyedSubtree(
                      key: ValueKey(
                        'admin_user_${_selectedTab}_$_detailReloadNonce',
                      ),
                      child: _buildTabContent(state, bodyFs, smallFs),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: AdminHomeAppBar(
              title: headerName,
              leadingIcon: Symbols.group,
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

  Widget _buildTabContent(
    AdminUserDetailState state,
    double bodyFs,
    double smallFs,
  ) {
    switch (_selectedTab) {
      case 'Profile':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserProfileTab(
              details: state.user,
              loading: state.isLoading,
              bodyFontSize: bodyFs,
              userId: widget.id,
              onRefresh: ({bool silent = false}) {
                ref
                    .read(adminUserDetailControllerProvider(widget.id).notifier)
                    .load(silent: silent);
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      case 'Vehicles':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserVehiclesTab(
              userId: widget.id,
              items: state.vehicles,
              loading: state.isLoadingVehicles,
              onAssigned: () => ref
                  .read(adminUserDetailControllerProvider(widget.id).notifier)
                  .loadVehicles(force: true),
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Drivers':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserDriversTab(
              items: state.drivers,
              loading: state.isLoadingDrivers,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Documents':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserDocumentsTab(
              userId: widget.id,
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Tickets':
        return Column(
          children: [
            const SizedBox(height: 24),
            if (state.user != null)
              AdminUserTicketsTab(
                userId: widget.id,
                userSummary: state.user!.summary,
              )
            else if (state.isLoading)
              listShimmer(context, count: 2, height: 100)
            else
              const Center(
                child: Text('User details not available.'),
              ),
            const SizedBox(height: 24),
          ],
        );

      case 'Payments':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserPaymentsTab(
              userId: widget.id,
              items: state.payments,
              loading: state.isLoadingPayments,
              bodyFontSize: bodyFs,
              smallFontSize: smallFs,
              onRenew: () => ref
                  .read(adminUserDetailControllerProvider(widget.id).notifier)
                  .loadPayments(force: true),
            ),
            const SizedBox(height: 24),
          ],
        );

      case 'Activity Logs':
        return Column(
          children: [
            const SizedBox(height: 24),
            AdminUserActivityTab(userId: widget.id),
            const SizedBox(height: 24),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
