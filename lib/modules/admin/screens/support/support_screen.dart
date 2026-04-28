import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_ticket_message_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_support_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/utils/file_picker_helper.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/screens/support/new_ticket_screen.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

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
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/tickets
  // - GET /admin/tickets/:id
  // - POST /admin/tickets/:id/messages  (body keys: message)
  // - PATCH /admin/tickets/:id/status   (body keys: status)
  List<AdminTicketListItem>? _tickets;
  bool _loading = false;
  bool _loadErrorShown = false;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';

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
      rk: 1,
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
            child: AdminHomeAppBar(
              title: 'Support',
              leadingIcon: Icons.support_agent_outlined,
              onClose: () => context.go('/admin/home'),
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
  String selectedLocalTab = 'Conversation';
  late String selectedDropdownStatus;
  final TextEditingController messageController = TextEditingController();

  final List<String> statusOptions = const [
    'Open',
    'In Process',
    'Closed',
  ];

  List<AdminTicketMessageItem> _messages = const <AdminTicketMessageItem>[];
  Map<String, dynamic> _ticketDetail = const <String, dynamic>{};
  String _adminIdentifier = '';

  bool _loadingMessages = false;
  bool _sending = false;
  bool _updatingStatus = false;
  bool _hasChanges = false;
  PickedFilePayload? _attachment;

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
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
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
    final direct =
        msg.raw['attachmentName']?.toString().trim() ??
        msg.raw['fileName']?.toString().trim() ??
        '';
    if (direct.isNotEmpty) return direct;
    final attachments = msg.raw['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        final name =
            first['originalName']?.toString().trim() ??
            first['storedName']?.toString().trim() ??
            first['name']?.toString().trim() ??
            '';
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }

  String _messageAttachmentUrl(AdminTicketMessageItem msg) {
    final direct =
        msg.raw['attachmentUrl']?.toString().trim() ??
        msg.raw['filePath']?.toString().trim() ??
        '';
    if (direct.isNotEmpty) return direct;
    final attachments = msg.raw['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        final path =
            first['filePath']?.toString().trim() ??
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
    if (_adminIdentifier.isNotEmpty && senderId.isNotEmpty) {
      return senderId == _adminIdentifier;
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

  Future<void> _loadMessages() async {
    _messagesToken?.cancel('Reload ticket messages');
    final token = CancelToken();
    _messagesToken = token;

    if (!mounted) return;
    setState(() => _loadingMessages = true);

    final detailResult = await _repoOrCreate().getTicketDetail(
      widget.ticket.id.isNotEmpty ? widget.ticket.id : widget.ticket.ticketNumber,
      rk: 1,
      cancelToken: token,
    );

    if (!mounted) return;

    detailResult.when(
      success: (detail) {
        final detailMap = _coerceDetailMap(detail);
        final rawMessages = detailMap['messages'];
        final items = <AdminTicketMessageItem>[];
        if (rawMessages is List) {
          for (final item in rawMessages) {
            if (item is Map<String, dynamic>) {
              items.add(AdminTicketMessageItem(item));
            } else if (item is Map) {
              items.add(
                AdminTicketMessageItem(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
        }
        setState(() {
          _ticketDetail = detailMap;
          _messages = items;
          _adminIdentifier =
              (detailMap['adminUserId'] ?? detailMap['adminId'] ?? '')
                  .toString()
                  .trim();
          final detailStatus = detailMap['status']?.toString() ?? '';
          if (detailStatus.trim().isNotEmpty) {
            selectedDropdownStatus = _toDisplayStatus(detailStatus);
          }
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

  Map<String, dynamic> _coerceDetailMap(Map<String, dynamic> source) {
    Map<String, dynamic> map = source;

    Map<String, dynamic> asMap(Object? value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value.cast());
      return const <String, dynamic>{};
    }

    bool looksLikeTicket(Map<String, dynamic> m) {
      return m.containsKey('id') ||
          m.containsKey('ticketNo') ||
          m.containsKey('title') ||
          m.containsKey('status') ||
          m.containsKey('fromUser') ||
          m.containsKey('messages');
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
      case 'closed':
        return 'Closed';
      case 'open':
        return 'Open';
      case 'in_process':
      case 'in_progress':
      case 'resolved':
      case 'answered':
      case 'hold':
      case 'on_hold':
        return 'In Process';
      default:
        return 'Open';
    }
  }

  String _toApiStatus(String display) {
    final d = display.trim().toLowerCase();
    if (d == 'open') return 'OPEN';
    if (d == 'in process') return 'IN_PROGRESS';
    if (d == 'closed') return 'CLOSED';
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
      widget.ticket.id.isNotEmpty ? widget.ticket.id : widget.ticket.ticketNumber,
      _toApiStatus(value),
      rk: 1,
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() {
          _updatingStatus = false;
          _hasChanges = true;
        });
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
      widget.ticket.id.isNotEmpty ? widget.ticket.id : widget.ticket.ticketNumber,
      text,
      internal: isInternal,
      attachment: _attachment,
      rk: 1,
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (item) {
        final raw = <String, dynamic>{
          ...(item?.raw ?? const <String, dynamic>{}),
        };
        raw.putIfAbsent('senderName', () => 'You');
        raw.putIfAbsent('message', () => text);
        raw.putIfAbsent('createdAt', () => DateTime.now().toIso8601String());
        raw.putIfAbsent('isInternal', () => isInternal);
        if (_adminIdentifier.isNotEmpty) {
          raw.putIfAbsent('senderId', () => _adminIdentifier);
        }
        if (_attachment != null) {
          final hasAttachment =
              _messageAttachmentName(AdminTicketMessageItem(raw))
                  .trim()
                  .isNotEmpty;
          if (!hasAttachment) {
            raw['attachmentName'] = _attachment!.filename;
            raw['attachments'] = <Map<String, dynamic>>[
              <String, dynamic>{
                'originalName': _attachment!.filename,
                'filePath': _attachment!.filename,
              },
            ];
          }
        }
        final msg = AdminTicketMessageItem(raw);

        setState(() {
          _messages = <AdminTicketMessageItem>[..._messages, msg];
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

  Future<String?> _showStatusSheet() async {
    final colorScheme = Theme.of(context).colorScheme;
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                        style: GoogleFonts.roboto(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: colorScheme.primary,
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? colorScheme.primary.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary.withOpacity(0.45)
                              : colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              status,
                              style: GoogleFonts.roboto(
                                fontSize: fontSize - 1,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
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
    final raw = widget.ticket.raw;
    final fromUserMap = (_ticketDetail['fromUser'] is Map)
        ? Map<String, dynamic>.from((_ticketDetail['fromUser'] as Map).cast())
        : const <String, dynamic>{};
    final String fromName = ((fromUserMap['name'] ?? '')
                .toString()
                .trim()
                .isNotEmpty)
        ? fromUserMap['name'].toString().trim()
        : (_ticketDetail['fromUserName'] ?? _ticketDetail['fromName'] ?? '')
                .toString()
                .trim()
                .isNotEmpty
            ? (_ticketDetail['fromUserName'] ?? _ticketDetail['fromName'])
                .toString()
                .trim()
            : widget.ticket.ownerName.isNotEmpty
                ? widget.ticket.ownerName
                : '—';
    String fromEmail = '—';
    final rawEmail = (fromUserMap.isNotEmpty
            ? fromUserMap['email']
            : (_ticketDetail['fromUserEmail'] ??
                  _ticketDetail['email'] ??
                  raw['email']))
        ?.toString()
        .trim() ??
        '';
    if (rawEmail.isNotEmpty) {
      fromEmail = rawEmail;
    } else if (raw['fromUser'] is Map) {
      final email = (raw['fromUser'] as Map)['email']?.toString().trim() ?? '';
      if (email.isNotEmpty) fromEmail = email;
    }
    final String fromDate = _formatDateTimeDisplay(
      (_ticketDetail['updatedAt']?.toString().trim().isNotEmpty == true)
          ? _ticketDetail['updatedAt'].toString()
          : widget.ticket.updatedAt.isNotEmpty
              ? widget.ticket.updatedAt
              : widget.ticket.createdAt,
    );
    final filteredMessages =
        (selectedLocalTab == 'Conversation'
                ? _messages.where((m) => !m.isInternal)
                : _messages.where((m) => m.isInternal))
            .toList();
    final bool showDetailsSkeleton =
        _loadingMessages && _messages.isEmpty;

    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                topPadding + AppUtils.appBarHeightCustom + 28,
                padding,
                padding,
              ),
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
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _statusColor(
                                    selectedDropdownStatus,
                                    colorScheme,
                                  ).withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _statusIcon(selectedDropdownStatus),
                                    size: AdaptiveUtils.getIconSize(w) - 4,
                                    color: _statusColor(
                                      selectedDropdownStatus,
                                      colorScheme,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    selectedDropdownStatus,
                                    style: GoogleFonts.roboto(
                                      fontSize: metaFs,
                                      height: 14 / 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(
                                        selectedDropdownStatus,
                                        colorScheme,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(height: 6),
                        Text(
                          [
                            widget.ticket.ticketNumber.isNotEmpty
                                ? widget.ticket.ticketNumber
                                : widget.ticket.id,
                            if (_titleCase(
                                  (_ticketDetail['category']?.toString().trim().isNotEmpty ==
                                              true)
                                      ? _ticketDetail['category'].toString()
                                      : widget.ticket.category,
                                ).isNotEmpty)
                              _titleCase(
                                (_ticketDetail['category']?.toString().trim().isNotEmpty == true)
                                    ? _ticketDetail['category'].toString()
                                    : widget.ticket.category,
                              ),
                            if (_titleCase(
                                  (_ticketDetail['priority']?.toString().trim().isNotEmpty ==
                                              true)
                                      ? _ticketDetail['priority'].toString()
                                      : widget.ticket.priority,
                                ).isNotEmpty)
                              '${_titleCase(
                                (_ticketDetail['priority']?.toString().trim().isNotEmpty == true)
                                    ? _ticketDetail['priority'].toString()
                                    : widget.ticket.priority,
                              )} Priority',
                          ].join(' · '),
                          style: GoogleFonts.roboto(
                            fontSize: metaFs,
                            height: 14 / 11,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.onSurface.withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: GoogleFonts.roboto(
                                  fontSize: metaFs,
                                  height: 14 / 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
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
                                fromEmail,
                                style: GoogleFonts.roboto(
                                  fontSize: secondaryFs,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.6),
                                ),
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (showDetailsSkeleton)
                          const AppShimmer(
                            width: double.infinity,
                            height: 52,
                            radius: 16,
                          )
                        else
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _updatingStatus
                                ? null
                                : () async {
                                    final chosen = await _showStatusSheet();
                                    if (!mounted || chosen == null) return;
                                    if (chosen == selectedDropdownStatus) return;
                                    _updateStatus(chosen);
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
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
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ],
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
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  colorScheme.onSurface.withOpacity(0.06),
                              child: Text(
                                fromName.isNotEmpty
                                    ? fromName[0].toUpperCase()
                                    : '—',
                                style: GoogleFonts.roboto(
                                  fontSize: bodyFs,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.6),
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
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          height: 160,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: filteredMessages.isEmpty
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '—',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.roboto(
                                      fontSize: secondaryFs,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filteredMessages.length,
                                  padding: EdgeInsets.zero,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final msg = filteredMessages[index];
                                    final isOutgoing = _isOutgoingMessage(msg);
                                    final attachmentName =
                                        _messageAttachmentName(msg);
                                    return Align(
                                      alignment: isOutgoing
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(context).size.width *
                                              0.68,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOutgoing
                                              ? colorScheme.primary
                                                  .withOpacity(0.08)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.12),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isOutgoing
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg.message,
                                              textAlign: isOutgoing
                                                  ? TextAlign.right
                                                  : TextAlign.left,
                                              style: GoogleFonts.roboto(
                                                fontSize: bodyFs,
                                                height: 20 / 14,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                            if (attachmentName
                                                .trim()
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                onTap: () =>
                                                    _downloadAttachment(msg),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.04),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                    border: Border.all(
                                                      color: colorScheme
                                                          .onSurface
                                                          .withOpacity(0.08),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.attach_file,
                                                        size: 14,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withOpacity(0.6),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          attachmentName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              GoogleFonts.roboto(
                                                            fontSize:
                                                                secondaryFs - 1,
                                                            height: 14 / 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.onSurface.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _pickAttachment,
                                        child: Container(
                                          height: 32,
                                          width: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.06),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.attach_file,
                                            size: 16,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextField(
                                              controller: messageController,
                                              minLines: 1,
                                              maxLines: 3,
                                              style: GoogleFonts.roboto(
                                                fontSize: bodyFs,
                                                height: 20 / 14,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText: 'Type a message…',
                                                hintStyle: GoogleFonts.roboto(
                                                  fontSize: bodyFs,
                                                  height: 20 / 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.onSurface
                                                      .withOpacity(0.6),
                                                ),
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                              ),
                                            ),
                                            if (_attachment != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Text(
                                                  _attachment!.filename,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: secondaryFs - 1,
                                                    height: 14 / 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: _sending ? null : _sendMessage,
                                        child: Container(
                                          height: 38,
                                          width: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: colorScheme.primary,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.send,
                                            size: 18,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    ),
                    const SizedBox(height: 12),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFF5F5F7),
              child: AdminHomeAppBar(
                title: widget.ticket.ticketNumber.isNotEmpty
                    ? widget.ticket.ticketNumber
                    : widget.ticket.id,
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
                        softWrap: true,
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

Widget _tabPill(
  BuildContext context, {
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  final cs = Theme.of(context).colorScheme;
  final width = MediaQuery.of(context).size.width;
  final double scale = width >= 900 ? 1 : (width < 360 ? -1 : 0);
  final double tabFs = 14 + scale;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? cs.onSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
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
