// UPDATED: screens/all_activities_screen.dart (renamed from all_transactions_screen.dart)
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AllActivitiesScreen extends StatefulWidget {
  final String activityType;

  const AllActivitiesScreen({super.key, required this.activityType});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  List<DateTime?> _selectedRange = [];
  List<Map<String, dynamic>> allActivities = <Map<String, dynamic>>[];
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void didUpdateWidget(covariant AllActivitiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityType != widget.activityType) {
      _loadActivities();
    }
  }

  @override
  void dispose() {
    _token?.cancel('AllActivitiesScreen disposed');
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

  Future<void> _loadActivities() async {
    _token?.cancel('Reload activities');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

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
                      'status': v.status.isNotEmpty ? v.status : 'Idle',
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
                      'value': t.valueText.isNotEmpty ? t.valueText : '—',
                      'description': t.description.isNotEmpty
                          ? t.description
                          : '—',
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

  Future<void> _pickDateRange() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(350, 380),
      value: _selectedRange,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        selectedDayHighlightColor: Theme.of(context).colorScheme.primary,
      ),
    );

    if (results != null && results.length == 2) {
      setState(() => _selectedRange = results);
    }
  }

  String get formattedRange {
    if (_selectedRange.isEmpty || _selectedRange[0] == null) return 'All Dates';

    final df = DateFormat('MMM dd, yyyy');
    final start = df.format(_selectedRange[0]!);
    final end = _selectedRange.length > 1 && _selectedRange[1] != null
        ? df.format(_selectedRange[1]!)
        : start;
    return '$start - $end';
  }

  List<Map<String, dynamic>> get filteredActivities {
    if (_selectedRange.isEmpty || _selectedRange[0] == null) {
      return allActivities;
    }

    final start = _selectedRange[0]!;
    final end = (_selectedRange[1] ?? start)
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    return allActivities.where((activity) {
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

  Widget buildActivityItem(Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final statusColors = getStatusColors(context);
    final dateStr = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(activity["date"]);

    Widget avatar;
    Widget content;
    Widget right = const SizedBox.shrink();

    switch (widget.activityType) {
      case "Vehicles":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
          backgroundColor: colorScheme.surfaceVariant,
          child: Icon(Icons.directions_car, color: colorScheme.primary),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity["id"],
              style: GoogleFonts.inter(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              activity["name"],
              style: GoogleFonts.inter(
                fontSize: subFontSize,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: subFontSize - 1,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );

        right = Container(
          padding: EdgeInsets.symmetric(
            horizontal: itemPadding + 2,
            vertical: itemPadding - 2,
          ),
          decoration: BoxDecoration(
            color: statusColors[activity["status"]],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            activity["status"],
            style: GoogleFonts.inter(
              color: colorScheme.onPrimary,
              fontSize: badgeFontSize,
            ),
          ),
        );
        break;

      case "Transactions":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
          backgroundColor: colorScheme.surfaceVariant,
          child: Icon(Icons.receipt_long, color: colorScheme.primary),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activity["id"],
                  style: GoogleFonts.inter(
                    fontSize: mainFontSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  activity["value"],
                  style: GoogleFonts.inter(
                    fontSize: mainFontSize,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              activity["description"],
              style: GoogleFonts.inter(
                fontSize: subFontSize,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: subFontSize - 1,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );

        right = Container(
          padding: EdgeInsets.symmetric(
            horizontal: itemPadding,
            vertical: itemPadding - 3,
          ),
          decoration: BoxDecoration(
            color: statusColors[activity["status"]],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            activity["status"],
            style: GoogleFonts.inter(
              color: colorScheme.onPrimary,
              fontSize: badgeFontSize,
            ),
          ),
        );
        break;

      case "Users":
        final name = activity["name"] as String;
        final initials = name
            .split(" ")
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join();

        avatar = Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.8),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
            backgroundColor: Colors.transparent,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: mainFontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              activity["email"],
              style: GoogleFonts.inter(
                fontSize: subFontSize,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: subFontSize - 1,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );

        right = const SizedBox.shrink(); // No status for users
        break;

      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          avatar,
          SizedBox(width: itemPadding + 2),
          Expanded(child: content),
          if (right is! SizedBox) ...[SizedBox(width: itemPadding + 2), right],
        ],
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
    final String title = widget.activityType;
    final String subtitle = 'All ${widget.activityType}';

    return AppLayout(
      title: title,
      subtitle: subtitle,
      showLeftAvatar: false,
      showRightAvatar: false,
      leftAvatarText: '',
      actionIcons: [CupertinoIcons.search], // Optional: Add search if needed
      // onActionTaps: [...] if needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE RANGE PICKER
          Center(
            child: GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: hp,
                  vertical: hp * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: fs + 4,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formattedRange,
                      style: GoogleFonts.inter(
                        fontSize: fs,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (filteredActivities.isEmpty)
            Center(
              child: Text(
                'No activities in selected range',
                style: GoogleFonts.inter(
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
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.onSurface.withOpacity(0.08),
              ),
              itemBuilder: (_, index) =>
                  buildActivityItem(filteredActivities[index]),
            ),
        ],
      ),
    );
  }
}
