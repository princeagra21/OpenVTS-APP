// screens/support/support_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/ticket_message_item.dart';
import 'package:fleet_stack/core/models/ticket_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Data Models for Ticket and Message ---

class Ticket {
  final String title;
  final String id;
  final String name;
  final String owner;
  final String status;
  final String desc;
  final String created;
  final String updated;
  final List<Message> messages;

  const Ticket({
    required this.title,
    required this.id,
    required this.name,
    required this.owner,
    required this.status,
    required this.desc,
    required this.created,
    required this.updated,
    required this.messages,
  });
}

class Message {
  final String sender;
  final String content;
  final String timestamp;
  final bool isInternalNote;

  const Message({
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isInternalNote = false,
  });
}

// --- Status Color Helper ---

Color _statusColor(String status, ColorScheme colorScheme) {
  switch (_normalizeTicketStatus(status)) {
    case "Open":
      return colorScheme.primary;
    case "In Process":
      return Colors.orange;
    case "Answered":
      return Colors.green;
    case "Hold":
      return Colors.purple;
    case "Closed":
      return colorScheme.error;
    default:
      return colorScheme.onSurfaceVariant;
  }
}

String _normalizeTicketStatus(String raw) {
  final status = raw.trim();
  final s = status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
  if (s.isEmpty) return 'Open';
  if (s.contains('close')) return 'Closed';
  if (s.contains('answer') || s.contains('resolve')) return 'Answered';
  if (s.contains('hold')) return 'Hold';
  if (s.contains('process') ||
      s.contains('progress') ||
      s.contains('pending')) {
    return 'In Process';
  }
  if (s.contains('open') || s.contains('new')) return 'Open';
  return status;
}

// --- Support Screen State and Widgets ---

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Ticket> _tickets = <Ticket>[];
  bool _loadingTickets = false;
  bool _ticketsErrorShown = false;
  CancelToken? _ticketsCancelToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _ticketsCancelToken?.cancel('SupportScreen disposed');
    super.dispose();
  }

  Ticket _mapTicketItem(TicketListItem t) {
    final id = t.id.isNotEmpty
        ? t.id
        : (t.ticketNumber.isNotEmpty ? t.ticketNumber : '—');
    final title = t.subject.isNotEmpty ? t.subject : '—';
    final name = t.ownerName.isNotEmpty
        ? t.ownerName
        : (t.userName.isNotEmpty ? t.userName : '—');
    final status = _normalizeTicketStatus(t.status);
    final created = t.createdAt.isNotEmpty ? t.createdAt : '';
    final updated = '';
    final desc = t.snippet.isNotEmpty
        ? t.snippet
        : (t.priority.isNotEmpty ? 'Priority: ${t.priority}' : '');

    return Ticket(
      title: title,
      id: id,
      name: name,
      owner: name,
      status: status,
      desc: desc,
      created: created,
      updated: updated,
      messages: const <Message>[],
    );
  }

  Future<void> _loadTickets() async {
    _ticketsCancelToken?.cancel('Reload tickets');
    final token = CancelToken();
    _ticketsCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingTickets = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getTickets(
        page: 1,
        limit: 50,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          if (!mounted) return;
          final mapped = items.map(_mapTicketItem).toList();
          setState(() {
            _loadingTickets = false;
            _ticketsErrorShown = false;
            _tickets = mapped;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingTickets = false);
          if (_ticketsErrorShown) return;
          _ticketsErrorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view tickets.'
              : "Couldn't load tickets.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTickets = false);
      if (_ticketsErrorShown) return;
      _ticketsErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load tickets.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    final showListSkeleton = _loadingTickets && _tickets.isEmpty;
    final showNoData = !_loadingTickets && _tickets.isEmpty;

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
            // INBOX TITLE
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Inbox",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (_loadingTickets)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (showListSkeleton)
              const AppShimmer(width: 96, height: 14, radius: 8)
            else
              Text(
                "${_tickets.length} tickets",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  color: colorScheme.onSurface.withOpacity(0.54),
                ),
                overflow: TextOverflow.ellipsis, // adds the "..."
                maxLines: 1, // ensures single-line text
              ),

            const SizedBox(height: 16),

            // TICKET CARDS LIST
            if (showListSkeleton)
              ...List<Widget>.generate(4, (_) => const _TicketCardShimmer())
            else if (showNoData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  "No tickets found.",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ..._tickets.map(
                (ticket) => _TicketCard(
                  ticket: ticket,
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailsScreen(ticket: ticket),
                      ),
                    );
                    if (changed == true && mounted) {
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

// --- Ticket Details Screen ---

class TicketDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  String selectedLocalTab = "Conversation";
  late String selectedDropdownStatus;
  final TextEditingController messageController = TextEditingController();
  final List<TicketMessageItem> _messages = <TicketMessageItem>[];
  final List<String> statusOptions = [
    "Closed",
    "Open",
    "In Process",
    "Answered",
    "Hold",
  ];
  bool _sending = false;
  bool _updatingStatus = false;
  bool _loadingDetails = false;
  bool _sendErrorShown = false;
  bool _statusErrorShown = false;
  bool _detailsErrorShown = false;
  bool _hasChanges = false;
  CancelToken? _sendToken;
  CancelToken? _statusToken;
  CancelToken? _detailsToken;
  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    selectedDropdownStatus = _normalizeTicketStatus(widget.ticket.status);
    if (!statusOptions.contains(selectedDropdownStatus)) {
      statusOptions.insert(0, selectedDropdownStatus);
    }
    _messages.addAll(
      widget.ticket.messages.map(
        (m) => TicketMessageItem(<String, dynamic>{
          'senderName': m.sender,
          'message': m.content,
          'createdAt': m.timestamp,
          'isInternal': m.isInternalNote,
        }),
      ),
    );
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _sendToken?.cancel('TicketDetailsScreen disposed');
    _statusToken?.cancel('TicketDetailsScreen disposed');
    _detailsToken?.cancel('TicketDetailsScreen disposed');
    messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    _detailsToken?.cancel('Reload ticket details');
    final token = CancelToken();
    _detailsToken = token;

    if (!mounted) return;
    setState(() => _loadingDetails = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.getTicketDetails(
        widget.ticket.id,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (payload) {
          final normalizedStatus = _normalizeTicketStatus(
            (payload['status'] ?? '').toString(),
          );

          final nextMessages = <TicketMessageItem>[];
          final rawMessages = payload['messages'];
          if (rawMessages is List) {
            for (final raw in rawMessages) {
              if (raw is! Map) continue;
              final m = Map<String, dynamic>.from(raw.cast());
              final sender = m['sender'];
              if (sender is Map && m['senderName'] == null) {
                final senderMap = Map<String, dynamic>.from(sender.cast());
                final name = senderMap['name']?.toString();
                if (name != null && name.trim().isNotEmpty) {
                  m['senderName'] = name.trim();
                }
                m['user'] = senderMap;
              }
              if (m['isInternal'] == null && m['type'] is String) {
                final t = (m['type'] as String).toLowerCase();
                m['isInternal'] = t == 'internal' || t == 'note';
              }
              nextMessages.add(TicketMessageItem(m));
            }
          }

          setState(() {
            _loadingDetails = false;
            _detailsErrorShown = false;
            if (normalizedStatus.isNotEmpty) {
              if (!statusOptions.contains(normalizedStatus)) {
                statusOptions.insert(0, normalizedStatus);
              }
              selectedDropdownStatus = normalizedStatus;
            }
            _messages
              ..clear()
              ..addAll(nextMessages);
          });
        },
        failure: (err) {
          setState(() => _loadingDetails = false);
          if (_detailsErrorShown) return;
          _detailsErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view ticket details.'
              : "Couldn't load ticket details.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDetails = false);
      if (_detailsErrorShown) return;
      _detailsErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load ticket details.")),
      );
    }
  }

  String _wireStatus(String status) {
    switch (_normalizeTicketStatus(status)) {
      case 'Open':
        return 'OPEN';
      case 'In Process':
        return 'IN_PROGRESS';
      case 'Answered':
        return 'ANSWERED';
      case 'Hold':
        return 'HOLD';
      case 'Closed':
        return 'CLOSED';
      default:
        return status.trim().toUpperCase().replaceAll(' ', '_');
    }
  }

  Future<void> _sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _sending) return;

    _sendToken?.cancel('New send message');
    final token = CancelToken();
    _sendToken = token;

    if (!mounted) return;
    setState(() {
      _sending = true;
      _sendErrorShown = false;
    });

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final internal = selectedLocalTab == 'Internal Note';
      final res = await _repo!.sendTicketMessage(
        widget.ticket.id,
        text,
        internal: internal,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (item) {
          final now = DateTime.now();
          final local = TicketMessageItem(<String, dynamic>{
            'senderName': 'You',
            'message': text,
            'createdAt':
                '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            'isInternal': internal,
          });
          setState(() {
            _sending = false;
            _messages.add(item ?? local);
            messageController.clear();
            _hasChanges = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Message sent')));
        },
        failure: (err) {
          setState(() => _sending = false);
          if (_sendErrorShown) return;
          _sendErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to send message.'
              : "Couldn't send message.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      if (_sendErrorShown) return;
      _sendErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't send message.")));
    }
  }

  Future<void> _changeStatus(String nextStatus) async {
    final previous = selectedDropdownStatus;
    if (_updatingStatus || nextStatus == previous) return;

    _statusToken?.cancel('New status update');
    final token = CancelToken();
    _statusToken = token;

    if (!mounted) return;
    setState(() {
      selectedDropdownStatus = nextStatus;
      _updatingStatus = true;
      _statusErrorShown = false;
    });

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.updateTicketStatus(
        widget.ticket.id,
        _wireStatus(nextStatus),
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (_) {
          setState(() => _updatingStatus = false);
          _hasChanges = true;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Status updated')));
        },
        failure: (err) {
          setState(() {
            _updatingStatus = false;
            selectedDropdownStatus = previous;
          });
          if (_statusErrorShown) return;
          _statusErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to update status.'
              : "Couldn't update status.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _updatingStatus = false;
        selectedDropdownStatus = previous;
      });
      if (_statusErrorShown) return;
      _statusErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't update status.")));
    }
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

    // Filter messages based on the selected tab
    final filteredMessages =
        (selectedLocalTab == "Conversation"
                ? _messages.where((m) => !m.isInternal)
                : _messages.where((m) => m.isInternal))
            .map(
              (m) => Message(
                sender: m.senderName.isNotEmpty ? m.senderName : 'Unknown',
                content: m.message,
                timestamp: m.createdAt,
                isInternalNote: m.isInternal,
              ),
            )
            .toList();
    final showDetailsSkeleton = _loadingDetails && _messages.isEmpty;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.ticket.title,
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
                    onTap: () => Navigator.pop(context, _hasChanges),
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
                "${widget.ticket.id} • ${widget.ticket.name}",
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
                      // Status Dropdown
                      if (showDetailsSkeleton)
                        const AppShimmer(
                          width: double.infinity,
                          height: 52,
                          radius: 16,
                        )
                      else
                        DropdownButtonFormField<String>(
                          decoration: _dropdownDecoration(context),
                          value: statusOptions.contains(selectedDropdownStatus)
                              ? selectedDropdownStatus
                              : null,
                          items: statusOptions
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                          onChanged: _updatingStatus
                              ? null
                              : (value) {
                                  if (value != null) _changeStatus(value);
                                },
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

                      // Owner info
                      if (showDetailsSkeleton)
                        const AppShimmer(width: 180, height: 14, radius: 8)
                      else
                        Text(
                          "Ticket owner: ${widget.ticket.owner}",
                          style: GoogleFonts.inter(
                            fontSize: labelSize - 2,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Created/Updated info
                      if (showDetailsSkeleton)
                        const AppShimmer(
                          width: double.infinity,
                          height: 14,
                          radius: 8,
                        )
                      else
                        Text(
                          "Created: ${widget.ticket.created} • Updated: ${widget.ticket.updated}",
                          style: GoogleFonts.inter(
                            fontSize: labelSize - 2,
                            color: colorScheme.onSurface.withOpacity(0.54),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Tabs
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

                      // Messages
                      if (showDetailsSkeleton)
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.4,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: ListView(
                            physics: const NeverScrollableScrollPhysics(),
                            children: const [
                              AppShimmer(
                                width: 180,
                                height: 12,
                                radius: 8,
                                margin: EdgeInsets.only(bottom: 10),
                              ),
                              AppShimmer(
                                width: double.infinity,
                                height: 14,
                                radius: 8,
                                margin: EdgeInsets.only(bottom: 6),
                              ),
                              AppShimmer(
                                width: 230,
                                height: 14,
                                radius: 8,
                                margin: EdgeInsets.only(bottom: 16),
                              ),
                              AppShimmer(
                                width: 150,
                                height: 12,
                                radius: 8,
                                margin: EdgeInsets.only(bottom: 10),
                              ),
                              AppShimmer(
                                width: double.infinity,
                                height: 14,
                                radius: 8,
                                margin: EdgeInsets.only(bottom: 6),
                              ),
                              AppShimmer(width: 260, height: 14, radius: 8),
                            ],
                          ),
                        )
                      else
                        _MessagesContainer(
                          messages: filteredMessages,
                          selectedTab: selectedLocalTab,
                        ),

                      const SizedBox(height: 16),

                      // Message Input
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

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
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
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: _sending
                                        ? CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  colorScheme.onPrimary,
                                                ),
                                          )
                                        : Icon(
                                            Icons.send,
                                            color: colorScheme.onPrimary,
                                            size: 18,
                                          ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
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

// --- New Widget for Messages Display ---

class _MessagesContainer extends StatelessWidget {
  final List<Message> messages;
  final String selectedTab;

  const _MessagesContainer({required this.messages, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double messageHeight = MediaQuery.of(context).size.height * 0.4;

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
        reverse: false, // default
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
                    Text(
                      message.sender,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: message.isInternalNote
                            ? Colors.purple
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
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

// LOCAL TAB (Unchanged)
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
  const _TicketCardShimmer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
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
          AppShimmer(width: 220, height: 16, radius: 8),
          SizedBox(height: 8),
          AppShimmer(width: 170, height: 14, radius: 8),
          SizedBox(height: 8),
          AppShimmer(width: 78, height: 14, radius: 8),
          SizedBox(height: 12),
          AppShimmer(width: double.infinity, height: 14, radius: 8),
        ],
      ),
    );
  }
}

// TICKET CARD (Modified to accept a Ticket object and handle selection)
class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final Color statusColor = _statusColor(ticket.status, colorScheme);

    return InkWell(
      onTap: onTap, // Set the selected ticket on tap
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
              ticket.title,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${ticket.id} • ${ticket.name}",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ticket.status,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ticket.desc,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width),
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
