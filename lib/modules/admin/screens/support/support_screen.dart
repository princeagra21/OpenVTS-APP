import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_message_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_support_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color _statusColor(String status, ColorScheme colorScheme) {
  final normalized = AdminTicketListItem.normalizeStatus(status);
  switch (normalized) {
    case 'open':
      return colorScheme.primary;
    case 'in_process':
    case 'in_progress':
      return Colors.orange;
    case 'resolved':
    case 'answered':
      return Colors.green;
    case 'hold':
    case 'on_hold':
      return Colors.purple;
    case 'closed':
      return colorScheme.error;
    default:
      return colorScheme.onSurfaceVariant;
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/tickets
  // - GET /admin/tickets/:id
  // - POST /admin/tickets/:id/messages  (body keys: message)
  // - PATCH /admin/tickets/:id/status   (body keys: status)
  List<AdminTicketListItem>? _tickets;
  bool _loading = false;
  bool _loadErrorShown = false;

  CancelToken? _loadToken;

  ApiClient? _apiClient;
  AdminSupportRepository? _repo;

  AdminSupportRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminSupportRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTickets() async {
    _loadToken?.cancel('Reload tickets');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getTickets(
      limit: 100,
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _tickets = items;
          _loading = false;
          _loadErrorShown = false;
        });
      },
      failure: (err) {
        setState(() {
          _tickets = const <AdminTicketListItem>[];
          _loading = false;
        });
        if (_isCancelled(err)) return;
        final message = err is ApiException
            ? err.message
            : "Couldn't load tickets.";
        _showLoadErrorOnce(message);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _loadToken?.cancel('SupportScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final tickets = _tickets ?? const <AdminTicketListItem>[];

    return AppLayout(
      title: 'FLEET STACK',
      subtitle: 'Support',
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inbox',
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            _loading
                ? const AppShimmer(width: 92, height: 14, radius: 7)
                : Text(
                    '${tickets.length} tickets',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
            const SizedBox(height: 16),
            if (_loading)
              ...List.generate(3, (_) => _TicketCardShimmer(width: width))
            else if (tickets.isEmpty)
              const _TicketCard(ticket: null, onTap: null)
            else
              ...tickets.map(
                (ticket) => _TicketCard(
                  ticket: ticket,
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailsScreen(ticket: ticket),
                      ),
                    );
                    if (changed == true) {
                      _loadTickets();
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TicketDetailsScreen extends StatefulWidget {
  final AdminTicketListItem ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  String selectedLocalTab = 'Conversation';
  late String selectedDropdownStatus;
  final TextEditingController messageController = TextEditingController();

  final List<String> statusOptions = const [
    'Closed',
    'Open',
    'In Process',
    'Answered',
    'Hold',
  ];

  List<AdminTicketMessageItem> _messages = const <AdminTicketMessageItem>[];

  bool _loadingMessages = false;
  bool _sending = false;
  bool _updatingStatus = false;

  bool _messagesErrorShown = false;
  bool _sendErrorShown = false;
  bool _statusErrorShown = false;
  bool _aiUnavailableShown = false;

  CancelToken? _messagesToken;
  CancelToken? _sendToken;
  CancelToken? _statusToken;

  ApiClient? _apiClient;
  AdminSupportRepository? _repo;

  AdminSupportRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminSupportRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  @override
  void initState() {
    super.initState();
    selectedDropdownStatus = _toDisplayStatus(widget.ticket.status);
    _loadMessages();
  }

  @override
  void dispose() {
    _messagesToken?.cancel('TicketDetailsScreen disposed');
    _sendToken?.cancel('TicketDetailsScreen disposed');
    _statusToken?.cancel('TicketDetailsScreen disposed');
    messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    _messagesToken?.cancel('Reload ticket messages');
    final token = CancelToken();
    _messagesToken = token;

    if (!mounted) return;
    setState(() => _loadingMessages = true);

    final result = await _repoOrCreate().getTicketMessages(
      widget.ticket.id,
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _messages = items;
          _loadingMessages = false;
          _messagesErrorShown = false;
        });
      },
      failure: (err) {
        setState(() {
          _messages = const <AdminTicketMessageItem>[];
          _loadingMessages = false;
        });
        if (_isCancelled(err) || _messagesErrorShown) return;
        _messagesErrorShown = true;
        final message = err is ApiException
            ? err.message
            : "Couldn't load conversation.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  String _toDisplayStatus(String raw) {
    final normalized = AdminTicketListItem.normalizeStatus(raw);
    switch (normalized) {
      case 'closed':
        return 'Closed';
      case 'open':
        return 'Open';
      case 'in_process':
      case 'in_progress':
        return 'In Process';
      case 'resolved':
      case 'answered':
        return 'Answered';
      case 'hold':
      case 'on_hold':
        return 'Hold';
      default:
        return 'Open';
    }
  }

  String _toApiStatus(String display) {
    final d = display.trim().toLowerCase();
    if (d == 'closed') return 'CLOSED';
    if (d == 'open') return 'OPEN';
    if (d == 'in process') return 'IN_PROGRESS';
    if (d == 'answered') return 'RESOLVED';
    if (d == 'hold') return 'HOLD';
    return display.toUpperCase().replaceAll(' ', '_');
  }

  Future<void> _updateStatus(String? value) async {
    if (value == null || _updatingStatus) return;
    final previous = selectedDropdownStatus;

    setState(() {
      selectedDropdownStatus = value;
      _updatingStatus = true;
      _statusErrorShown = false;
    });

    _statusToken?.cancel('Replace status update');
    final token = CancelToken();
    _statusToken = token;

    final result = await _repoOrCreate().updateTicketStatus(
      widget.ticket.id,
      _toApiStatus(value),
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _updatingStatus = false);
      },
      failure: (err) {
        setState(() {
          selectedDropdownStatus = previous;
          _updatingStatus = false;
        });

        if (_isCancelled(err) || _statusErrorShown) return;
        _statusErrorShown = true;
        final message = err is ApiException
            ? err.message
            : "Couldn't update status.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    final text = messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message cannot be empty.')));
      return;
    }

    setState(() {
      _sending = true;
      _sendErrorShown = false;
    });

    _sendToken?.cancel('Replace send message');
    final token = CancelToken();
    _sendToken = token;
    final isInternal = selectedLocalTab == 'Internal Note';

    final result = await _repoOrCreate().sendTicketMessage(
      widget.ticket.id,
      text,
      internal: isInternal,
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (item) {
        final msg =
            item ??
            AdminTicketMessageItem(<String, dynamic>{
              'senderName': 'You',
              'message': text,
              'createdAt': DateTime.now().toIso8601String(),
              'isInternal': isInternal,
            });

        setState(() {
          _messages = <AdminTicketMessageItem>[..._messages, msg];
          _sending = false;
        });
        messageController.clear();
      },
      failure: (err) {
        setState(() => _sending = false);
        if (_isCancelled(err) || _sendErrorShown) return;
        _sendErrorShown = true;
        final message = err is ApiException
            ? err.message
            : "Couldn't send message.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  void _showAiUnavailableOnce() {
    if (!kDebugMode || _aiUnavailableShown || !mounted) return;
    _aiUnavailableShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI answer API not available yet')),
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    final filteredMessages = selectedLocalTab == 'Conversation'
        ? _messages.where((m) => !m.isInternal).toList()
        : _messages.where((m) => m.isInternal).toList();

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.ticket.subject.isEmpty
                          ? '—'
                          : widget.ticket.subject,
                      style: GoogleFonts.inter(
                        fontSize: titleSize + 2,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.ticket.ticketNumber.isEmpty ? widget.ticket.id : widget.ticket.ticketNumber} • ${widget.ticket.ownerName.isEmpty ? '—' : widget.ticket.ownerName}',
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: _dropdownDecoration(context),
                        value: selectedDropdownStatus,
                        items: statusOptions
                            .map(
                              (status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: _updatingStatus ? null : _updateStatus,
                        style: GoogleFonts.inter(
                          fontSize: labelSize,
                          color: colorScheme.onSurface,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ticket owner: ${widget.ticket.ownerName.isEmpty ? '—' : widget.ticket.ownerName}',
                        style: GoogleFonts.inter(
                          fontSize: labelSize - 2,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Created: ${widget.ticket.createdAt.isEmpty ? '—' : widget.ticket.createdAt} • Updated: ${widget.ticket.updatedAt.isEmpty ? '—' : widget.ticket.updatedAt}',
                        style: GoogleFonts.inter(
                          fontSize: labelSize - 2,
                          color: colorScheme.onSurface.withOpacity(0.54),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 12,
                        children: ['Conversation', 'Internal Note'].map((tab) {
                          return _LocalTab(
                            label: tab,
                            selected: tab == selectedLocalTab,
                            onTap: () => setState(() => selectedLocalTab = tab),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _MessagesContainer(
                        messages: filteredMessages,
                        selectedTab: selectedLocalTab,
                        loading: _loadingMessages,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: messageController,
                        maxLines: 5,
                        style: GoogleFonts.inter(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Write your message...',
                          hintStyle: GoogleFonts.inter(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _showAiUnavailableOnce,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.smart_toy,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Generate Answer',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _sending ? null : _sendMessage,
                            child: Opacity(
                              opacity: _sending ? 0.7 : 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.send,
                                      color: colorScheme.onPrimary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    _sending
                                        ? AppShimmer(
                                            width: 34,
                                            height: 12,
                                            radius: 6,
                                          )
                                        : Text(
                                            'Send',
                                            style: GoogleFonts.inter(
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesContainer extends StatelessWidget {
  final List<AdminTicketMessageItem> messages;
  final String selectedTab;
  final bool loading;

  const _MessagesContainer({
    required this.messages,
    required this.selectedTab,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double messageHeight = MediaQuery.of(context).size.height * 0.4;

    if (loading) {
      return Container(
        width: double.infinity,
        height: messageHeight,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: ListView(
          children: const [
            AppShimmer(width: 160, height: 12, radius: 6),
            SizedBox(height: 8),
            AppShimmer(width: double.infinity, height: 14, radius: 7),
            SizedBox(height: 14),
            AppShimmer(width: 130, height: 12, radius: 6),
            SizedBox(height: 8),
            AppShimmer(width: double.infinity, height: 14, radius: 7),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return Container(
        width: double.infinity,
        height: messageHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Text(
          'No ${selectedTab.toLowerCase()} messages for this ticket.',
          style: GoogleFonts.inter(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: messageHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.builder(
        reverse: false,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.senderName.isEmpty ? '—' : message.senderName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: message.isInternal
                              ? Colors.purple
                              : colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.createdAt.isEmpty ? '—' : message.createdAt,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.message.isEmpty ? '—' : message.message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LocalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocalTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final bool small = width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: small ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TicketCardShimmer extends StatelessWidget {
  final double width;

  const _TicketCardShimmer({required this.width});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(width: 220, height: 14, radius: 7),
          SizedBox(height: 8),
          AppShimmer(width: 180, height: 12, radius: 6),
          SizedBox(height: 8),
          AppShimmer(width: 90, height: 12, radius: 6),
          SizedBox(height: 10),
          AppShimmer(width: 260, height: 13, radius: 6),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final AdminTicketListItem? ticket;
  final VoidCallback? onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  String _safe(String value) {
    final out = value.trim();
    if (out.isEmpty || out.toLowerCase() == 'null') return '—';
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    if (ticket == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(hp),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Text(
          'No tickets found',
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final status = _safe(ticket?.statusLabel ?? '');
    final statusColor = _statusColor(status, colorScheme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(hp),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _safe(ticket?.subject ?? ''),
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${_safe(ticket?.ticketNumber.isNotEmpty == true ? ticket!.ticketNumber : ticket?.id ?? '')} • ${_safe(ticket?.ownerName ?? '')}',
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _safe(ticket?.description ?? ''),
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width),
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
