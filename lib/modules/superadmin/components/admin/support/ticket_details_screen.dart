// Ticket details screen extracted
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/ticket_message_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/utils/file_picker_helper.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Ticket {
  final String title;
  final String id;
  final String ticketNo;
  final String numericId;
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
    required this.ticketNo,
    required this.numericId,
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

IconData _statusIcon(String status) {
  final s = _normalizeTicketStatus(status);
  if (s == 'Closed') return Icons.check_circle_outline;
  if (s == 'Answered') return Icons.mark_email_read_outlined;
  if (s == 'Hold') return Icons.pause_circle_outline;
  if (s == 'In Process') return Icons.schedule_outlined;
  return Icons.radio_button_unchecked;
}

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
  PickedFilePayload? _attachment;
  String? _detailTitle;
  String? _detailCategory;
  String? _detailPriority;
  String? _detailStatus;
  String? _detailFromName;
  String? _detailFromEmail;

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
        widget.ticket.numericId.isNotEmpty
            ? widget.ticket.numericId
            : widget.ticket.id,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (payload) {
          final detailMap = (payload['data'] is Map)
              ? Map<String, dynamic>.from((payload['data'] as Map).cast())
              : payload;
          final normalizedStatus = _normalizeTicketStatus(
            (detailMap['status'] ?? '').toString(),
          );
          final rawTitle = (detailMap['title'] ?? '').toString();
          final rawCategory = (detailMap['category'] ?? '').toString();
          final rawPriority = (detailMap['priority'] ?? '').toString();
          final fromUser = detailMap['fromUser'];
          final fromName = fromUser is Map
              ? (fromUser['name'] ?? '').toString()
              : '';
          final fromEmail = fromUser is Map
              ? (fromUser['email'] ?? '').toString()
              : '';

          final nextMessages = <TicketMessageItem>[];
          final rawMessages = detailMap['messages'];
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
            _detailTitle = rawTitle.isNotEmpty ? rawTitle : _detailTitle;
            _detailCategory =
                rawCategory.isNotEmpty ? rawCategory : _detailCategory;
            _detailPriority =
                rawPriority.isNotEmpty ? rawPriority : _detailPriority;
            _detailStatus =
                normalizedStatus.isNotEmpty ? normalizedStatus : _detailStatus;
            _detailFromName =
                fromName.isNotEmpty ? fromName : _detailFromName;
            _detailFromEmail =
                fromEmail.isNotEmpty ? fromEmail : _detailFromEmail;
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
        widget.ticket.numericId.isNotEmpty
            ? widget.ticket.numericId
            : widget.ticket.id,
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
            _messages.add(local);
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
        widget.ticket.numericId.isNotEmpty
            ? widget.ticket.numericId
            : widget.ticket.id,
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
    final double scale = _supportScale(w);
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double ticketTitleFs = 14 + scale;
    final double bodyFs = 14 + scale;
    final double secondaryFs = 12 + scale;
    final double metaFs = 11 + scale;
    final String fromName = (_detailFromName != null &&
            _detailFromName!.trim().isNotEmpty)
        ? _detailFromName!.trim()
        : (widget.ticket.owner.isNotEmpty
            ? widget.ticket.owner
            : (widget.ticket.name.isNotEmpty ? widget.ticket.name : '—'));
    final String fromEmail = (_detailFromEmail != null &&
            _detailFromEmail!.trim().isNotEmpty)
        ? _detailFromEmail!.trim()
        : '—';
    final String fromDate = _formatDateTimeDisplay(
      widget.ticket.updated.isNotEmpty
          ? widget.ticket.updated
          : widget.ticket.created,
    );
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
    final Message? latestMessage =
        filteredMessages.isNotEmpty ? filteredMessages.last : null;
    final showDetailsSkeleton = _loadingDetails && _messages.isEmpty;

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
                                (_detailTitle != null &&
                                        _detailTitle!.trim().isNotEmpty)
                                    ? _detailTitle!
                                    : widget.ticket.title,
                                style: GoogleFonts.inter(
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
                                    _detailStatus ?? selectedDropdownStatus,
                                    colorScheme,
                                  ).withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _statusIcon(
                                      _detailStatus ?? selectedDropdownStatus,
                                    ),
                                    size: AdaptiveUtils.getIconSize(w) - 4,
                                    color: _statusColor(
                                      _detailStatus ?? selectedDropdownStatus,
                                      colorScheme,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _detailStatus ?? selectedDropdownStatus,
                                    style: GoogleFonts.inter(
                                      fontSize: metaFs,
                                      height: 14 / 11,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(
                                        _detailStatus ?? selectedDropdownStatus,
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
                            widget.ticket.ticketNo.isNotEmpty
                                ? widget.ticket.ticketNo
                                : widget.ticket.id,
                            if (_titleCase(_detailCategory ?? '').isNotEmpty)
                              _titleCase(_detailCategory ?? ''),
                            if (_titleCase(_detailPriority ?? '').isNotEmpty)
                              '${_titleCase(_detailPriority ?? '')} Priority',
                          ].join(' · '),
                          style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
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
                                style: GoogleFonts.inter(
                                  fontSize: bodyFs,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fromEmail,
                                style: GoogleFonts.inter(
                                  fontSize: secondaryFs,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                              fontSize: secondaryFs,
                              height: 16 / 12,
                              color: colorScheme.onSurface,
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.primary,
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
                                style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fromDate,
                                    style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
                                    return Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.12),
                                          ),
                                        ),
                                        child: Text(
                                          msg.content,
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.inter(
                                            fontSize: bodyFs,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
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
                                              style: GoogleFonts.inter(
                                                fontSize: bodyFs,
                                                height: 20 / 14,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface,
                                              ),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                hintText: 'Type a message…',
                                                hintStyle: GoogleFonts.inter(
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
                                                  style: GoogleFonts.inter(
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
                ],
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
              child: SuperAdminHomeAppBar(
                title: widget.ticket.ticketNo.isNotEmpty
                    ? widget.ticket.ticketNo
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

// --- New Widget for Messages Display ---

class _MessagesContainer extends StatelessWidget {
  final List<Message> messages;
  final String selectedTab;

  const _MessagesContainer({required this.messages, required this.selectedTab});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double messageHeight = MediaQuery.of(context).size.height * 0.4;
    final double width = MediaQuery.of(context).size.width;
    final double scale = width >= 900 ? 1 : (width < 360 ? -1 : 0);
    final double messageTitleFs = 14 + scale;
    final double messageBodyFs = 14 + scale;
    final double metaFs = 11 + scale;

    if (messages.isEmpty) {
      return Container(
        width: double.infinity,
        height: messageHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Text(
          "No ${selectedTab.toLowerCase()} messages for this ticket.",
          style: GoogleFonts.inter(
            fontSize: messageBodyFs,
            height: 20 / 14,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.builder(
        reverse: false, // default
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        message.sender,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: messageTitleFs,
                          height: 20 / 14,
                          color: message.isInternalNote
                              ? Colors.purple
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.timestamp,
                        style: GoogleFonts.inter(
                          fontSize: metaFs,
                          height: 14 / 11,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: messageBodyFs,
                      height: 20 / 14,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                ],
              ),
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
    final double scale = width >= 900 ? 1 : (width < 360 ? -1 : 0);
    final double tabFs = 14 + scale;

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
            fontSize: small ? (tabFs - 1) : tabFs,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
