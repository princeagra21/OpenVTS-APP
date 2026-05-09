import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_ticket_list_item.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/design_system/components/open_vts_feedback.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';
import 'package:open_vts/features/support/widgets/ticket_empty_state.dart';
import 'package:open_vts/features/support/widgets/ticket_message_input.dart';
import 'package:open_vts/features/support/widgets/ticket_message_list.dart';
import 'package:open_vts/features/support/widgets/ticket_status_chip.dart';
import 'package:open_vts/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:open_vts/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

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

  SupportTicketDetailsScreen.superadmin({
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
  final TextEditingController _messageController = TextEditingController();

  late final SupportRoleConfig _config;
  late final SupportRepositoryAdapter _repository;
  late SupportTicketSummary _ticket;
  late String _selectedStatus;

  CancelToken? _detailsToken;
  CancelToken? _messagesToken;
  CancelToken? _sendToken;
  CancelToken? _statusToken;

  bool _loading = false;
  bool _sending = false;
  bool _updatingStatus = false;
  bool _hasChanges = false;

  String? _errorMessage;

  List<SupportTicketMessage> _messages = <SupportTicketMessage>[];
  PickedFilePayload? _attachment;
  String _selectedComposerTab = 'Conversation';

  @override
  void initState() {
    super.initState();
    _config = _configFor(widget._role);
    _repository = SupportRepositoryFactory.forRole(widget._role);
    _ticket = widget._ticket;
    _selectedStatus = _normalizeStatusLabel(_ticket.status);
    _loadTicketData();
  }

  @override
  void dispose() {
    _detailsToken?.cancel('SupportTicketDetailsScreen disposed');
    _messagesToken?.cancel('SupportTicketDetailsScreen disposed');
    _sendToken?.cancel('SupportTicketDetailsScreen disposed');
    _statusToken?.cancel('SupportTicketDetailsScreen disposed');
    _messageController.dispose();
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

  String _pickFirstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  String _normalizeStatusLabel(String raw) {
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    if (value.isEmpty) return 'Open';
    if (value.contains('close')) return 'Closed';
    if (value.contains('answer') || value.contains('resolve'))
      return 'Answered';
    if (value.contains('hold')) return 'Hold';
    if (value.contains('process') ||
        value.contains('progress') ||
        value.contains('pending')) {
      return 'In Process';
    }
    if (value.contains('open') || value.contains('new')) return 'Open';
    return raw.trim();
  }

  String _statusToApi(String display) {
    final normalized = _normalizeStatusLabel(display).toLowerCase();
    if (normalized == 'open') return 'OPEN';
    if (normalized == 'in process') return 'IN_PROGRESS';
    if (normalized == 'closed') return 'CLOSED';
    if (normalized == 'answered') return 'ANSWERED';
    if (normalized == 'hold') return 'HOLD';
    return normalized.toUpperCase().replaceAll(' ', '_');
  }

  void _showInfo(String message) {
    if (!mounted) return;
    OpenVtsFeedback.info(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    OpenVtsFeedback.success(context, message);
  }

  void _showError(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
  }

  List<String> get _statusOptions {
    final base = switch (_config.role) {
      SupportRole.admin => <String>['Open', 'In Process', 'Answered', 'Closed'],
      SupportRole.user => <String>[],
      SupportRole.superadmin => <String>['Open', 'In Process', 'Closed'],
    };
    if (!base.contains(_selectedStatus)) {
      base.insert(0, _selectedStatus);
    }
    return base;
  }

  SupportTicketSummary _mergeTicket(
    SupportTicketSummary current,
    Map<String, dynamic> raw,
  ) {
    final mergedRaw = <String, dynamic>{...current.raw, ...raw};

    final id = _pickFirstNonEmpty(raw, const <String>['id', '_id', 'ticketId']);
    final subject = _pickFirstNonEmpty(raw, const <String>['subject', 'title']);
    final status = _pickFirstNonEmpty(raw, const <String>['status', 'state']);
    final owner = _pickFirstNonEmpty(raw, const <String>[
      'ownerName',
      'owner',
      'userName',
      'name',
    ]);
    final description = _pickFirstNonEmpty(raw, const <String>[
      'description',
      'message',
      'snippet',
    ]);
    final category = _pickFirstNonEmpty(raw, const <String>['category']);
    final priority = _pickFirstNonEmpty(raw, const <String>['priority']);
    final ticketNo = _pickFirstNonEmpty(raw, const <String>[
      'ticketNumber',
      'ticketNo',
      'code',
    ]);
    final created = _pickFirstNonEmpty(raw, const <String>[
      'createdAt',
      'created_at',
      'created',
    ]);
    final updated = _pickFirstNonEmpty(raw, const <String>[
      'updatedAt',
      'updated_at',
      'updated',
    ]);

    return SupportTicketSummary(
      id: id.isNotEmpty ? id : current.id,
      subject: subject.isNotEmpty ? subject : current.subject,
      status: status.isNotEmpty
          ? _normalizeStatusLabel(status)
          : current.status,
      ownerName: owner.isNotEmpty ? owner : current.ownerName,
      description: description.isNotEmpty ? description : current.description,
      category: category.isNotEmpty ? category : current.category,
      priority: priority.isNotEmpty ? priority : current.priority,
      ticketNumber: ticketNo.isNotEmpty ? ticketNo : current.ticketNumber,
      createdAt: created.isNotEmpty ? created : current.createdAt,
      updatedAt: updated.isNotEmpty ? updated : current.updatedAt,
      raw: mergedRaw,
    );
  }

  Future<void> _loadTicketData() async {
    _detailsToken?.cancel('Reload ticket details');
    _messagesToken?.cancel('Reload ticket messages');
    final detailsToken = CancelToken();
    final messagesToken = CancelToken();
    _detailsToken = detailsToken;
    _messagesToken = messagesToken;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final detailsResult = await _repository.getTicketDetails(
      _ticket.id,
      scope: widget._scope,
      cancelToken: detailsToken,
    );

    if (detailsToken.isCancelled || !mounted) return;

    detailsResult.when(
      success: (raw) {
        _ticket = _mergeTicket(_ticket, raw);
        _selectedStatus = _normalizeStatusLabel(_ticket.status);
      },
      failure: (error) {
        _errorMessage = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load ticket details.";
      },
    );

    final messagesResult = await _repository.getTicketMessages(
      _ticket.id,
      scope: widget._scope,
      cancelToken: messagesToken,
    );

    if (messagesToken.isCancelled || !mounted) return;

    messagesResult.when(
      success: (items) {
        _messages = items;
      },
      failure: (error) {
        _messages = <SupportTicketMessage>[];
        _errorMessage ??=
            error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load ticket messages.";
      },
    );

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _reloadMessages() async {
    _messagesToken?.cancel('Reload ticket messages');
    final token = CancelToken();
    _messagesToken = token;

    final result = await _repository.getTicketMessages(
      _ticket.id,
      scope: widget._scope,
      cancelToken: token,
    );

    if (token.isCancelled || !mounted) return;

    result.when(
      success: (items) {
        setState(() => _messages = items);
      },
      failure: (_) {},
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _attachment == null) return;

    _sendToken?.cancel('Send ticket message');
    final token = CancelToken();
    _sendToken = token;

    if (!mounted) return;
    setState(() => _sending = true);

    final result = await _repository.sendMessage(
      SupportSendMessageDraft(
        ticketId: _ticket.id,
        message: text,
        internal:
            _config.permissions.canSendInternalNotes &&
            _selectedComposerTab == 'Internal Note',
        attachment: _attachment,
      ),
      scope: widget._scope,
      cancelToken: token,
    );

    if (token.isCancelled || !mounted) return;

    result.when(
      success: (_) {
        setState(() {
          _sending = false;
          _hasChanges = true;
          _attachment = null;
        });
        _messageController.clear();
        _reloadMessages();
      },
      failure: (error) {
        setState(() => _sending = false);
        final message = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't send message.";
        _showError(message);
      },
    );
  }

  Future<void> _updateStatus() async {
    if (!_config.permissions.canUpdateStatus || _updatingStatus) return;

    final current = _normalizeStatusLabel(_ticket.status);
    if (_normalizeStatusLabel(_selectedStatus) == current) return;

    _statusToken?.cancel('Update ticket status');
    final token = CancelToken();
    _statusToken = token;

    if (!mounted) return;
    setState(() => _updatingStatus = true);

    final result = await _repository.updateStatus(
      _ticket.id,
      _statusToApi(_selectedStatus),
      scope: widget._scope,
      cancelToken: token,
    );

    if (token.isCancelled || !mounted) return;

    result.when(
      success: (_) {
        setState(() {
          _updatingStatus = false;
          _hasChanges = true;
          _ticket = SupportTicketSummary(
            id: _ticket.id,
            subject: _ticket.subject,
            status: _selectedStatus,
            ownerName: _ticket.ownerName,
            description: _ticket.description,
            category: _ticket.category,
            priority: _ticket.priority,
            ticketNumber: _ticket.ticketNumber,
            createdAt: _ticket.createdAt,
            updatedAt: _ticket.updatedAt,
            raw: <String, dynamic>{..._ticket.raw, 'status': _selectedStatus},
          );
        });
        _showSuccess('Status updated.');
      },
      failure: (error) {
        setState(() => _updatingStatus = false);
        final message = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't update status.";
        _showError(message);
      },
    );
  }

  Future<void> _pickAttachment() async {
    final file = await pickSingleFilePayload();
    if (file == null || !mounted) return;
    setState(() => _attachment = file);
  }

  Future<void> _openAttachment(SupportTicketMessage message) async {
    final raw = message.attachmentUrl.trim();
    if (raw.isEmpty) {
      _showInfo('Attachment URL not available.');
      return;
    }

    final resolvedUrl = _repository.resolveAttachmentUrl(raw);
    final uri = Uri.tryParse(resolvedUrl);
    if (uri == null) {
      _showError('Invalid attachment URL.');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showError("Couldn't open attachment.");
    }
  }

  Widget _buildRoleAppBar() {
    switch (_config.role) {
      case SupportRole.admin:
        return AdminHomeAppBar(
          title: 'Ticket Details',
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context, _hasChanges),
        );
      case SupportRole.user:
        return UserHomeAppBar(
          title: 'Ticket Details',
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context, _hasChanges),
        );
      case SupportRole.superadmin:
        return SuperAdminHomeAppBar(
          title: 'Ticket Details',
          leadingIcon: Icons.support_agent_outlined,
          onClose: () => Navigator.pop(context, _hasChanges),
        );
    }
  }

  List<SupportTicketMessage> get _visibleMessages {
    if (_config.permissions.canSendInternalNotes &&
        _selectedComposerTab == 'Internal Note') {
      return _messages.where((message) => message.isInternal).toList();
    }
    return _messages.where((message) => !message.isInternal).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final topPadding = MediaQuery.of(context).padding.top;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _ticket.subject.isEmpty
                                      ? 'Support Ticket'
                                      : _ticket.subject,
                                  style: AppFonts.roboto(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _ticket.ticketNumber.isEmpty
                                      ? _ticket.id
                                      : _ticket.ticketNumber,
                                  style: AppFonts.roboto(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.62),
                                  ),
                                ),
                                if (_ticket.ownerName.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _ticket.ownerName,
                                    style: AppFonts.roboto(
                                      fontSize: 12,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.62,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          TicketStatusChip(status: _ticket.status),
                        ],
                      ),
                      if (_ticket.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _ticket.description,
                          style: AppFonts.roboto(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                      if (_config.permissions.canUpdateStatus) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Ticket Status',
                                ),
                                items: _statusOptions
                                    .map(
                                      (item) => DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _updatingStatus
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() => _selectedStatus = value);
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _updatingStatus ? null : _updateStatus,
                              icon: _updatingStatus
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Update'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (_config.permissions.canSendInternalNotes)
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Conversation'),
                              selected: _selectedComposerTab == 'Conversation',
                              onSelected: (_) {
                                setState(
                                  () => _selectedComposerTab = 'Conversation',
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Internal Note'),
                              selected: _selectedComposerTab == 'Internal Note',
                              onSelected: (_) {
                                setState(
                                  () => _selectedComposerTab = 'Internal Note',
                                );
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_errorMessage != null && _messages.isEmpty)
                        TicketEmptyState(
                          message: _errorMessage!,
                          action: FilledButton.icon(
                            onPressed: _loadTicketData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        )
                      else
                        Container(
                          height: 360,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: TicketMessageList(
                            messages: _visibleMessages,
                            onAttachmentTap: _openAttachment,
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (_config.permissions.canAttachFiles) ...[
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _sending ? null : _pickAttachment,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Attach file'),
                            ),
                            const SizedBox(width: 8),
                            if (_attachment != null)
                              Expanded(
                                child: Text(
                                  _attachment!.filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.roboto(
                                    fontSize: 12,
                                    color: cs.onSurface.withValues(alpha: 0.72),
                                  ),
                                ),
                              ),
                            if (_attachment != null)
                              IconButton(
                                onPressed: _sending
                                    ? null
                                    : () => setState(() => _attachment = null),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      TicketMessageInput(
                        controller: _messageController,
                        sending: _sending,
                        enabled: !_loading,
                        hintText:
                            _config.permissions.canSendInternalNotes &&
                                _selectedComposerTab == 'Internal Note'
                            ? 'Type internal note...'
                            : 'Type your reply...',
                        onSend: _sendMessage,
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
