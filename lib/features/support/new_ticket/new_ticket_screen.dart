import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/support/new_ticket/new_ticket_controller.dart';
import 'package:open_vts/features/support/new_ticket/new_ticket_validators.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_admin_selector.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_attachment_picker.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_category_selector.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_message_field.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_priority_selector.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_subject_field.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_submit_bar.dart';
import 'package:open_vts/features/support/new_ticket/widgets/ticket_user_selector.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';

class SupportNewTicketScreen extends StatefulWidget {
  const SupportNewTicketScreen.admin({
    super.key,
    this.preSelectedUser,
    this.forMyTickets = false,
  }) : _role = SupportRole.admin;

  const SupportNewTicketScreen.user({super.key})
    : _role = SupportRole.user,
      preSelectedUser = null,
      forMyTickets = false;

  const SupportNewTicketScreen.superadmin({super.key})
    : _role = SupportRole.superadmin,
      preSelectedUser = null,
      forMyTickets = false;

  final SupportRole _role;
  final AdminUserListItem? preSelectedUser;
  final bool forMyTickets;

  @override
  State<SupportNewTicketScreen> createState() => _SupportNewTicketScreenState();
}

class _SupportNewTicketScreenState extends State<SupportNewTicketScreen> {
  late final SupportRoleConfig _config;
  late final NewTicketController _controller;

  @override
  void initState() {
    super.initState();
    _config = SupportRoleConfigs.forRole(widget._role);
    _controller = NewTicketController(
      role: widget._role,
      config: _config,
      repository: SupportRepositoryFactory.forRole(widget._role),
      preSelectedUser: widget.preSelectedUser,
      forMyTickets: widget.forMyTickets,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRoleAppBar() {
    final title = _config.role == SupportRole.admin && widget.forMyTickets
        ? 'My Ticket'
        : 'Create Ticket';

    switch (_config.role) {
      case SupportRole.admin:
        return AdminHomeAppBar(
          title: title,
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context),
        );
      case SupportRole.user:
        return UserHomeAppBar(
          title: title,
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context),
        );
      case SupportRole.superadmin:
        return SuperAdminHomeAppBar(
          title: title,
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context),
        );
    }
  }

  Widget _buildAssigneeSection() {
    if (_config.role == SupportRole.admin && widget.forMyTickets) {
      return const SizedBox.shrink();
    }

    final isAdminAssignee = _config.role == SupportRole.superadmin;
    final disabled = widget.preSelectedUser != null && !isAdminAssignee;

    if (isAdminAssignee) {
      return TicketAdminSelector(
        selectedAdmin: _controller.state.selectedAdmin,
        admins: _controller.state.admins,
        loading: _controller.state.loadingAssignees,
        onSelect: _controller.selectAdmin,
      );
    } else {
      return TicketUserSelector(
        selectedUser: _controller.state.selectedUser,
        users: _controller.state.users,
        loading: _controller.state.loadingAssignees,
        disabled: disabled,
        onSelect: _controller.selectUser,
      );
    }
  }

  void _showWarning(String message) {
    if (!mounted) return;
    OpenVtsFeedback.warning(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    OpenVtsFeedback.success(context, message);
  }

  void _showError(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
  }

  Future<void> _submit() async {
    final title = _controller.state.titleController?.text.trim() ?? '';
    final message = _controller.state.messageController?.text.trim() ?? '';

    final assigneeError = NewTicketValidators.validateAssignee(
      _controller.state.selectedUser,
      _controller.state.selectedAdmin,
      _controller.role,
      _controller.forMyTickets,
    );
    if (assigneeError != null) {
      _showWarning(assigneeError);
      return;
    }

    final titleError = NewTicketValidators.validateTitle(title, _controller.role);
    if (titleError != null) {
      _showWarning(titleError);
      return;
    }

    final messageError = NewTicketValidators.validateMessage(message, _controller.role);
    if (messageError != null) {
      _showWarning(messageError);
      return;
    }

    final categoryError = NewTicketValidators.validateCategory(_controller.state.selectedCategory);
    if (categoryError != null) {
      _showWarning(categoryError);
      return;
    }

    final priorityError = NewTicketValidators.validatePriority(_controller.state.selectedPriority);
    if (priorityError != null) {
      _showWarning(priorityError);
      return;
    }

    final attachmentError = NewTicketValidators.validateAttachments(_controller.state.attachments, _controller.role);
    if (attachmentError != null) {
      _showWarning(attachmentError);
      return;
    }

    final success = await _controller.submit();
    if (success) {
      _showSuccess('Ticket created.');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      _showError("Couldn't create ticket.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _config.role == SupportRole.admin && !widget.forMyTickets
                          ? 'Create Ticket (on behalf of User)'
                          : _config.role == SupportRole.superadmin
                          ? 'Create Ticket (on behalf of Admin)'
                          : 'Create Ticket',
                      style: AppFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildAssigneeSection(),
                    Row(
                      children: [
                        TicketCategorySelector(
                          role: _controller.role,
                          selectedCategory: _controller.state.selectedCategory,
                          onChanged: _controller.selectCategory,
                        ),
                        const SizedBox(width: 12),
                        TicketPrioritySelector(
                          role: _controller.role,
                          selectedPriority: _controller.state.selectedPriority,
                          onChanged: _controller.selectPriority,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_controller.state.titleController != null)
                      TicketSubjectField(
                        controller: _controller.state.titleController!,
                        role: _controller.role,
                      ),
                    const SizedBox(height: 8),
                    if (_controller.state.messageController != null)
                      TicketMessageField(
                        controller: _controller.state.messageController!,
                        role: _controller.role,
                      ),
                    if (_controller.showAttachmentSection) ...[
                      const SizedBox(height: 12),
                      TicketAttachmentPicker(
                        attachments: _controller.state.attachments,
                        submitting: _controller.state.submitting,
                        role: _controller.role,
                        onPick: _controller.pickAttachment,
                        onRemove: _controller.removeAttachment,
                      ),
                    ],
                    const SizedBox(height: 20),
                    TicketSubmitBar(
                      submitting: _controller.state.submitting,
                      onCancel: () => Navigator.pop(context, false),
                      onSubmit: _submit,
                    ),
                  ],
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