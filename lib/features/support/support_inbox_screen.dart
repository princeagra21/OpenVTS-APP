import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_ticket_list_item.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/support/new_ticket/new_ticket_screen.dart';
import 'package:open_vts/features/support/support_controller.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_screen.dart';
import 'package:open_vts/features/support/widgets/ticket_empty_state.dart';
import 'package:open_vts/features/support/widgets/ticket_filters.dart';
import 'package:open_vts/features/support/widgets/ticket_list.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';

class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({super.key, required this.role});

  final SupportRole role;

  @override
  State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  late final SupportRoleConfig _config;
  late final SupportController _controller;

  @override
  void initState() {
    super.initState();
    _config = _configFor(widget.role);
    _controller = SupportController(
      config: _config,
      repository: SupportRepositoryFactory.forRole(widget.role),
    )..addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadTickets();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
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
    final bool? created;
    switch (_config.role) {
      case SupportRole.admin:
        created = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => SupportNewTicketScreen.admin(
              forMyTickets: _controller.scope == SupportListScope.mine,
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
      await _controller.loadTickets();
    }
  }

  Future<void> _openTicket(SupportTicketSummary ticket) async {
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
              forMyTickets: _controller.scope == SupportListScope.mine,
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
      await _controller.loadTickets();
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

    final tickets = _controller.filteredTickets;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _controller.loadTickets,
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
                                  '${tickets.length} in ${_scopeLabel(_controller.scope).toLowerCase()}',
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
                                  _controller.scope == SupportListScope.all,
                              onTap: () {
                                _controller.setScope(SupportListScope.all);
                                _controller.loadTickets();
                              },
                            ),
                            const SizedBox(width: 8),
                            _scopeChip(
                              label: 'My Tickets',
                              selected:
                                  _controller.scope == SupportListScope.mine,
                              onTap: () {
                                _controller.setScope(SupportListScope.mine);
                                _controller.loadTickets();
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      TicketFilters(
                        searchController: _controller.searchController,
                        selectedTab: _controller.selectedTab,
                        onTabChanged: _controller.setTab,
                      ),
                      const SizedBox(height: 14),
                      if (_controller.errorMessage != null &&
                          !_controller.loading &&
                          tickets.isEmpty)
                        TicketEmptyState(
                          message: _controller.errorMessage!,
                          action: FilledButton.icon(
                            onPressed: _controller.loadTickets,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        )
                      else
                        TicketList(
                          tickets: tickets,
                          loading: _controller.loading,
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
