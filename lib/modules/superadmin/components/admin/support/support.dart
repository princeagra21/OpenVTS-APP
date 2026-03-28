// screens/support/support_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/ticket_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/support/ticket_details_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/support/new_ticket_screen.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

double _supportScale(double width) {
  if (width >= 900) return 1;
  if (width < 360) return -1;
  return 0;
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
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';

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
    _searchController.dispose();
    super.dispose();
  }

  Ticket _mapTicketItem(TicketListItem t) {
    final ticketNo = t.ticketNumber;
    final numericId = t.id;
    final id = ticketNo.isNotEmpty
        ? ticketNo
        : (numericId.isNotEmpty ? numericId : '—');
    final raw = t.raw;
    final rawFromUser = raw['fromUser'];
    final fromUserName = rawFromUser is Map ? rawFromUser['name']?.toString() : null;
    String clean(String? v) {
      if (v == null) return '';
      final s = v.trim();
      return (s.isEmpty || s == '_' || s.toLowerCase() == 'null') ? '' : s;
    }
    final normalizedTitle = t.subject.trim();
    final title = normalizedTitle.isNotEmpty && normalizedTitle != '_'
        ? normalizedTitle
        : (t.ticketNumber.isNotEmpty
            ? t.ticketNumber
            : 'Support Ticket');
    final fallbackEmail = raw['email']?.toString();
    final name = clean(fromUserName).isNotEmpty
        ? clean(fromUserName)
        : (clean(t.ownerName).isNotEmpty
            ? clean(t.ownerName)
            : (clean(t.userName).isNotEmpty
                ? clean(t.userName)
                : (clean(fallbackEmail).isNotEmpty
                    ? clean(fallbackEmail)
                    : '—')));
    final status = _normalizeTicketStatus(t.status);
    final lastMessageAt = raw['lastMessageAt']?.toString() ?? '';
    final created = t.createdAt.isNotEmpty
        ? t.createdAt
        : (lastMessageAt.isNotEmpty ? lastMessageAt : '');
    final updated = '';
    final desc = t.snippet.isNotEmpty ? t.snippet : '';

    return Ticket(
      title: title,
      id: id,
      ticketNo: ticketNo,
      numericId: numericId,
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
    final double scale = _supportScale(width);
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double topPadding = MediaQuery.of(context).padding.top;

    final double sectionTitleFs = 18 + scale;
    final double buttonFs = 14 + scale;
    final double searchFs = 14 + scale;
    final double secondaryFs = 12 + scale;

    final showListSkeleton = _loadingTickets && _tickets.isEmpty;
    final filteredTickets = _tickets.where((t) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.id.toLowerCase().contains(query) ||
          t.name.toLowerCase().contains(query) ||
          t.owner.toLowerCase().contains(query);
      final matchesTab = _selectedTab == 'All' ||
          _normalizeTicketStatus(t.status) == _selectedTab;
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
                      "Support Inbox",
                      style: GoogleFonts.inter(
                        fontSize: sectionTitleFs,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (showListSkeleton)
                      const AppShimmer(width: 96, height: 14, radius: 8)
                    else
                      Text(
                        "${_tickets.length} tickets",
                        style: GoogleFonts.inter(
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
                    );
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
                          "New Ticket",
                          style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
                  fontSize: searchFs,
                  height: 20 / 14,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "Search tickets",
                  hintStyle: GoogleFonts.inter(
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
                    onTap: () => setState(() => _selectedTab = 'In Process'),
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

            // TICKET CARDS LIST
            if (showListSkeleton)
              ...List<Widget>.generate(4, (_) => const _TicketCardShimmer())
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
                  "No tickets found",
                  style: GoogleFonts.inter(
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
            ),
          ),
          Positioned(
            left: hp,
            right: hp,
            top: 0,
            child: SuperAdminHomeAppBar(
              title: 'Support',
              leadingIcon: Icons.support_agent_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Ticket Details Screen ---

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
        border: Border.all(
          color: cs.onSurface.withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: tabFs,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          color: selected ? cs.surface : cs.onSurface,
        ),
      ),
    ),
  );
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
    final double scale = width >= 900 ? 1 : (width < 360 ? -1 : 0);
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final Color statusColor = _statusColor(ticket.status, colorScheme);
    final double ticketTitleFs = 14 + scale;
    final double secondaryFs = 12 + scale;
    final double metaFs = 11 + scale;
    final createdAt = DateTime.tryParse(ticket.created);
    final createdText = createdAt == null
        ? '-'
        : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    return Container(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    ticket.title,
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
                if (_normalizeTicketStatus(ticket.status) != 'Closed')
                  Text(
                    '•',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text(
                    ticket.id,
                    style: GoogleFonts.inter(
                      fontSize: metaFs,
                      height: 14 / 11,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        _normalizeTicketStatus(ticket.status) == 'Closed'
                            ? Icons.check_circle_outline
                            : _normalizeTicketStatus(ticket.status) == 'Answered'
                                ? Icons.mark_email_read_outlined
                                : _normalizeTicketStatus(ticket.status) == 'Hold'
                                    ? Icons.pause_circle_outline
                                    : _normalizeTicketStatus(ticket.status) == 'In Process'
                                        ? Icons.schedule_outlined
                                        : Icons.radio_button_unchecked,
                        size: AdaptiveUtils.getIconSize(width) - 4,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ticket.status,
                        style: GoogleFonts.inter(
                          fontSize: metaFs,
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
            Text(
              'From',
              style: GoogleFonts.inter(
                fontSize: metaFs,
                height: 14 / 11,
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ticket.name,
                    style: GoogleFonts.inter(
                      fontSize: secondaryFs,
                      height: 16 / 12,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  createdText,
                  style: GoogleFonts.inter(
                    fontSize: secondaryFs,
                    height: 16 / 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (ticket.desc.isNotEmpty)
              Text(
                ticket.desc,
                style: GoogleFonts.inter(
                  fontSize: secondaryFs,
                  height: 16 / 12,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Ticket',
                        style: GoogleFonts.inter(
                          fontSize: secondaryFs,
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
    );
  }
}
