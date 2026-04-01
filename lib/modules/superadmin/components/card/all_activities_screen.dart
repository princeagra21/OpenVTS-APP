// UPDATED: screens/all_activities_screen.dart (renamed from all_transactions_screen.dart)
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/core/models/admin_list_item.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AllActivitiesScreen extends StatefulWidget {
  final String activityType;

  const AllActivitiesScreen({super.key, required this.activityType});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  List<DateTime?> _selectedRange = [];
  List<Map<String, dynamic>> allActivities = <Map<String, dynamic>>[];
  String _searchQuery = '';
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  CancelToken? _adminToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  List<AdminListItem> _admins = const [];
  AdminListItem? _selectedAdmin;
  String _dateFilterLabel = 'This month';
  bool _loadingAdmins = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedRange = [DateTime(now.year, now.month, 1), now];
    _loadActivities();
  }

  @override
  void didUpdateWidget(covariant AllActivitiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityType != widget.activityType) {
      _selectedAdmin = null;
      _dateFilterLabel = 'This month';
      final now = DateTime.now();
      _selectedRange = [];
      if (widget.activityType == 'Transactions') {
        _selectedRange = [DateTime(now.year, now.month, 1), now];
      }
      _loadActivities();
    }
  }

  @override
  void dispose() {
    _token?.cancel('AllActivitiesScreen disposed');
    _adminToken?.cancel('AllActivitiesScreen disposed');
    super.dispose();
  }

  DateTime _parseDate(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed ?? DateTime.now();
  }

  String _normalizedTransactionStatus(String rawStatus) {
    final s = rawStatus.trim().toLowerCase();
    if (s.contains('complete') || s == 'success' || s == 'done') {
      return 'Completed';
    }
    if (s.contains('fail') || s.contains('reject') || s.contains('error')) {
      return 'Failed';
    }
    return 'Pending';
  }

  String _capitalizeFirst(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final lower = trimmed.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  String _safeString(Object? value, {String fallback = "—"}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(date.toUtc());
    if (diff.inHours < 24) {
      final h = diff.inHours < 1 ? 1 : diff.inHours;
      return '${h}h';
    }
    if (diff.inDays < 30) {
      final d = diff.inDays < 1 ? 1 : diff.inDays;
      return '${d}d';
    }
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months < 1 ? 1 : months}mo';
    final years = (diff.inDays / 365).floor();
    return '${years < 1 ? 1 : years}y';
  }

  String _formatDate(DateTime date) {
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
    final local = date.toLocal();
    final m = months[local.month - 1];
    final hour12 = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'pm' : 'am';
    return '${local.day} $m, $hour12:$minute $ampm';
  }

  String _formatDateOnly(DateTime date) {
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
    final local = date.toLocal();
    final m = months[local.month - 1];
    return '${local.day} $m, ${local.year}';
  }

  String _formatDateInput(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  DateTime? _parseInputDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;
    return DateTime(y, m, d);
  }

  double _parseAmount(Object? value) {
    if (value == null) return 0;
    final raw = value.toString();
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatRevenue(double amount, String currency) {
    final formatted = NumberFormat.compact().format(amount);
    return currency.isNotEmpty ? '$currency $formatted' : formatted;
  }

  Future<void> _loadActivities() async {
    _token?.cancel('Reload activities');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() {
      _loading = true;
      if (widget.activityType == "Vehicles") {
        _selectedRange = [];
      }
    });

    try {
      _ensureRepo();

      switch (widget.activityType) {
        case "Vehicles":
          final res = await _repo!.getVehicles(limit: 200, cancelToken: token);
          if (!mounted) return;
          res.when(
            success: (vehicles) {
              if (kDebugMode) {
                debugPrint(
                  '[Home] GET /superadmin/vehicles status=2xx items=${vehicles.length}',
                );
              }
              final mapped = vehicles
                  .map(
                    (v) => <String, dynamic>{
                      'id': v.id.isNotEmpty ? v.id : '—',
                      'name': v.name.isNotEmpty ? v.name : '—',
                      'type': v.type.isNotEmpty ? v.type : '—',
                      'status': v.status.isNotEmpty ? v.status : 'Idle',
                      'imei': v.imei,
                      'simNumber': v.simNumber,
                      'plateNumber': v.plateNumber,
                      'date': _parseDate(v.updatedAt),
                    },
                  )
                  .toList();
              if (!mounted) return;
              setState(() {
                allActivities = mapped;
                _loading = false;
                _errorShown = false;
              });
            },
            failure: (_) => _handleLoadFailure("Couldn't load vehicles."),
          );
          break;

        case "Transactions":
          _loadAdmins();
          final res = await _repo!.getRecentTransactions(
            limit: 200,
            cancelToken: token,
          );
          if (!mounted) return;
          res.when(
            success: (transactions) {
              if (kDebugMode) {
                debugPrint(
                  '[Home] GET /superadmin/transactions status=2xx items=${transactions.length}',
                );
              }
              final mapped = transactions
                  .map(
                    (t) => <String, dynamic>{
                      'id': t.id.isNotEmpty ? t.id : '—',
                      'name': t.fromUserName.isNotEmpty
                          ? t.fromUserName
                          : '—',
                      'value': t.valueText.isNotEmpty ? t.valueText : '—',
                      'currency': t.currency.isNotEmpty ? t.currency : '',
                      'adminId': t.fromUserId,
                      'status': _normalizedTransactionStatus(t.status),
                      'date': _parseDate(t.time),
                    },
                  )
                  .toList();
              if (!mounted) return;
              setState(() {
                allActivities = mapped;
                _loading = false;
                _errorShown = false;
              });
            },
            failure: (_) => _handleLoadFailure("Couldn't load transactions."),
          );
          break;

        case "Users":
          final res = await _repo!.getRecentUsers(cancelToken: token);
          if (!mounted) return;
          res.when(
            success: (users) {
              if (kDebugMode) {
                debugPrint(
                  '[Home] GET /superadmin/dashboard/recentusers status=2xx items=${users.length}',
                );
              }
              final mapped = users
                  .map(
                    (u) => <String, dynamic>{
                      'name': u.name.isNotEmpty ? u.name : '—',
                      'email': u.email,
                      'date': _parseDate(u.time),
                    },
                  )
                  .toList();
              if (!mounted) return;
              setState(() {
                allActivities = mapped;
                _loading = false;
                _errorShown = false;
              });
            },
            failure: (_) => _handleLoadFailure("Couldn't load users."),
          );
          break;

        default:
          if (!mounted) return;
          setState(() {
            allActivities = <Map<String, dynamic>>[];
            _loading = false;
          });
      }
    } catch (_) {
      _handleLoadFailure("Couldn't load ${widget.activityType.toLowerCase()}.");
    }
  }

  void _handleLoadFailure(String message) {
    if (!mounted) return;
    setState(() => _loading = false);
    if (_errorShown) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _snackOnce(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _ensureRepo() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= SuperadminRepository(api: _api!);
  }

  void _applySearch(String query) {
    if (!mounted) return;
    setState(() => _searchQuery = query.trim());
  }

  Future<void> _loadAdmins() async {
    if (_loadingAdmins || _admins.isNotEmpty) return;
    _adminToken?.cancel('reload admins');
    _adminToken = CancelToken();
    _ensureRepo();
    if (!mounted) return;
    setState(() => _loadingAdmins = true);
    try {
      final res = await _repo!.getAdmins(
        limit: 200,
        cancelToken: _adminToken,
      );
      if (!mounted) return;
      res.when(
        success: (admins) {
          setState(() {
            _admins = admins;
            _loadingAdmins = false;
          });
        },
        failure: (_) {
          setState(() => _loadingAdmins = false);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
    }
  }

  void _openAdminFilter() {
    _loadAdmins();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Admin',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _loadingAdmins
                      ? const Center(
                          child: AppShimmer(width: 18, height: 18, radius: 9),
                        )
                      : ListView.separated(
                          itemCount: _admins.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                title: Text(
                                  'All Admins',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: _selectedAdmin == null
                                    ? Icon(
                                        Icons.check,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() => _selectedAdmin = null);
                                  Navigator.pop(context);
                                },
                              );
                            }
                            final a = _admins[i - 1];
                            final name = a.name.isNotEmpty
                                ? a.name
                                : (a.username.isNotEmpty ? a.username : '—');
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              title: Text(
                                name,
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                a.email.isNotEmpty ? a.email : '—',
                                style: GoogleFonts.roboto(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              trailing: _selectedAdmin?.id == a.id
                                  ? Icon(
                                      Icons.check,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _selectedAdmin = a);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDateFilter() {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Date Filter',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('This month'),
                  onTap: () {
                    final start = DateTime(now.year, now.month, 1);
                    setState(() {
                      _selectedRange = [start, now];
                      _dateFilterLabel = 'This month';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Last 30 days'),
                  onTap: () {
                    final start = now.subtract(const Duration(days: 30));
                    setState(() {
                      _selectedRange = [start, now];
                      _dateFilterLabel = 'Last 30 days';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('This year'),
                  onTap: () {
                    final start = DateTime(now.year, 1, 1);
                    setState(() {
                      _selectedRange = [start, now];
                      _dateFilterLabel = 'This year';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Custom'),
                  onTap: () {
                    Navigator.pop(context);
                    _openCustomDateDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCustomDateDialog() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(350, 380),
      value: _selectedRange,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        selectedDayHighlightColor: Theme.of(context).colorScheme.primary,
        okButton: const Text('Proceed'),
        cancelButton: const Text('Cancel'),
      ),
    );

    if (results != null && results.isNotEmpty && results.first != null) {
      final from = results[0]!;
      final to = results.length > 1 && results[1] != null ? results[1]! : from;
      if (to.isBefore(from)) {
        _snackOnce('To date must be after From date.');
        return;
      }
      setState(() {
        _selectedRange = [from, to];
        _dateFilterLabel =
            '${_formatDateInput(from)} - ${_formatDateInput(to)}';
      });
    }
  }

  List<Map<String, dynamic>> get filteredActivities {
    var list = allActivities;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((activity) {
        final name = _safeString(activity['name'], fallback: '').toLowerCase();
        final email = _safeString(activity['email'], fallback: '').toLowerCase();
        final type = _safeString(activity['type'], fallback: '').toLowerCase();
        final status =
            _safeString(activity['status'], fallback: '').toLowerCase();
        final value = _safeString(activity['value'], fallback: '').toLowerCase();
        final id = _safeString(activity['id'], fallback: '').toLowerCase();
        final imei = _safeString(activity['imei'], fallback: '').toLowerCase();
        final sim = _safeString(activity['simNumber'], fallback: '')
            .toLowerCase();
        final plate = _safeString(activity['plateNumber'], fallback: '')
            .toLowerCase();

        return name.contains(q) ||
            email.contains(q) ||
            type.contains(q) ||
            status.contains(q) ||
            value.contains(q) ||
            id.contains(q) ||
            imei.contains(q) ||
            sim.contains(q) ||
            plate.contains(q);
      }).toList();
    }

    if (widget.activityType == "Transactions" && _selectedAdmin != null) {
      final adminId = _selectedAdmin!.id;
      list =
          list.where((a) => _safeString(a['adminId']) == adminId).toList();
    }

    if (widget.activityType == "Users") {
      return list;
    }

    if (_selectedRange.isEmpty || _selectedRange[0] == null) {
      return list;
    }

    final start = _selectedRange[0]!;
    final end = (_selectedRange[1] ?? start)
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    return list.where((activity) {
      final date = activity["date"] as DateTime;
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Map<String, Color> getStatusColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      "Active": colorScheme.primary,
      "Idle": colorScheme.primary.withOpacity(0.7),
      "Completed": colorScheme.primary,
      "Pending": colorScheme.primary.withOpacity(0.7),
      "Failed": colorScheme.error,
    };
  }

  Widget _buildTransactionSummary(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 1;
    final double valueSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) + 1;
    final double pad = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final totalTxns = items.length;
    final successful =
        items.where((e) => _safeString(e['status']) == 'Completed').length;
    final pending =
        items.where((e) => _safeString(e['status']) == 'Pending').length;
    final failed =
        items.where((e) => _safeString(e['status']) == 'Failed').length;

    final revenue = items.fold<double>(
      0,
      (sum, e) => sum + _parseAmount(e['value']),
    );
    final currency = items.isNotEmpty
        ? _safeString(items.first['currency'], fallback: '')
        : '';

    final cards = [
      {
        'title': 'Revenue',
        'value': _formatRevenue(revenue, currency),
        'icon': Icons.currency_rupee,
      },
      {
        'title': 'Total Txns',
        'value': totalTxns.toString(),
        'icon': Icons.trending_up,
      },
      {
        'title': 'Successful',
        'value': successful.toString(),
        'icon': Icons.check_circle_outline,
      },
      {
        'title': 'Pending',
        'value': pending.toString(),
        'icon': Icons.schedule,
      },
      {
        'title': 'Failed',
        'value': failed.toString(),
        'icon': Icons.error_outline,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;
        final itemWidth = (maxWidth - (spacing * 2)) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((c) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: EdgeInsets.all(pad),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          c['icon'] as IconData,
                          size: titleSize + 6,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c['value'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: valueSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildActivityItem(Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final statusColors = getStatusColors(context);
    final date = activity["date"] as DateTime;
    final dateStr = _formatDate(date);

    Widget avatar;
    Widget content;
    Widget right = const SizedBox.shrink();

    switch (widget.activityType) {
      case "Vehicles":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.1,
          backgroundColor:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant,
          child: Icon(
            Icons.directions_car_outlined,
            size: mainFontSize + 1,
            color: colorScheme.primary,
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _capitalizeFirst(_safeString(activity["name"], fallback: "")),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _capitalizeFirst(
                      _safeString(activity["type"], fallback: "—"),
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: subFontSize,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      dateStr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: subFontSize - 2,
                        color: colorScheme.onSurface.withOpacity(0.54),
                      ),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        );

        right = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: itemPadding - 2,
                vertical: itemPadding - 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                activity["status"],
                style: GoogleFonts.roboto(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: badgeFontSize - 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _relativeTime(date),
              style: GoogleFonts.roboto(
                fontSize: subFontSize,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
          ],
        );
        break;

      case "Transactions":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.1,
          backgroundColor:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant,
          child: Icon(
            Icons.credit_card,
            size: mainFontSize + 1,
            color: colorScheme.primary,
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _capitalizeFirst(_safeString(activity["name"], fallback: "")),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDateOnly(date),
              style: GoogleFonts.roboto(
                fontSize: subFontSize - 2,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
          ],
        );

        right = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _safeString(activity["value"], fallback: "—"),
              style: GoogleFonts.roboto(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _safeString(activity["status"], fallback: ""),
              style: GoogleFonts.roboto(
                fontSize: subFontSize - 3,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
          ],
        );
        break;

      case "Users":
        final name = _safeString(activity["name"], fallback: "—");
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.1,
          backgroundColor:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant,
          child: Icon(
            Icons.group,
            size: mainFontSize + 1,
            color: colorScheme.primary,
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              _safeString(activity["email"], fallback: ""),
              style: GoogleFonts.roboto(
                fontSize: subFontSize,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
          ],
        );

        right = Text(
          _formatDateOnly(date),
          style: GoogleFonts.roboto(
            fontSize: subFontSize - 2,
            color: colorScheme.onSurface.withOpacity(0.54),
          ),
        );
        break;

      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding / 2),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: itemPadding,
          vertical: itemPadding,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            avatar,
            SizedBox(width: itemPadding + 2),
            Expanded(child: content),
            if (right is! SizedBox) ...[
              SizedBox(width: itemPadding + 2),
              right,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final double avatarSize = AdaptiveUtils.getAvatarSize(screenWidth);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(vertical: itemPadding / 2),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: itemPadding,
            vertical: itemPadding,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AppShimmer(
                width: avatarSize,
                height: avatarSize,
                radius: avatarSize / 2,
              ),
              SizedBox(width: itemPadding + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppShimmer(width: 140, height: 12, radius: 6),
                    const SizedBox(height: 8),
                    const AppShimmer(width: 110, height: 10, radius: 6),
                  ],
                ),
              ),
              SizedBox(width: itemPadding + 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  AppShimmer(width: 60, height: 10, radius: 6),
                  SizedBox(height: 8),
                  AppShimmer(width: 40, height: 10, radius: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double hp = AdaptiveUtils.getHorizontalPadding(
      MediaQuery.of(context).size.width,
    );
    final double fs = AdaptiveUtils.getSubtitleFontSize(
      MediaQuery.of(context).size.width,
    );
    final String title = '';
    final String subtitle = widget.activityType == 'Transactions'
        ? 'Payments'
        : 'All ${widget.activityType}';

    return AppLayout(
      title: title,
      subtitle: subtitle,
      showLeftAvatar: false,
      showRightAvatar: false,
      leftAvatarText: '',
      actionIcons: [CupertinoIcons.search], // Optional: Add search if needed
      onSearchSubmitted: _applySearch,
      onSearchChanged: _applySearch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.activityType == "Transactions") ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: hp,
                vertical: hp * 0.9,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payments',
                            style: GoogleFonts.roboto(
                              fontSize: fs - 1,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage transactions',
                            style: GoogleFonts.roboto(
                              fontSize: fs - 3,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push(
                          '/superadmin/transactions/record-manual',
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: hp * 0.7,
                            vertical: hp * 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: fs,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Record payment',
                                style: GoogleFonts.roboto(
                                  fontSize: fs - 3,
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
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_loading)
            _buildLoadingList(context)
          else
            Column(
              children: [
                if (widget.activityType == "Transactions") ...[
                  _buildTransactionSummary(context, filteredActivities),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final maxWidth = constraints.maxWidth;
                      final itemWidth = (maxWidth - spacing) / 2;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: GestureDetector(
                              onTap: _openAdminFilter,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hp * 0.8,
                                  vertical: hp * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.white
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: fs + 2,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedAdmin == null
                                            ? 'All admins'
                                            : _safeString(
                                                _selectedAdmin!.name,
                                                fallback:
                                                    _selectedAdmin!.username,
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.roboto(
                                          fontSize: fs - 2,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: GestureDetector(
                              onTap: _openDateFilter,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: hp * 0.8,
                                  vertical: hp * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.white
                                      : colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: fs + 1,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _dateFilterLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                          fontSize: fs - 2,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (filteredActivities.isEmpty)
                  Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No activities found'
                          : 'No activities in selected range',
                      style: GoogleFonts.roboto(
                        fontSize: fs,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true, // Added to fix unbounded height
                    physics:
                        NeverScrollableScrollPhysics(), // Added to disable inner scroll, let outer handle it
                    padding: EdgeInsets.zero,
                    itemCount: filteredActivities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        buildActivityItem(filteredActivities[index]),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
