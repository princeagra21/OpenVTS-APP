import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_ticket_list_item.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_controller.dart';
import 'package:open_vts/features/support/ticket_details/ticket_details_state.dart';
import 'package:open_vts/features/support/ticket_details/widgets/ticket_details_composer.dart';
import 'package:open_vts/features/support/ticket_details/widgets/ticket_details_header.dart';
import 'package:open_vts/features/support/ticket_details/widgets/ticket_details_messages.dart';
import 'package:open_vts/features/support/ticket_details/widgets/ticket_details_status_updater.dart';
import 'package:open_vts/features/support/ticket_details/widgets/ticket_details_tabs.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';

class SupportTicketDetailsScreen extends StatefulWidget {
  SupportTicketDetailsScreen.admin({
    super.key,
    required AdminTicketListItem ticket,
    bool forMyTickets = false,
  }) : _role = SupportRole.admin,
       _scope = forMyTickets ? SupportListScope.mine : SupportListScope.all,
       _ticket = _fromAdminTicket(ticket);

  SupportTicketDetailsScreen.user({
    super.key,
    required AdminTicketListItem ticket,
  }) : _role = SupportRole.user,
       _scope = SupportListScope.all,
       _ticket = _fromAdminTicket(ticket);

  const SupportTicketDetailsScreen.superadmin({
    super.key,
    required SupportTicketSummary ticket,
  }) : _role = SupportRole.superadmin,
       _scope = SupportListScope.all,
       _ticket = ticket;

  final SupportRole _role;
  final SupportListScope _scope;
  final SupportTicketSummary _ticket;

  static SupportTicketSummary _fromAdminTicket(AdminTicketListItem ticket) {
    return SupportTicketSummary(
      id: ticket.id,
      subject: ticket.subject,
      status: ticket.statusLabel,
      ownerName: ticket.ownerName,
      description: ticket.description,
      category: ticket.category,
      priority: ticket.priority,
      ticketNumber: ticket.ticketNumber,
      createdAt: ticket.createdAt,
      updatedAt: ticket.updatedAt,
      raw: ticket.raw,
    );
  }

  @override
  State<SupportTicketDetailsScreen> createState() =>
      _SupportTicketDetailsScreenState();
}

class _SupportTicketDetailsScreenState
    extends State<SupportTicketDetailsScreen> {
  late final TicketDetailsState _state;
  late final TicketDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _state = TicketDetailsState(
      role: widget._role,
      scope: widget._scope,
      initialTicket: widget._ticket,
    );
    final config = TicketDetailsController.configFor(widget._role);
    final repository = SupportRepositoryFactory.forRole(widget._role);
    _controller = TicketDetailsController(
      state: _state,
      config: config,
      repository: repository,
    );
    _controller.loadTicketData();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Widget _buildRoleAppBar() {
    switch (_state.role) {
      case SupportRole.admin:
        return AdminHomeAppBar(
          title: 'Ticket Details',
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context, _state.hasChanges),
        );
      case SupportRole.user:
        return UserHomeAppBar(
          title: 'Ticket Details',
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context, _state.hasChanges),
        );
      case SupportRole.superadmin:
        return SuperAdminHomeAppBar(
          title: 'Ticket Details',
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context, _state.hasChanges),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _state.hasChanges);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? OpenVtsColors.panelDark
            : OpenVtsColors.panelLight,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
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
                      TicketDetailsHeader(state: _state),
                      if (_state.ticket.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _state.ticket.description,
                          style: AppFonts.roboto(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      TicketDetailsStatusUpdater(
                        controller: _controller,
                        config: _controller.config,
                        onStatusChanged: (value) => setState(() => _state.selectedStatus = value),
                      ),
                      const SizedBox(height: 14),
                      TicketDetailsTabs(
                        config: _controller.config,
                        state: _state,
                        onTabChanged: (tab) => setState(() => _state.selectedComposerTab = tab),
                      ),
                      const SizedBox(height: 12),
                      TicketDetailsMessages(
                        controller: _controller,
                        onRetry: () => _controller.loadTicketData(),
                      ),
                      const SizedBox(height: 12),
                      TicketDetailsComposer(
                        controller: _controller,
                        config: _controller.config,
                        onSend: () => _controller.sendMessage(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(left: hp, right: hp, top: 0, child: _buildRoleAppBar()),
          ],
        ),
      ),
    );
  }
}