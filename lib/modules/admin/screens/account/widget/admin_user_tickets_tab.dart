import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_ticket_list_item.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_support_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/screens/support/new_ticket_screen.dart';
import 'package:fleet_stack/modules/admin/screens/support/support_screen.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserTicketsTab extends StatefulWidget {
  final String userId;
  final AdminUserListItem userSummary;

  const AdminUserTicketsTab({
    super.key,
    required this.userId,
    required this.userSummary,
  });

  @override
  State<AdminUserTicketsTab> createState() => _AdminUserTicketsTabState();
}

class _AdminUserTicketsTabState extends State<AdminUserTicketsTab> {
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTickets() async {
    _loadToken?.cancel('Reload tickets');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().api.get(
      '/admin/tickets',
      queryParameters: <String, dynamic>{
        'userId': widget.userId,
        'rk': DateTime.now().millisecondsSinceEpoch,
        'limit': 100,
      },
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (data) {
        final list = _extractList(data);
        final items = <AdminTicketListItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              items.add(AdminTicketListItem(item));
            } else if (item is Map) {
              items.add(
                AdminTicketListItem(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
        }
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
        final message =
            err is ApiException ? err.message : "Couldn't load tickets.";
        _showLoadErrorOnce(message);
      },
    );
  }

  List? _extractList(Object? data) {
    if (data is List) return data;
    if (data is! Map) return null;
    final keys = const ['data', 'items', 'result', 'tickets'];
    for (final key in keys) {
      if (data[key] is List) return data[key] as List;
    }
    final d = data['data'];
    if (d is Map) {
      for (final key in keys) {
        if (d[key] is List) return d[key] as List;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _loadToken?.cancel('AdminUserTicketsTab disposed');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = width >= 900 ? 1 : (width < 360 ? -1 : 0);
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

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
          t.category.toLowerCase().contains(query) ||
          t.priority.toLowerCase().contains(query) ||
          t.statusLabel.toLowerCase().contains(query);
      final matchesTab = _selectedTab == 'All' ||
          AdminTicketListItem.normalizeStatus(t.statusLabel) ==
              AdminTicketListItem.normalizeStatus(_selectedTab);
      return matchesSearch && matchesTab;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                        'User Tickets',
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
                          builder: (_) => NewTicketScreen(
                            preSelectedUser: widget.userSummary,
                          ),
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
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: AdaptiveUtils.getIconSize(width),
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'New Ticket',
                            style: GoogleFonts.roboto(
                              fontSize: buttonFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.roboto(
                    fontSize: searchFs,
                    height: 20 / 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tickets...',
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
                    _tabPillLocal(
                      context,
                      label: 'All',
                      selected: _selectedTab == 'All',
                      onTap: () => setState(() => _selectedTab = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _tabPillLocal(
                      context,
                      label: 'Open',
                      selected: _selectedTab == 'Open',
                      onTap: () => setState(() => _selectedTab = 'Open'),
                    ),
                    const SizedBox(width: 8),
                    _tabPillLocal(
                      context,
                      label: 'In Process',
                      selected: _selectedTab == 'In Process',
                      onTap: () => setState(() => _selectedTab = 'In Process'),
                    ),
                    const SizedBox(width: 8),
                    _tabPillLocal(
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
                  child: Center(
                    child: Text(
                      'No tickets found',
                      style: GoogleFonts.roboto(
                        fontSize: secondaryFs,
                        height: 16 / 12,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                ...filteredTickets.map(
                  (ticket) => _TicketCardLocal(
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
      ],
    );
  }

  Widget _tabPillLocal(
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

class _TicketCardLocal extends StatelessWidget {
  final AdminTicketListItem ticket;
  final VoidCallback onTap;

  const _TicketCardLocal({required this.ticket, required this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    final status = _safe(ticket.statusLabel);
    final statusColor = _statusColor(status, colorScheme);
    final category = _safe(ticket.category);
    final priority = _safe(ticket.priority);
    final createdText = _formatShortDate(_safe(ticket.createdAt));

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
              _safe(ticket.subject),
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
                    _safe(ticket.ticketNumber.isNotEmpty
                        ? ticket.ticketNumber
                        : ticket.id),
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
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(_statusIcon(status),
                          size: AdaptiveUtils.getIconSize(width) - 4,
                          color: statusColor),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    [
                      if (category != '—') _titleCase(category),
                      if (priority != '—') '${_titleCase(priority)} Priority',
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
                      Icon(Icons.chevron_right,
                          size: AdaptiveUtils.getIconSize(width),
                          color: colorScheme.primary),
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
