import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_message_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_support_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/utils/file_picker_helper.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'new_ticket_screen.dart';

String _formatDateTimeDisplay(String raw) {
  if (raw.trim().isEmpty) return '—';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} $month, $hour12:$minute $suffix';
  } catch (_) {
    return '—';
  }
}

String _normalizeTicketStatus(String raw) {
  final status = raw.trim();
  final s = status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
  if (s.isEmpty) return 'Open';
  if (s.contains('close')) return 'Closed';
  if (s.contains('answer') || s.contains('resolve')) return 'Answered';
  if (s.contains('hold')) return 'Hold';
  if (s.contains('process') || s.contains('progress') || s.contains('pending')) {
    return 'In Process';
  }
  if (s.contains('open') || s.contains('new')) return 'Open';
  return status;
}

double _supportScale(double width) {
  if (width >= 900) return 1;
  if (width < 360) return -1;
  return 0;
}

String _titleCase(String value) {
  final v = value.trim();
  if (v.isEmpty) return '';
  return v
      .toLowerCase()
      .split(RegExp(r'\\s+|_+|-+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase() + p.substring(1))
      .join(' ');
}

Color _statusColor(String status, ColorScheme colorScheme) {
  switch (_normalizeTicketStatus(status)) {
    case 'Open':
      return colorScheme.primary;
    case 'In Process':
      return Colors.orange;
    case 'Answered':
      return Colors.green;
    case 'Hold':
      return Colors.purple;
    case 'Closed':
      return colorScheme.error;
    default:
      return colorScheme.onSurfaceVariant;
  }
}

IconData _statusIcon(String status) {
  final s = _normalizeTicketStatus(status);
  if (s == 'Closed') return Icons.check_circle_outline;
  if (s == 'Answered') return Icons.mark_email_read_outlined;
  if (s == 'Hold') return Icons.pause_circle_outline;
  if (s == 'In Process') return Icons.schedule_outlined;
  return Icons.radio_button_unchecked;
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // User support endpoints:
  // - GET /user/tickets
  // - POST /user/tickets
  // - GET /user/tickets/:id
  // - POST /user/tickets/:id
  List<AdminTicketListItem>? _tickets;
  bool _loading = false;
  bool _loadErrorShown = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';

  CancelToken? _loadToken;

  ApiClient? _apiClient;
  UserSupportRepository? _repo;

  UserSupportRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserSupportRepository(api: _apiClient!);
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

    final result = await _repoOrCreate().getTickets(cancelToken: token);

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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = width >= 900 ? 1 : (width < 360 ? -1 : 0);
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double topPadding = MediaQuery.of(context).padding.top;

    final double sectionTitleFs = 18 + scale;
    final double buttonFs = 14 + scale;
    final double searchFs = 14 + scale;
    final double secondaryFs = 12 + scale;

    final tickets = _tickets ?? const <AdminTicketListItem>[];
    final showListSkeleton = _loading && tickets.isEmpty;
    final query = _searchController.text.trim().toLowerCase();
    final filteredTickets = tickets.where((t) {
      final matchesSearch = query.isEmpty ||
          t.subject.toLowerCase().contains(query) ||
          t.ticketNumber.toLowerCase().contains(query) ||
          t.ownerName.toLowerCase().contains(query) ||
          t.id.toLowerCase().contains(query);
      final matchesTab = _selectedTab == 'All' ||
          AdminTicketListItem.normalizeStatus(t.statusLabel) ==
              AdminTicketListItem.normalizeStatus(_selectedTab);
      return matchesSearch && matchesTab;
    }).toList();

    return Scaffold(
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
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support Inbox',
                              style: GoogleFonts.roboto(
                                fontSize: sectionTitleFs,
                                height: 24 / 18,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (showListSkeleton)
                              const AppShimmer(
                                width: 96,
                                height: 14,
                                radius: 8,
                              )
                            else
                              Text(
                                '${tickets.length} tickets',
                                style: GoogleFonts.roboto(
                                  fontSize: secondaryFs,
                                  height: 16 / 12,
                                  color: colorScheme.onSurface.withOpacity(0.54),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NewTicketScreen(),
                              ),
                            ).then((value) {
                              if (value == true) _loadTickets();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: AdaptiveUtils.getIconSize(width),
                                  color: colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'New Ticket',
                                  style: GoogleFonts.roboto(
                                    fontSize: buttonFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: hp * 3.8,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.roboto(
                          fontSize: searchFs,
                          height: 20 / 14,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search tickets',
                          hintStyle: GoogleFonts.roboto(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: searchFs - 2,
                            height: 16 / 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: AdaptiveUtils.getIconSize(width) + 2,
                            color: colorScheme.onSurface,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: hp,
                            vertical: hp,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _tabPill(
                            context,
                            label: 'All',
                            selected: _selectedTab == 'All',
                            onTap: () => setState(() => _selectedTab = 'All'),
                          ),
                          const SizedBox(width: 8),
                          _tabPill(
                            context,
                            label: 'Open',
                            selected: _selectedTab == 'Open',
                            onTap: () => setState(() => _selectedTab = 'Open'),
                          ),
                          const SizedBox(width: 8),
                          _tabPill(
                            context,
                            label: 'In Process',
                            selected: _selectedTab == 'In Process',
                            onTap: () =>
                                setState(() => _selectedTab = 'In Process'),
                          ),
                          const SizedBox(width: 8),
                          _tabPill(
                            context,
                            label: 'Closed',
                            selected: _selectedTab == 'Closed',
                            onTap: () => setState(() => _selectedTab = 'Closed'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (showListSkeleton)
                      ...List<Widget>.generate(
                        4,
                        (_) => const _TicketCardShimmer(),
                      )
                    else if (filteredTickets.isEmpty)
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
                          'No tickets found',
                          style: GoogleFonts.roboto(
                            fontSize: secondaryFs,
                            height: 16 / 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      ...filteredTickets.map(
                        (ticket) => _TicketCard(
                          ticket: ticket,
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TicketDetailsScreen(ticket: ticket),
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
            ),
          ),
          Positioned(
            left: hp,
            right: hp,
            top: 0,
            child: UserHomeAppBar(
              title: 'Support',
              leadingIcon: Icons.support_agent_outlined,
              onClose: () => context.go('/user/home'),
            ),
          ),
        ],
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
  final messageController = TextEditingController();
  final List<String> localTabs = ['Conversation'];
  String selectedLocalTab = 'Conversation';

  Map<String, dynamic> _ticketDetail = const <String, dynamic>{};
  List<AdminTicketMessageItem> _messages = const <AdminTicketMessageItem>[];
  String _myUserIdentifier = '';

  bool _loadingMessages = false;
  bool _sending = false;
  bool _updatingStatus = false;
  bool _hasChanges = false;
  PickedFilePayload? _attachment;

  bool _messagesErrorShown = false;
  bool _sendErrorShown = false;

  CancelToken? _messagesToken;
  CancelToken? _sendToken;
  CancelToken? _statusToken;

  ApiClient? _apiClient;
  UserSupportRepository? _repo;

  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _fullscreenChatScrollController = ScrollController();

  final List<String> statusOptions = ['Open', 'In Process', 'Answered', 'Closed'];
  String selectedDropdownStatus = 'Open';

  UserSupportRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserSupportRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException && err.message.toLowerCase() == 'request cancelled';
  }

  @override
  void initState() {
    super.initState();
    selectedDropdownStatus = _toDisplayStatus(widget.ticket.status);
    _myUserIdentifier = (widget.ticket.raw['fromUserId'] ??
            widget.ticket.raw['userId'] ??
            widget.ticket.raw['createdById'] ??
            '')
        .toString()
        .trim();
    _resolveMyUserIdFromToken();
    _loadMessages();
  }

  Future<void> _resolveMyUserIdFromToken() async {
    if (_myUserIdentifier.isNotEmpty) return;
    final token = await TokenStorage.defaultInstance().readAccessToken();
    if (!mounted || token == null || token.trim().isEmpty) return;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return;
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(payload);
      if (map is! Map) return;
      final sub = (map['sub'] ?? '').toString().trim();
      if (sub.isEmpty || !mounted) return;
      setState(() => _myUserIdentifier = sub);
    } catch (_) {
      // Ignore token parse failures; fallback logic remains active.
    }
  }

  @override
  void dispose() {
    _messagesToken?.cancel('TicketDetailsScreen disposed');
    _sendToken?.cancel('TicketDetailsScreen disposed');
    _statusToken?.cancel('TicketDetailsScreen disposed');
    _chatScrollController.dispose();
    _fullscreenChatScrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  DateTime? _parseMessageDate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    final iso = DateTime.tryParse(v);
    if (iso != null) return iso.toLocal();
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(v);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }

  String _formatMessageTime(AdminTicketMessageItem msg) {
    final dt = _parseMessageDate(msg.createdAt);
    if (dt == null) return msg.createdAt.trim().isEmpty ? '—' : msg.createdAt;
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  String _dateLabelForMessage(AdminTicketMessageItem msg) {
    final dt = _parseMessageDate(msg.createdAt);
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  void _scrollToLatest([ScrollController? controller]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = controller ?? _chatScrollController;
      if (!c.hasClients) return;
      c.animateTo(
        c.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Color _chatAccentBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Color.alphaBlend(
      cs.primary.withValues(alpha: 0.18),
      cs.surface,
    );
  }

  Color _chatAccentForeground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.onSurface;
  }

  Widget _buildChatSurface({
    required BuildContext context,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.03),
      cs.surfaceContainerLowest,
    );
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        painter: _ChatPatternPainter(
          color: cs.onSurface.withValues(alpha: 0.035),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      ),
    );
  }

  Widget _buildReplyComposer({
    required BuildContext context,
    required ColorScheme colorScheme,
    required double bodyFs,
    required double secondaryFs,
    VoidCallback? onChangedForParent,
  }) {
    final accentBg = _chatAccentBackground(context);
    final accentFg = _chatAccentForeground(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _pickAttachment();
                      onChangedForParent?.call();
                    },
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.attach_file,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: messageController,
                          minLines: 1,
                          maxLines: 3,
                          style: GoogleFonts.roboto(
                            fontSize: bodyFs,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Type a message…',
                            hintStyle: GoogleFonts.roboto(
                              fontSize: bodyFs,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                        if (_attachment != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _attachment!.filename,
                              style: GoogleFonts.roboto(
                                fontSize: secondaryFs - 1,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending
                        ? null
                        : () async {
                            onChangedForParent?.call();
                            await _sendMessage();
                            onChangedForParent?.call();
                          },
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentBg,
                      ),
                      alignment: Alignment.center,
                      child: _sending
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentFg,
                              ),
                            )
                          : Icon(Icons.send, size: 18, color: accentFg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList({
    required List<AdminTicketMessageItem> messages,
    required ColorScheme colorScheme,
    required double bodyFs,
    required double secondaryFs,
    required ScrollController controller,
  }) {
    final baseBg = colorScheme.surface;
    final baseText = colorScheme.onSurface;
    final mutedText = colorScheme.onSurfaceVariant;

    if (messages.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '—',
          style: GoogleFonts.roboto(
            fontSize: secondaryFs,
            fontWeight: FontWeight.w500,
            color: mutedText,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      padding: EdgeInsets.zero,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final bubbleMinWidth = (screenWidth * 0.24).clamp(86.0, 120.0);
        final bubbleMaxWidth = screenWidth * 0.74;
        final accentBg = _chatAccentBackground(context);
        final accentFg = _chatAccentForeground(context);
        final msg = messages[index];
        final isOutgoing = _isOutgoingMessage(msg);
        final prev = index > 0 ? messages[index - 1] : null;
        final currentDate = _dateLabelForMessage(msg);
        final prevDate = prev == null ? '' : _dateLabelForMessage(prev);
        final showDateSeparator = currentDate.isNotEmpty && currentDate != prevDate;

        return Column(
          children: [
            if (showDateSeparator)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      currentDate,
                      style: GoogleFonts.roboto(
                        fontSize: secondaryFs - 1,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Align(
                alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: bubbleMinWidth,
                    maxWidth: bubbleMaxWidth,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isOutgoing ? accentBg : baseBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOutgoing
                            ? accentBg.withValues(alpha: 0.9)
                            : colorScheme.onSurface.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.message,
                          textAlign: isOutgoing ? TextAlign.right : TextAlign.left,
                          style: GoogleFonts.roboto(
                            fontSize: bodyFs - 0.5,
                            fontWeight: FontWeight.w500,
                            color: isOutgoing ? accentFg : baseText,
                          ),
                        ),
                        if (_messageAttachmentName(msg).trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _downloadAttachment(msg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isOutgoing
                                    ? accentFg.withValues(alpha: 0.12)
                                    : colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outline.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 14,
                                    color: isOutgoing ? accentFg : mutedText,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _messageAttachmentName(msg),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: secondaryFs - 1,
                                        fontWeight: FontWeight.w500,
                                        color: isOutgoing ? accentFg : mutedText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatMessageTime(msg),
                            style: GoogleFonts.roboto(
                              fontSize: secondaryFs - 2.5,
                              fontWeight: FontWeight.w500,
                              color: isOutgoing ? accentFg.withValues(alpha: 0.85) : mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAttachment() async {
    final file = await pickSingleFilePayload();
    if (!mounted) return;
    if (file == null) return;
    if (file.bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max file size is 5MB.')),
      );
      return;
    }
    setState(() => _attachment = file);
  }

  Future<Directory> _resolveDownloadDir() async {
    if (Platform.isAndroid) {
      final androidDir = Directory('/storage/emulated/0/Download');
      if (await androidDir.exists()) return androidDir;
    }
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.trim().isNotEmpty) {
        final dl = Directory('$home${Platform.pathSeparator}Downloads');
        if (await dl.exists()) return dl;
      }
    }
    return Directory.systemTemp;
  }

  String _safeAttachmentName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'attachment';
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _messageAttachmentName(AdminTicketMessageItem msg) {
    final direct = msg.raw['attachmentName']?.toString().trim() ??
        msg.raw['fileName']?.toString().trim() ??
        '';
    if (direct.isNotEmpty) return direct;
    final attachments = msg.raw['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        final name = first['originalName']?.toString().trim() ??
            first['storedName']?.toString().trim() ??
            first['name']?.toString().trim() ??
            '';
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }

  String _messageAttachmentUrl(AdminTicketMessageItem msg) {
    final direct = msg.raw['attachmentUrl']?.toString().trim() ??
        msg.raw['filePath']?.toString().trim() ??
        '';
    if (direct.isNotEmpty) return direct;
    final attachments = msg.raw['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        final path = first['filePath']?.toString().trim() ??
            first['url']?.toString().trim() ??
            '';
        if (path.isNotEmpty) return path;
      }
    }
    return '';
  }

  String _messageSenderId(AdminTicketMessageItem msg) {
    return (msg.raw['senderId'] ??
            msg.raw['fromUserId'] ??
            msg.raw['createdById'] ??
            '')
        .toString()
        .trim();
  }

  bool _isOutgoingMessage(AdminTicketMessageItem msg) {
    final senderId = _messageSenderId(msg);
    final senderType = (msg.raw['senderType'] ??
            msg.raw['fromType'] ??
            msg.raw['createdByType'] ??
            msg.raw['userType'] ??
            msg.raw['loginType'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    if (senderType.contains('admin')) return false;
    if (senderType.contains('user')) return true;
    if (_myUserIdentifier.isNotEmpty && senderId.isNotEmpty) {
      return senderId == _myUserIdentifier;
    }
    return msg.senderName.trim().toLowerCase() == 'you';
  }

  Future<void> _downloadAttachment(AdminTicketMessageItem msg) async {
    final rawPath = _messageAttachmentUrl(msg);
    if (rawPath.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment URL not available.')),
      );
      return;
    }

    try {
      _apiClient ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      final dir = await _resolveDownloadDir();
      final fileName = _safeAttachmentName(_messageAttachmentName(msg));
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await _apiClient!.dio.download(rawPath, file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't download attachment.")),
      );
    }
  }

  Future<void> _openFullscreenChat() async {
    final colorScheme = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final scale = _supportScale(w);
    final bodyFs = 14 + scale;
    final secondaryFs = 12 + scale;

    final fromUserMap = (_ticketDetail['fromUser'] is Map)
        ? Map<String, dynamic>.from((_ticketDetail['fromUser'] as Map).cast())
        : const <String, dynamic>{};
    final String fromName = ((fromUserMap['name'] ?? '').toString().trim().isNotEmpty)
        ? fromUserMap['name'].toString().trim()
        : (_ticketDetail['fromUserName'] ?? _ticketDetail['fromName'] ?? '').toString().trim().isNotEmpty
            ? (_ticketDetail['fromUserName'] ?? _ticketDetail['fromName']).toString().trim()
            : widget.ticket.ownerName.isNotEmpty
                ? widget.ticket.ownerName
                : '—';
    final String fromDate = _formatDateTimeDisplay(
      (_ticketDetail['updatedAt']?.toString().trim().isNotEmpty == true)
          ? _ticketDetail['updatedAt'].toString()
          : widget.ticket.updatedAt.isNotEmpty
              ? widget.ticket.updatedAt
              : widget.ticket.createdAt,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final filteredMessages = (selectedLocalTab == 'Conversation'
                      ? _messages.where((m) => !m.isInternal)
                      : _messages.where((m) => m.isInternal))
                  .toList();
              _scrollToLatest(_fullscreenChatScrollController);

              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
                                child: Text(
                                  fromName.isNotEmpty ? fromName[0].toUpperCase() : '—',
                                  style: GoogleFonts.roboto(
                                    fontSize: bodyFs - 1,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fromName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: bodyFs,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fromDate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: secondaryFs,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Tooltip(
                                message: 'Collapse content',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.surface,
                                      border: Border.all(
                                        color: colorScheme.outline.withValues(alpha: 0.22),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.close_fullscreen,
                                      size: 18,
                                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _buildChatSurface(
                              context: context,
                              child: _buildChatList(
                                messages: filteredMessages,
                                colorScheme: colorScheme,
                                bodyFs: bodyFs,
                                secondaryFs: secondaryFs,
                                controller: _fullscreenChatScrollController,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildReplyComposer(
                            context: context,
                            colorScheme: colorScheme,
                            bodyFs: bodyFs,
                            secondaryFs: secondaryFs,
                            onChangedForParent: () {
                              if (mounted) {
                                setModalState(() {});
                                _scrollToLatest(_fullscreenChatScrollController);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadMessages() async {
    _messagesToken?.cancel('Reload ticket messages');
    final token = CancelToken();
    _messagesToken = token;

    if (!mounted) return;
    setState(() => _loadingMessages = true);

    final detailResult = await _repoOrCreate().getTicketDetails(
      widget.ticket.id.isNotEmpty ? widget.ticket.id : widget.ticket.ticketNumber,
      cancelToken: token,
    );

    if (!mounted) return;

    detailResult.when(
      success: (detail) {
        final detailMap = _coerceDetailMap(detail.raw);
        final items = detail.messages;
        setState(() {
          _ticketDetail = detailMap;
          _messages = items;
          if (_myUserIdentifier.isEmpty) {
            final fromUser = detailMap['fromUser'];
            if (fromUser is Map) {
              _myUserIdentifier = (fromUser['uid'] ??
                      fromUser['id'] ??
                      fromUser['userId'] ??
                      '')
                  .toString()
                  .trim();
            }
            if (_myUserIdentifier.isEmpty) {
              _myUserIdentifier = (detailMap['fromUserId'] ??
                      detailMap['userId'] ??
                      detailMap['createdById'] ??
                      '')
                  .toString()
                  .trim();
            }
          }
          final detailStatus = detailMap['status']?.toString() ?? '';
          if (detailStatus.trim().isNotEmpty) {
            selectedDropdownStatus = _toDisplayStatus(detailStatus);
          }
          _loadingMessages = false;
          _messagesErrorShown = false;
        });
        _scrollToLatest();
      },
      failure: (err) {
        setState(() {
          _messages = const <AdminTicketMessageItem>[];
          _loadingMessages = false;
        });
        if (_isCancelled(err) || _messagesErrorShown) return;
        _messagesErrorShown = true;
        final message = err is ApiException ? err.message : "Couldn't load conversation.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Map<String, dynamic> _coerceDetailMap(Map<String, dynamic> source) {
    Map<String, dynamic> map = source;
    Map<String, dynamic> asMap(Object? value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value.cast());
      return const <String, dynamic>{};
    }
    bool looksLikeTicket(Map<String, dynamic> m) {
      return m.containsKey('id') || m.containsKey('ticketNo') || m.containsKey('title') || m.containsKey('status') || m.containsKey('messages');
    }
    for (var i = 0; i < 4; i++) {
      final nested = asMap(map['data']);
      if (nested.isEmpty) break;
      map = nested;
      if (looksLikeTicket(map)) break;
    }
    return map;
  }

  String _toDisplayStatus(String raw) {
    final normalized = AdminTicketListItem.normalizeStatus(raw);
    switch (normalized) {
      case 'closed': return 'Closed';
      case 'open': return 'Open';
      case 'in_process':
      case 'in_progress':
      case 'resolved':
      case 'answered':
      case 'hold':
      case 'on_hold':
        return 'In Process';
      default: return 'Open';
    }
  }

  Future<void> _updateStatus(String? value) async {
    if (value == null || _updatingStatus) return;
    setState(() => selectedDropdownStatus = value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status update is not available for user tickets.')),
    );
  }

  Future<void> _sendMessage() async {
    if (_sending) return;
    final text = messageController.text.trim();
    if (text.isEmpty && _attachment == null) return;

    setState(() {
      _sending = true;
      _sendErrorShown = false;
    });

    _sendToken?.cancel('Replace send message');
    final token = CancelToken();
    _sendToken = token;
    final result = await _repoOrCreate().sendTicketMessage(
      widget.ticket.id.isNotEmpty ? widget.ticket.id : widget.ticket.ticketNumber,
      text,
      attachment: _attachment,
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (item) {
        setState(() {
          _sending = false;
          _hasChanges = true;
          _attachment = null;
        });
        messageController.clear();
        _loadMessages();
      },
      failure: (err) {
        setState(() => _sending = false);
        if (_isCancelled(err) || _sendErrorShown) return;
        _sendErrorShown = true;
        final message = err is ApiException ? err.message : "Couldn't send message.";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  Future<String?> _showStatusSheet() async {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Status',
                        style: GoogleFonts.roboto(fontSize: fontSize, fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 32, width: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close, size: 18, color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...statusOptions.map((status) {
                  final selected = status == selectedDropdownStatus;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(ctx, status),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? colorScheme.primary.withValues(alpha: 0.45) : colorScheme.onSurface.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              status,
                              style: GoogleFonts.roboto(fontSize: fontSize - 1, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            ),
                          ),
                          if (selected) Icon(Icons.check_rounded, size: 18, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double scale = _supportScale(w);
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double ticketTitleFs = 14 + scale;
    final double bodyFs = 14 + scale;
    final double secondaryFs = 12 + scale;
    final double metaFs = 11 + scale;

    final fromUserMap = (_ticketDetail['fromUser'] is Map)
        ? Map<String, dynamic>.from((_ticketDetail['fromUser'] as Map).cast())
        : const <String, dynamic>{};
    final String fromName = ((fromUserMap['name'] ?? '').toString().trim().isNotEmpty)
        ? fromUserMap['name'].toString().trim()
        : (_ticketDetail['fromUserName'] ?? _ticketDetail['fromName'] ?? '').toString().trim().isNotEmpty
            ? (_ticketDetail['fromUserName'] ?? _ticketDetail['fromName']).toString().trim()
            : widget.ticket.ownerName.isNotEmpty
                ? widget.ticket.ownerName
                : '—';
    final String fromDate = _formatDateTimeDisplay(
      (_ticketDetail['updatedAt']?.toString().trim().isNotEmpty == true)
          ? _ticketDetail['updatedAt'].toString()
          : widget.ticket.updatedAt.isNotEmpty
              ? widget.ticket.updatedAt
              : widget.ticket.createdAt,
    );
    final filteredMessages = _messages.toList();
    final bool showDetailsSkeleton = _loadingMessages && _messages.isEmpty;

    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding, topPadding + AppUtils.appBarHeightCustom + 28, padding, padding),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  (_ticketDetail['title']?.toString().trim().isNotEmpty == true)
                                      ? _ticketDetail['title'].toString().trim()
                                      : widget.ticket.subject.isNotEmpty
                                          ? widget.ticket.subject
                                          : 'Support Ticket',
                                  style: GoogleFonts.roboto(
                                    fontSize: ticketTitleFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: _statusColor(selectedDropdownStatus, colorScheme).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_statusIcon(selectedDropdownStatus), size: AdaptiveUtils.getIconSize(w) - 4, color: _statusColor(selectedDropdownStatus, colorScheme)),
                                    const SizedBox(width: 6),
                                    Text(
                                      selectedDropdownStatus,
                                      style: GoogleFonts.roboto(
                                        fontSize: metaFs,
                                        height: 14 / 11,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(selectedDropdownStatus, colorScheme),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              widget.ticket.ticketNumber.isNotEmpty ? widget.ticket.ticketNumber : widget.ticket.id,
                              if (_titleCase((_ticketDetail['category']?.toString().trim().isNotEmpty == true) ? _ticketDetail['category'].toString() : widget.ticket.category).isNotEmpty)
                                _titleCase((_ticketDetail['category']?.toString().trim().isNotEmpty == true) ? _ticketDetail['category'].toString() : widget.ticket.category),
                              if (_titleCase((_ticketDetail['priority']?.toString().trim().isNotEmpty == true) ? _ticketDetail['priority'].toString() : widget.ticket.priority).isNotEmpty)
                                '${_titleCase((_ticketDetail['priority']?.toString().trim().isNotEmpty == true) ? _ticketDetail['priority'].toString() : widget.ticket.priority)} Priority',
                            ].join(' · '),
                            style: GoogleFonts.roboto(
                              fontSize: metaFs,
                              height: 14 / 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          if (showDetailsSkeleton)
                            const AppShimmer(width: double.infinity, height: 52, radius: 16)
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                selectedDropdownStatus,
                                style: GoogleFonts.roboto(
                                  fontSize: secondaryFs,
                                  height: 16 / 12,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
                                child: Text(
                                  fromName.isNotEmpty ? fromName[0].toUpperCase() : '—',
                                  style: GoogleFonts.roboto(
                                    fontSize: bodyFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fromName,
                                      style: GoogleFonts.roboto(
                                        fontSize: bodyFs,
                                        height: 20 / 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fromDate,
                                      style: GoogleFonts.roboto(
                                        fontSize: secondaryFs,
                                        height: 16 / 12,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Tooltip(
                                message: 'Full screen chat',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => _openFullscreenChat(),
                                  child: Container(
                                    height: 38, width: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorScheme.surface,
                                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.22)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.open_in_full_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 260,
                            child: _buildChatSurface(
                              context: context,
                              child: _buildChatList(
                                messages: filteredMessages,
                                colorScheme: colorScheme,
                                bodyFs: bodyFs,
                                secondaryFs: secondaryFs,
                                controller: _chatScrollController,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildReplyComposer(
                            context: context,
                            colorScheme: colorScheme,
                            bodyFs: bodyFs,
                            secondaryFs: secondaryFs,
                            onChangedForParent: () { if (mounted) setState(() {}); },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
              child: UserHomeAppBar(
                title: widget.ticket.ticketNumber.isNotEmpty ? widget.ticket.ticketNumber : widget.ticket.id,
                leadingIcon: Icons.confirmation_number_outlined,
                onClose: () => Navigator.pop(context, _hasChanges),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPatternPainter extends CustomPainter {
  final Color color;
  const _ChatPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    const step = 34.0;
    for (double y = 10; y < size.height; y += step) {
      for (double x = 10; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 3.2, paint);
        canvas.drawLine(Offset(x + 7, y + 7), Offset(x + 12, y + 12), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatPatternPainter oldDelegate) => oldDelegate.color != color;
}

Widget _tabPill(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
  final cs = Theme.of(context).colorScheme;
  final width = MediaQuery.of(context).size.width;
  final double scale = _supportScale(width);
  final double tabFs = 14 + scale;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? cs.onSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: tabFs,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          color: selected ? cs.surface : cs.onSurface,
        ),
      ),
    ),
  );
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

class _TicketCard extends StatelessWidget {
  final AdminTicketListItem? ticket;
  final VoidCallback? onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  String _safe(String value) {
    final out = value.trim();
    if (out.isEmpty || out.toLowerCase() == 'null') return '—';
    return out;
  }

  String _formatShortDate(String raw) {
    if (raw.trim().isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      return '$d/$m/$y';
    } catch (_) {
      return '—';
    }
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
          style: GoogleFonts.roboto(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    final status = _safe(ticket?.statusLabel ?? '');
    final statusColor = _statusColor(status, colorScheme);
    final category = _safe(ticket?.category ?? '');
    final priority = _safe(ticket?.priority ?? '');
    final createdText = _formatShortDate(_safe(ticket?.createdAt ?? ''));

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
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _safe(
                      ticket?.ticketNumber.isNotEmpty == true
                          ? ticket!.ticketNumber
                          : ticket?.id ?? '',
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: AdaptiveUtils.getIconSize(width) - 4,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: GoogleFonts.roboto(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (category != '—' || priority != '—' || createdText != '—')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (category != '—') _titleCase(category),
                        if (priority != '—')
                          '${_titleCase(priority)} Priority',
                      ].join(' · '),
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        height: 16 / 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (createdText != '—')
                    Text(
                      createdText,
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        height: 16 / 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Ticket',
                        style: GoogleFonts.roboto(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                          height: 16 / 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: AdaptiveUtils.getIconSize(width),
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
