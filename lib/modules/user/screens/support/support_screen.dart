import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_message_item.dart';
import 'package:fleet_stack/core/models/user_ticket_details.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_support_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color _statusColor(String status, ColorScheme colorScheme) {
  switch (AdminTicketListItem.normalizeStatus(status)) {
    case "open":
      return colorScheme.primary;
    case "in_process":
    case "in_progress":
      return Colors.orange;
    case "resolved":
    case "answered":
      return Colors.green;
    case "hold":
      return Colors.purple;
    case "closed":
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
  // FleetStack-API-Reference.md confirmed:
  // - GET  /user/tickets
  // - POST /user/tickets
  // - GET  /user/tickets/:id
  // - POST /user/tickets/:id
  //
  // Live backend mismatch found:
  // - Postman create body uses `subject`
  // - Live backend requires `title` + `category`
  // This screen currently wires list + conversation + reply only.
  ApiClient? _apiClient;
  UserSupportRepository? _repo;
  CancelToken? _token;

  List<AdminTicketListItem> _tickets = <AdminTicketListItem>[];
  bool _loading = false;
  bool _errorShown = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _token?.cancel('User support disposed');
    super.dispose();
  }

  UserSupportRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserSupportRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object error) {
    return error is ApiException &&
        error.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadTickets() async {
    _token?.cancel('Reload user tickets');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getTickets(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (items) {
        setState(() {
          _tickets = items;
          _loading = false;
          _errorShown = false;
        });
      },
      failure: (error) {
        setState(() => _loading = false);
        if (_isCancelled(error) || _errorShown) return;
        _errorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load tickets.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Support",
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
              "Inbox",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${_tickets.length} tickets",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width),
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            if (_loading)
              ...List.generate(
                3,
                (_) => _TicketShimmerCard(horizontalPadding: hp),
              )
            else if (_tickets.isEmpty)
              _EmptyTicketCard(horizontalPadding: hp)
            else
              ..._tickets.map(
                (ticket) => _TicketCard(
                  ticket: ticket,
                  onTap: () async {
                    final refreshed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailsScreen(ticket: ticket),
                      ),
                    );
                    if (refreshed == true) {
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
  final TextEditingController messageController = TextEditingController();
  final List<String> statusOptions = [
    "Closed",
    "Open",
    "In Process",
    "Answered",
    "Hold",
  ];

  ApiClient? _apiClient;
  UserSupportRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _sendToken;

  String selectedLocalTab = "Conversation";
  String? selectedDropdownStatus;
  UserTicketDetails? _ticket;
  List<AdminTicketMessageItem> _messages = <AdminTicketMessageItem>[];
  bool _loading = false;
  bool _sending = false;
  bool _loadErrorShown = false;
  bool _sendErrorShown = false;
  bool _aiUnavailableShown = false;

  @override
  void initState() {
    super.initState();
    selectedDropdownStatus = _dropdownStatusValue(widget.ticket.status);
    _loadDetails();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Ticket details disposed');
    _sendToken?.cancel('Ticket details disposed');
    messageController.dispose();
    super.dispose();
  }

  UserSupportRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserSupportRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object error) {
    return error is ApiException &&
        error.message.toLowerCase() == 'request cancelled';
  }

  String _safe(String? value, {String fallback = '—'}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _formatDateTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '—';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String? _dropdownStatusValue(String? rawStatus) {
    final normalized = UserTicketDetails.normalizeStatus(rawStatus);
    switch (normalized) {
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
      case 'closed':
        return 'Closed';
      default:
        final direct = (rawStatus ?? '').trim();
        return statusOptions.contains(direct) ? direct : null;
    }
  }

  Future<void> _loadDetails() async {
    _loadToken?.cancel('Reload ticket details');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getTicketDetails(
      widget.ticket.id,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (details) {
        setState(() {
          _ticket = details;
          _messages = details.messages;
          selectedDropdownStatus = _dropdownStatusValue(details.status);
          _loading = false;
          _loadErrorShown = false;
        });
      },
      failure: (error) {
        setState(() => _loading = false);
        if (_isCancelled(error) || _loadErrorShown) return;
        _loadErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't load ticket.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    _sendToken?.cancel('Restart send ticket message');
    final token = CancelToken();
    _sendToken = token;

    if (!mounted) return;
    setState(() {
      _sending = true;
      _sendErrorShown = false;
    });

    final result = await _repoOrCreate().sendTicketMessage(
      widget.ticket.id,
      text,
      cancelToken: token,
    );
    if (!mounted || token.isCancelled) return;

    result.when(
      success: (message) {
        final appended =
            message ??
            AdminTicketMessageItem(<String, dynamic>{
              'message': text,
              'createdAt': DateTime.now().toIso8601String(),
              'senderName': 'You',
            });
        setState(() {
          _sending = false;
          _messages = [..._messages, appended];
        });
        messageController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message sent')));
      },
      failure: (error) {
        setState(() => _sending = false);
        if (_isCancelled(error) || _sendErrorShown) return;
        _sendErrorShown = true;
        final msg = error is ApiException && error.message.trim().isNotEmpty
            ? error.message
            : "Couldn't send message.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  void _showAiUnavailable() {
    if (!kDebugMode || _aiUnavailableShown) return;
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
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
    final details = _ticket;

    final filteredMessages = selectedLocalTab == "Conversation"
        ? _messages.where((m) => !m.isInternal).toList()
        : _messages.where((m) => m.isInternal).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                      _safe(details?.title, fallback: widget.ticket.subject),
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
                    onTap: () => Navigator.pop(context, _messages.isNotEmpty),
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
                "${_safe(details?.ticketNo, fallback: widget.ticket.ticketNumber.isEmpty ? widget.ticket.id : widget.ticket.ticketNumber)} • ${_safe(widget.ticket.ownerName, fallback: 'You')}",
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                          selectedDropdownStatus ?? 'ticket-status-empty',
                        ),
                        decoration: _dropdownDecoration(context),
                        initialValue: selectedDropdownStatus,
                        disabledHint: Text(
                          'Status unavailable',
                          style: GoogleFonts.inter(
                            fontSize: labelSize,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        items: statusOptions
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: null,
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
                        "Ticket owner: ${_safe(widget.ticket.ownerName, fallback: 'You')}",
                        style: GoogleFonts.inter(
                          fontSize: labelSize - 2,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Created: ${_formatDateTime(details?.createdAt ?? widget.ticket.createdAt)} • Updated: ${_formatDateTime(details?.updatedAt ?? widget.ticket.updatedAt)}",
                        style: GoogleFonts.inter(
                          fontSize: labelSize - 2,
                          color: colorScheme.onSurface.withOpacity(0.54),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 12,
                        children: ["Conversation", "Internal Note"].map((tab) {
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
                        loading: _loading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: messageController,
                        maxLines: 5,
                        style: GoogleFonts.inter(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: "Write your message...",
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
                          InkWell(
                            onTap: _showAiUnavailable,
                            borderRadius: BorderRadius.circular(12),
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
                                    "Generate Answer",
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
                          InkWell(
                            onTap: _sending ? null : _sendMessage,
                            borderRadius: BorderRadius.circular(12),
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
                                      ? const AppShimmer(
                                          width: 36,
                                          height: 14,
                                          radius: 7,
                                        )
                                      : Text(
                                          "Send",
                                          style: GoogleFonts.inter(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ],
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

  String _formatDateTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '—';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double messageHeight = MediaQuery.of(context).size.height * 0.4;

    if (loading) {
      return Container(
        width: double.infinity,
        height: messageHeight,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(width: 140, height: 12, radius: 6),
                  SizedBox(height: 8),
                  AppShimmer(width: double.infinity, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 220, height: 14, radius: 7),
                ],
              ),
            ),
          ),
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
          "No ${selectedTab.toLowerCase()} messages for this ticket.",
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
                        message.senderName.isEmpty ? 'You' : message.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: message.isInternal
                              ? Colors.purple
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(message.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.message,
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

class _TicketCard extends StatelessWidget {
  final AdminTicketListItem ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final Color statusColor = _statusColor(ticket.status, colorScheme);
    final summary = ticket.description.isNotEmpty
        ? ticket.description
        : [
            if (ticket.category.isNotEmpty) ticket.category,
            if (ticket.priority.isNotEmpty) ticket.priority,
          ].join(' • ');

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
              ticket.subject.isEmpty ? 'Untitled ticket' : ticket.subject,
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
              "${ticket.ticketNumber.isEmpty ? ticket.id : ticket.ticketNumber} • ${ticket.ownerName.isEmpty ? 'You' : ticket.ownerName}",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              ticket.statusLabel,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              summary.isEmpty ? '—' : summary,
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

class _TicketShimmerCard extends StatelessWidget {
  final double horizontalPadding;

  const _TicketShimmerCard({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(width: 220, height: 18, radius: 8),
          SizedBox(height: 8),
          AppShimmer(width: 180, height: 14, radius: 7),
          SizedBox(height: 8),
          AppShimmer(width: 72, height: 14, radius: 7),
          SizedBox(height: 10),
          AppShimmer(width: double.infinity, height: 14, radius: 7),
          SizedBox(height: 8),
          AppShimmer(width: 240, height: 14, radius: 7),
        ],
      ),
    );
  }
}

class _EmptyTicketCard extends StatelessWidget {
  final double horizontalPadding;

  const _EmptyTicketCard({required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No tickets found',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open a support ticket from the web console if you need help.',
            style: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
