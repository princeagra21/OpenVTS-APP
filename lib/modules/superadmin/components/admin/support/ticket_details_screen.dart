// Ticket details screen extracted
import 'dart:io';

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
  final String attachmentName;
  final String attachmentUrl;
  final bool isOutgoing;

  const Message({
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isInternalNote = false,
    this.attachmentName = '',
    this.attachmentUrl = '',
    this.isOutgoing = false,
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
  String _adminIdentifier = '';
  bool _isOutgoingMessage(TicketMessageItem item) {
    final senderId = item.senderId;
    if (_adminIdentifier.isNotEmpty && senderId.isNotEmpty) {
      return senderId == _adminIdentifier;
    }
    return item.senderName == 'You';
  }
  final List<String> statusOptions = [
    "Open",
    "In Process",
    "Closed",
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
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _fullscreenChatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedDropdownStatus = _normalizeTicketStatus(widget.ticket.status);
    if (!statusOptions.contains(selectedDropdownStatus)) {
      statusOptions.insert(0, selectedDropdownStatus);
    }
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _sendToken?.cancel('TicketDetailsScreen disposed');
    _statusToken?.cancel('TicketDetailsScreen disposed');
    _detailsToken?.cancel('TicketDetailsScreen disposed');
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

  String _formatMessageTime(Message msg) {
    final dt = _parseMessageDate(msg.timestamp);
    if (dt == null) return msg.timestamp.trim().isEmpty ? '—' : msg.timestamp;
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  String _dateLabelForMessage(Message msg) {
    final dt = _parseMessageDate(msg.timestamp);
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
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
                      child: Icon(Icons.send, size: 18, color: accentFg),
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
    required List<Message> messages,
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
        final isOutgoing = msg.isOutgoing;
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                alignment:
                    isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: bubbleMinWidth,
                    maxWidth: bubbleMaxWidth,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
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
                      crossAxisAlignment: isOutgoing
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.content,
                          textAlign:
                              isOutgoing ? TextAlign.right : TextAlign.left,
                          style: GoogleFonts.roboto(
                            fontSize: bodyFs - 0.5,
                            fontWeight: FontWeight.w500,
                            color: isOutgoing
                                ? accentFg
                                : baseText,
                          ),
                        ),
                        if (msg.attachmentName.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _downloadAttachment(msg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isOutgoing
                                    ? accentFg.withValues(alpha: 0.12)
                                    : colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    size: 14,
                                    color: isOutgoing
                                        ? accentFg
                                        : mutedText,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      msg.attachmentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(
                                        fontSize: secondaryFs - 1,
                                        fontWeight: FontWeight.w500,
                                        color: isOutgoing
                                            ? accentFg
                                            : mutedText,
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
                              color: isOutgoing
                                  ? accentFg.withValues(alpha: 0.85)
                                  : mutedText,
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

  Future<void> _downloadAttachment(Message message) async {
    final rawPath = message.attachmentUrl.trim();
    if (rawPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment URL not available.')),
      );
      return;
    }

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      final dir = await _resolveDownloadDir();
      final fileName = _safeAttachmentName(message.attachmentName);
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await _api!.dio.download(rawPath, file.path);
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
          final adminIdRaw = (detailMap['adminUserId'] ?? detailMap['adminId'])
                  ?.toString()
                  .trim() ??
              '';
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
              final attachments = m['attachments'];
              if (attachments is List && attachments.isNotEmpty) {
                final first = attachments.first;
                if (first is Map) {
                  m['attachmentName'] ??=
                      first['originalName'] ?? first['storedName'];
                  m['attachmentUrl'] ??= first['filePath'] ?? first['url'];
                }
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
            _adminIdentifier = adminIdRaw.isNotEmpty
                ? adminIdRaw
                : (widget.ticket.numericId.isNotEmpty
                        ? widget.ticket.numericId
                        : widget.ticket.id);
            _messages
              ..clear()
              ..addAll(nextMessages);
          });
          _scrollToLatest();
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
      // Superadmin backend supports only OPEN / IN_PROGRESS / CLOSED.
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
        attachment: _attachment,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (item) {
          final now = DateTime.now();
          final local = TicketMessageItem(<String, dynamic>{
            'senderName': 'You',
            if (_adminIdentifier.isNotEmpty) 'senderId': _adminIdentifier,
            'message': text,
            'createdAt':
                '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            'isInternal': internal,
            if (_attachment != null) ...{
              'attachmentName': _attachment!.filename,
              'attachmentUrl': _attachment!.filename,
            },
          });
          setState(() {
            _sending = false;
            _messages.add(local);
            messageController.clear();
            _attachment = null;
            _hasChanges = true;
          });
          _scrollToLatest();
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
        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    );
  }

  List<Message> _filteredMessagesForTab() {
    return (selectedLocalTab == "Conversation"
            ? _messages.where((m) => !m.isInternal)
            : _messages.where((m) => m.isInternal))
        .map(
          (m) => Message(
            sender: m.senderName.isNotEmpty ? m.senderName : 'Unknown',
            content: m.message,
            timestamp: m.createdAt,
            isInternalNote: m.isInternal,
            attachmentName: m.attachmentName,
            attachmentUrl: m.attachmentUrl,
            isOutgoing: _isOutgoingMessage(m),
          ),
        )
        .toList();
  }

  Future<void> _openFullscreenChat() async {
    final String fromName = (_detailFromName != null &&
            _detailFromName!.trim().isNotEmpty)
        ? _detailFromName!.trim()
        : (widget.ticket.owner.isNotEmpty
            ? widget.ticket.owner
            : (widget.ticket.name.isNotEmpty ? widget.ticket.name : '—'));
    final String fromDate = _formatDateTimeDisplay(
      widget.ticket.updated.isNotEmpty
          ? widget.ticket.updated
          : widget.ticket.created,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final colorScheme = Theme.of(context).colorScheme;
              final w = MediaQuery.of(context).size.width;
              final scale = _supportScale(w);
              final bodyFs = 14 + scale;
              final secondaryFs = 12 + scale;
              final filteredMessages = _filteredMessagesForTab();
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
                                backgroundColor:
                                    colorScheme.onSurface.withValues(alpha: 0.06),
                                child: Text(
                                  fromName.isNotEmpty
                                      ? fromName[0].toUpperCase()
                                      : '—',
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
    if (mounted) {
      setState(() {});
    }
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
    final filteredMessages = _filteredMessagesForTab();
    final showDetailsSkeleton = _loadingDetails && _messages.isEmpty;

    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        color: colorScheme.onSurface.withValues(alpha: 0.08),
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
                                    _detailStatus ?? selectedDropdownStatus,
                                    colorScheme,
                                  ).withValues(alpha: 0.4),
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
                                    style: GoogleFonts.roboto(
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.onSurface.withValues(alpha: 0.12),
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
                                      colorScheme.onSurface.withValues(alpha: 0.6),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fromEmail,
                                style: GoogleFonts.roboto(
                                  fontSize: secondaryFs,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      colorScheme.onSurface.withValues(alpha: 0.6),
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
                            initialValue: statusOptions.contains(selectedDropdownStatus)
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
                            style: GoogleFonts.roboto(
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
                  Expanded(
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double normalPreviewMinHeight = 140;
                          final double normalPreviewMaxHeight =
                              constraints.maxHeight < 540 ? 280 : 360;
                          final double desiredPreviewHeight =
                              (120 + (filteredMessages.length * 64))
                                  .toDouble()
                                  .clamp(
                                    normalPreviewMinHeight,
                                    normalPreviewMaxHeight,
                                  );
                          // Reserve room for header + gaps + composer so column never overflows.
                          final double availableForMessages =
                              (constraints.maxHeight - 170).clamp(100.0, 420.0);
                          final double normalPreviewHeight =
                              desiredPreviewHeight > availableForMessages
                              ? availableForMessages
                              : desiredPreviewHeight;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  colorScheme.onSurface.withValues(alpha: 0.06),
                              child: Text(
                                fromName.isNotEmpty
                                    ? fromName[0].toUpperCase()
                                    : '—',
                                style: GoogleFonts.roboto(
                                  fontSize: bodyFs,
                                  height: 20 / 14,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      colorScheme.onSurface.withValues(alpha: 0.6),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fromDate,
                                    style: GoogleFonts.roboto(
                                      fontSize: secondaryFs,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Open fullscreen chat',
                              onPressed: _openFullscreenChat,
                              icon: Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.onSurface.withValues(alpha: 
                                    0.06,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.open_in_full,
                                  size: 18,
                                  color: colorScheme.onSurface.withValues(alpha: 
                                    0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                              SizedBox(
                                height: normalPreviewHeight,
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
                              const SizedBox(height: 10),
                              _buildReplyComposer(
                                context: context,
                                colorScheme: colorScheme,
                                bodyFs: bodyFs,
                                secondaryFs: secondaryFs,
                                onChangedForParent: () {
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          );
                        },
                      ),
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
              color: Theme.of(context).scaffoldBackgroundColor,
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
  bool shouldRepaint(covariant _ChatPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
