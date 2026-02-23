// UPDATED: components/activity/recent_activity_box.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/debug/superadmin_recent_vehicles_smoke_test.dart';
import 'package:fleet_stack/core/models/superadmin_recent_transaction.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBackground;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double hPadding =
        AdaptiveUtils.getHorizontalPadding(screenWidth) - 4; // 4-12
    final double vPadding =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2; // 4-8
    final double fontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    ); // 11-13

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackground ?? colorScheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class RecentActivityBox extends StatefulWidget {
  const RecentActivityBox({super.key});

  @override
  State<RecentActivityBox> createState() => _RecentActivityBoxState();
}

class _RecentActivityBoxState extends State<RecentActivityBox> {
  String activityTab = "Vehicles";

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

  List<Map<String, dynamic>> vehicleActivities = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> transactionActivities = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> userActivities = <Map<String, dynamic>>[];

  CancelToken? _recentVehiclesCancelToken;
  CancelToken? _recentTransactionsCancelToken;
  CancelToken? _recentUsersCancelToken;
  final CancelToken _smokeCancelToken = CancelToken();
  bool _loadingRecentVehicles = false;
  bool _loadingRecentTransactions = false;
  bool _loadingRecentUsers = false;
  bool _recentVehiclesErrorShown = false;
  bool _recentTransactionsErrorShown = false;
  bool _recentUsersErrorShown = false;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadRecentVehicles();
    _loadRecentTransactions();
    _loadRecentUsers();
  }

  @override
  void dispose() {
    _recentVehiclesCancelToken?.cancel('RecentActivityBox disposed');
    _recentTransactionsCancelToken?.cancel('RecentActivityBox disposed');
    _recentUsersCancelToken?.cancel('RecentActivityBox disposed');
    _smokeCancelToken.cancel('RecentActivityBox disposed');
    super.dispose();
  }

  Future<void> _loadRecentVehicles() async {
    _recentVehiclesCancelToken?.cancel('Reload recent vehicles');
    final token = CancelToken();
    _recentVehiclesCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingRecentVehicles = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getRecentVehicles(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (vehicles) {
          if (kDebugMode) {
            debugPrint(
              '[Home] GET /superadmin/dashboard/recentvehicles status=2xx items=${vehicles.length}',
            );
          }
          if (!mounted) return;
          final mapped = vehicles
              .map(
                (v) => <String, dynamic>{
                  "id": v.id.isNotEmpty ? v.id : "—",
                  "name": v.name.isNotEmpty ? v.name : "—",
                  "status": v.status.isNotEmpty ? v.status : "Active",
                  "time": _friendlyDateTime(v.time),
                },
              )
              .toList();

          setState(() {
            _loadingRecentVehicles = false;
            _recentVehiclesErrorShown = false;
            vehicleActivities = mapped;
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint(
              '[Home] GET /superadmin/dashboard/recentvehicles status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          setState(() => _loadingRecentVehicles = false);

          if (_recentVehiclesErrorShown) return;
          _recentVehiclesErrorShown = true;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load recent vehicles.")),
          );
        },
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[Home] GET /superadmin/dashboard/recentvehicles status=error',
        );
      }
      if (!mounted) return;
      setState(() => _loadingRecentVehicles = false);
      if (_recentVehiclesErrorShown) return;
      _recentVehiclesErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load recent vehicles.")),
      );
    }
  }

  Future<void> _loadRecentTransactions() async {
    _recentTransactionsCancelToken?.cancel('Reload recent transactions');
    final token = CancelToken();
    _recentTransactionsCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingRecentTransactions = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getRecentTransactions(
        limit: 10,
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
          if (!mounted) return;
          final mapped = transactions
              .map(
                (t) => <String, dynamic>{
                  'id': t.id.isNotEmpty ? t.id : '—',
                  'value': t.valueText.isNotEmpty ? t.valueText : '—',
                  'description': _transactionDescription(t),
                  'status': _normalizedTransactionStatus(t.status),
                },
              )
              .toList();

          setState(() {
            _loadingRecentTransactions = false;
            _recentTransactionsErrorShown = false;
            transactionActivities = mapped;
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint(
              '[Home] GET /superadmin/transactions status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          setState(() => _loadingRecentTransactions = false);

          if (_recentTransactionsErrorShown) return;
          _recentTransactionsErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load recent transactions.")),
          );
        },
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Home] GET /superadmin/transactions status=error');
      }
      if (!mounted) return;
      setState(() => _loadingRecentTransactions = false);
      if (_recentTransactionsErrorShown) return;
      _recentTransactionsErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load recent transactions.")),
      );
    }
  }

  Future<void> _loadRecentUsers() async {
    _recentUsersCancelToken?.cancel('Reload recent users');
    final token = CancelToken();
    _recentUsersCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingRecentUsers = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getRecentUsers(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (users) {
          if (kDebugMode) {
            debugPrint(
              '[Home] GET /superadmin/dashboard/recentusers status=2xx items=${users.length}',
            );
          }
          if (!mounted) return;
          final mapped = users
              .map(
                (u) => <String, dynamic>{
                  'name': u.name.isNotEmpty ? u.name : '—',
                  'email': u.email,
                  'time': _friendlyDateTime(u.time),
                },
              )
              .toList();

          setState(() {
            _loadingRecentUsers = false;
            _recentUsersErrorShown = false;
            userActivities = mapped;
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint(
              '[Home] GET /superadmin/dashboard/recentusers status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          setState(() => _loadingRecentUsers = false);

          if (_recentUsersErrorShown) return;
          _recentUsersErrorShown = true;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load recent users.")),
          );
        },
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Home] GET /superadmin/dashboard/recentusers status=error');
      }
      if (!mounted) return;
      setState(() => _loadingRecentUsers = false);
      if (_recentUsersErrorShown) return;
      _recentUsersErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load recent users.")),
      );
    }
  }

  String _normalizedTransactionStatus(String rawStatus) {
    final s = rawStatus.trim().toLowerCase();
    if (s.contains('complete') || s == 'success' || s == 'done') {
      return 'Completed';
    }
    if (s.contains('fail') || s.contains('reject') || s.contains('error')) {
      return 'Failed';
    }
    if (s.contains('pend') || s.contains('process')) {
      return 'Pending';
    }
    return 'Pending';
  }

  String _transactionDescription(SuperadminRecentTransaction transaction) {
    final actor = transaction.actorName;
    final description = transaction.description;
    if (actor.isNotEmpty && description.isNotEmpty) {
      return '$actor • $description';
    }
    if (description.isNotEmpty) return description;
    if (actor.isNotEmpty) return actor;
    return '—';
  }

  String _friendlyDateTime(String raw) {
    if (raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    final diffDays = date.difference(today).inDays;

    final hour12 = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour12:$minute $ampm';

    if (diffDays == 0) return 'Today, $time';
    if (diffDays == -1) return 'Yesterday, $time';

    const months = <String>[
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
    final month = months[local.month - 1];
    return '${local.day} $month, $time';
  }

  List<Map<String, dynamic>> get currentActivities {
    return switch (activityTab) {
      "Vehicles" => vehicleActivities,
      "Transactions" => transactionActivities,
      _ => userActivities,
    };
  }

  bool get _isCurrentTabLoading {
    return (activityTab == "Vehicles" && _loadingRecentVehicles) ||
        (activityTab == "Transactions" && _loadingRecentTransactions) ||
        (activityTab == "Users" && _loadingRecentUsers);
  }

  List<Map<String, dynamic>> get _currentActivitiesForRender {
    if (currentActivities.isNotEmpty) return currentActivities;
    return switch (activityTab) {
      "Vehicles" => [
        {'id': '—', 'name': 'No data', 'status': 'Idle', 'time': ''},
      ],
      "Transactions" => [
        {
          'id': '—',
          'value': '—',
          'description': 'No data',
          'status': 'Pending',
        },
      ],
      _ => [
        {'name': 'No data', 'email': '', 'time': ''},
      ],
    };
  }

  Widget buildActivityItem(Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2; // 12-16
    final double subFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    ); // 11-13
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    ); // 11-13
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(
      screenWidth,
    ); // 6-10

    final statusColors = getStatusColors(context);

    Widget avatar;
    Widget content;
    Widget right = const SizedBox.shrink();

    switch (activityTab) {
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
              activity["time"],
              style: GoogleFonts.inter(
                fontSize: subFontSize,
                color: colorScheme.onSurface.withOpacity(0.54),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity["description"],
                    style: GoogleFonts.inter(
                      fontSize: subFontSize,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
                ),
              ],
            ),
          ],
        );

      default: // Users
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
          ],
        );

        right = Text(
          activity["time"],
          style: GoogleFonts.inter(
            fontSize: subFontSize,
            color: colorScheme.onSurface.withOpacity(0.54),
          ),
        );
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

  Widget _buildActivitySkeletonItem(double screenWidth) {
    final itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final avatarSize = AdaptiveUtils.getAvatarSize(screenWidth) / 1.2;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          AppShimmer(width: avatarSize, height: avatarSize, radius: avatarSize),
          SizedBox(width: itemPadding + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(
                  width: screenWidth * 0.3,
                  height: itemPadding + 10,
                  radius: 6,
                ),
                SizedBox(height: itemPadding / 1.5),
                AppShimmer(
                  width: screenWidth * 0.45,
                  height: itemPadding + 8,
                  radius: 6,
                ),
              ],
            ),
          ),
          SizedBox(width: itemPadding + 2),
          AppShimmer(
            width: screenWidth * 0.2,
            height: itemPadding + 10,
            radius: 999,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double linkFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
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
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Recent Activity",
                      style: GoogleFonts.inter(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if ((_loadingRecentVehicles && activityTab == "Vehicles") ||
                        (_loadingRecentTransactions &&
                            activityTab == "Transactions") ||
                        (_loadingRecentUsers && activityTab == "Users"))
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: AppShimmer(width: 14, height: 14, radius: 7),
                        ),
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  context.push(
                    '/superadmin/all-activities',
                    extra: {'type': activityTab},
                  );
                },
                onLongPress: kDebugMode
                    ? () => DebugSuperadminRecentVehiclesSmokeTest.run(
                        context,
                        cancelToken: _smokeCancelToken,
                      )
                    : null,
                child: Text(
                  "View all",
                  style: GoogleFonts.inter(
                    fontSize: linkFontSize,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: padding),

          Center(
            child: Wrap(
              spacing: AdaptiveUtils.getIconPaddingLeft(screenWidth) - 4,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ["Vehicles", "Transactions", "Users"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: activityTab == tab,
                  onTap: () => setState(() => activityTab = tab),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: padding - 2),

          SizedBox(
            height: 320,
            child: _isCurrentTabLoading
                ? ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                    itemBuilder: (_, __) =>
                        _buildActivitySkeletonItem(screenWidth),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _currentActivitiesForRender.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                    itemBuilder: (_, index) =>
                        buildActivityItem(_currentActivitiesForRender[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
