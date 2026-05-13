import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/presentation/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/features/superadmin/presentation/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/features/support/di/support_new_ticket_controller_provider.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/presentation/new_ticket/new_ticket_controller.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_admin_selector.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_attachment_picker.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_category_selector.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_message_field.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_priority_selector.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_subject_field.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_submit_bar.dart';
import 'package:open_vts/features/support/presentation/new_ticket/widgets/ticket_user_selector.dart';
import 'package:open_vts/features/user/presentation/components/appbars/user_home_appbar.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_components.dart';

class SupportNewTicketScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SupportNewTicketScreen> createState() =>
      _SupportNewTicketScreenState();
}

class _SupportNewTicketScreenState extends ConsumerState<SupportNewTicketScreen> {
  late final SupportRoleConfig _config;
  late final NewTicketArgs _args;
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _config = SupportRoleConfigs.forRole(widget._role);
    _args = NewTicketArgs(
      role: widget._role,
      preSelectedUser: widget.preSelectedUser,
      forMyTickets: widget.forMyTickets,
    );
    _titleController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
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
    final state = ref.watch(newTicketControllerProvider(_args));
    final controller = ref.read(newTicketControllerProvider(_args).notifier);

    if (_config.role == SupportRole.admin && widget.forMyTickets) {
      return const SizedBox.shrink();
    }

    final isAdminAssignee = _config.role == SupportRole.superadmin;
    final disabled = widget.preSelectedUser != null && !isAdminAssignee;

    if (isAdminAssignee) {
      return TicketAdminSelector(
        selectedAdmin: state.selectedAdmin,
        admins: state.admins,
        loading: state.loadingAssignees,
        onSelect: controller.selectAdmin,
      );
    }

    return TicketUserSelector(
      selectedUser: state.selectedUser,
      users: state.users,
      loading: state.loadingAssignees,
      disabled: disabled,
      onSelect: controller.selectUser,
    );
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
    final controller = ref.read(newTicketControllerProvider(_args).notifier);
    final error = controller.validate(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
    );
    if (error != null) {
      _showWarning(error);
      return;
    }

    final success = await controller.submit(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
    );
    if (success) {
      _showSuccess('Ticket created.');
      if (mounted) Navigator.pop(context, true);
      return;
    }
    final state = ref.read(newTicketControllerProvider(_args));
    _showError(state.errorMessage ?? "Couldn't create ticket.");
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newTicketControllerProvider(_args));
    final controller = ref.read(newTicketControllerProvider(_args).notifier);
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final topPadding = MediaQuery.of(context).padding.top;

    ref.listen(newTicketControllerProvider(_args), (previous, next) {
      final message = next.errorMessage;
      if (message != null && message != previous?.errorMessage) {
        _showWarning(message);
      }
    });

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
                          role: controller.role,
                          selectedCategory: state.selectedCategory,
                          onChanged: controller.selectCategory,
                        ),
                        const SizedBox(width: 12),
                        TicketPrioritySelector(
                          role: controller.role,
                          selectedPriority: state.selectedPriority,
                          onChanged: controller.selectPriority,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TicketSubjectField(
                      controller: _titleController,
                      role: controller.role,
                    ),
                    const SizedBox(height: 8),
                    TicketMessageField(
                      controller: _messageController,
                      role: controller.role,
                    ),
                    if (controller.showAttachmentSection) ...[
                      const SizedBox(height: 12),
                      TicketAttachmentPicker(
                        attachments: state.attachments,
                        submitting: state.submitting,
                        role: controller.role,
                        onPick: controller.pickAttachment,
                        onRemove: controller.removeAttachment,
                      ),
                    ],
                    const SizedBox(height: 20),
                    TicketSubmitBar(
                      submitting: state.submitting,
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
