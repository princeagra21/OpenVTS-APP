import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_screen.dart';
import 'package:open_vts/features/support/di/support_providers.dart';
import 'package:open_vts/features/support/presentation/controllers/support_controller.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/presentation/ticket_details/ticket_details_screen.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_empty_state.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_filters.dart';
import 'package:open_vts/features/support/presentation/widgets/ticket_list.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/features/superadmin/presentation/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/features/user/presentation/components/appbars/user_home_appbar.dart';

class SupportInboxScreen extends ConsumerStatefulWidget {
  const SupportInboxScreen({super.key, required this.role});

  final SupportRole role;

  @override
  ConsumerState<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends ConsumerState<SupportInboxScreen> {
  late final SupportRoleConfig _config;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _config = _configFor(widget.role);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  SupportRoleConfig _configFor(SupportRole role) {
    switch (role) {
      case SupportRole.admin:
        return SupportRoleConfigs.admin;
      case SupportRole.user:
        return SupportRoleConfigs.user;
      case SupportRole.superadmin:
        return SupportRoleConfigs.superadmin;
    }
  }

  Future<void> _openNewTicket() async {
    final supportState = ref.read(supportControllerProvider(_config));
    final bool? created;
    switch (_config.role) {
      case SupportRole.admin:
        created = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => SupportNewTicketScreen.admin(
              forMyTickets: supportState.scope == SupportListScope.mine,
            ),
          ),
        );
        break;
      case SupportRole.user:
        created = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => const SupportNewTicketScreen.user(),
          ),
        );
        break;
      case SupportRole.superadmin:
        created = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => const SupportNewTicketScreen.superadmin(),
          ),
        );
        break;
    }

    if (created == true) {
      await ref.read(supportControllerProvider(_config).notifier).loadTickets();
    }
  }

  Future<void> _openTicket(SupportTicketSummary ticket) async {
    final supportState = ref.read(supportControllerProvider(_config));
    final raw = <String, dynamic>{
      ...ticket.raw,
      'id': ticket.id,
      'subject': ticket.subject,
      'status': ticket.status,
      'ownerName': ticket.ownerName,
      'description': ticket.description,
      'category': ticket.category,
      'priority': ticket.priority,
      'ticketNumber': ticket.ticketNumber,
      'createdAt': ticket.createdAt,
      'updatedAt': ticket.updatedAt,
    };

    final bool? changed;
    switch (_config.role) {
      case SupportRole.admin:
        changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => SupportTicketDetailsScreen.admin(
              ticket: AdminTicketListItem(raw),
              forMyTickets: supportState.scope == SupportListScope.mine,
            ),
          ),
        );
        break;
      case SupportRole.user:
        changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => SupportTicketDetailsScreen.user(
              ticket: AdminTicketListItem(raw),
            ),
          ),
        );
        break;
      case SupportRole.superadmin:
        changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) =>
                SupportTicketDetailsScreen.superadmin(ticket: ticket),
          ),
        );
        break;
    }

    if (changed == true) {
      await ref.read(supportControllerProvider(_config).notifier).loadTickets();
    }
  }

  Widget _buildRoleAppBar() {
    switch (_config.role) {
      case SupportRole.admin:
        return const AdminHomeAppBar(
          title: 'Support',
          leadingIcon: Icons.support_agent_outlined,
        );
      case SupportRole.user:
        return const UserHomeAppBar(
          title: 'Support',
          leadingIcon: Icons.support_agent_outlined,
        );
      case SupportRole.superadmin:
        return const SuperAdminHomeAppBar(
          title: 'Support',
          leadingIcon: Icons.support_agent_outlined,
        );
    }
  }

  String _scopeLabel(SupportListScope scope) {
    if (scope == SupportListScope.mine) return 'My Tickets';
    return 'All Tickets';
  }

  Widget _scopeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? cs.onSurface : Colors.transparent,
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: AppFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? cs.surface : cs.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;

    final provider = supportControllerProvider(_config);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen(provider.select((value) => value.effect), (previous, next) {
      if (next == null || previous == next) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message)));
      controller.clearEffect();
    });

    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final tickets = state.filteredTickets;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: controller.loadTickets,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hp,
                  topPadding + AppUtils.appBarHeightCustom + 28,
                  hp,
                  hp,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(hp),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _config.title,
                                  style: AppFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tickets.length} in ${_scopeLabel(state.scope).toLowerCase()}',
                                  style: AppFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withValues(alpha: 0.62),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _openNewTicket,
                            icon: const Icon(Icons.add),
                            label: const Text('New Ticket'),
                          ),
                        ],
                      ),
                      if (_config.permissions.canViewMyTicketsTab) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _scopeChip(
                              label: 'All Tickets',
                              selected:
                                  state.scope == SupportListScope.all,
                              onTap: () {
                                controller.setScope(SupportListScope.all);
                              },
                            ),
                            const SizedBox(width: 8),
                            _scopeChip(
                              label: 'My Tickets',
                              selected:
                                  state.scope == SupportListScope.mine,
                              onTap: () {
                                controller.setScope(SupportListScope.mine);
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      TicketFilters(
                        searchController: _searchController,
                        selectedTab: state.selectedTab,
                        onTabChanged: controller.setTab,
                        onSearchChanged: controller.setSearchQuery,
                      ),
                      const SizedBox(height: 14),
                      if (state.errorMessage != null &&
                          !state.isLoading &&
                          tickets.isEmpty)
                        TicketEmptyState(
                          message: state.errorMessage!,
                          action: FilledButton.icon(
                            onPressed: controller.loadTickets,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        )
                      else
                        TicketList(
                          tickets: tickets,
                          loading: state.isLoading,
                          onOpenTicket: _openTicket,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: hp, right: hp, top: 0, child: _buildRoleAppBar()),
        ],
      ),
    );
  }
}
