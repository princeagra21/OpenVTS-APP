// UPDATED: components/activity/recent_activity_box.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/debug/superadmin_recent_vehicles_smoke_test.dart';
import 'package:fleet_stack/core/models/superadmin_recent_vehicle.dart';
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

class RecentActivityBox extends StatefulWidget {
  const RecentActivityBox({super.key});

  @override
  State<RecentActivityBox> createState() => _RecentActivityBoxState();
}

class _RecentActivityBoxState extends State<RecentActivityBox> {
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

  String _relativeTime(Object? value) {
    final raw = _safeString(value, fallback: "");
    if (raw.isEmpty) return "";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return "";
    final now = DateTime.now().toUtc();
    final diff = now.difference(parsed.toUtc());
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

  String _formatDate(Object? value) {
    final raw = _safeString(value, fallback: "");
    if (raw.isEmpty) return "";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
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
    final date = parsed.toLocal();
    final m = months[date.month - 1];
    final hour12 = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'pm' : 'am';
    return '${date.day} $m, $hour12:$minute $ampm';
  }

  String _formatDateOnly(Object? value) {
    final raw = _safeString(value, fallback: "");
    if (raw.isEmpty) return "";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
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
    final date = parsed.toLocal();
    final m = months[date.month - 1];
    return '${date.day} $m, ${date.year}';
  }

  String _vehicleTypeLabel(SuperadminRecentVehicle v) {
    final fromGetter = v.vehicleTypeName;
    if (fromGetter.trim().isNotEmpty) return fromGetter;
    final raw = v.raw;
    final vt = raw['vehicleType'];
    if (vt is Map) {
      final name = vt['name'] ?? vt['title'] ?? vt['type'] ?? vt['slug'];
      final s = _safeString(name, fallback: "");
      if (s.isNotEmpty) return s;
    }
    return "—";
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

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double hPadding =
        AdaptiveUtils.getHorizontalPadding(screenWidth) - 6; // 2-10
    final double vPadding =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 4; // 2-6
    final double baseFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double fontSize = AdaptiveUtils.isSmallScreen(screenWidth)
        ? baseFontSize - 1
        : baseFontSize + 2;
    final Color textColor = selected
        ? colorScheme.primary.withOpacity(0.7)
        : colorScheme.onSurface.withOpacity(0.6);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 90;
            final iconSize = isTight ? fontSize : fontSize + 1;
            final labelSize = isTight ? fontSize + 1 : fontSize + 2;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: textColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

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
                  "type": _vehicleTypeLabel(v),
                  "status": v.status.isNotEmpty ? v.status : "Active",
                  "time": _friendlyDateTime(v.time),
                  "timeRaw": v.time,
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
                  'name': t.fromUserName.isNotEmpty ? t.fromUserName : '—',
                  'value': t.valueText.isNotEmpty ? t.valueText : '—',
                  'status': _normalizedTransactionStatus(t.status),
                  'timeRaw': t.time,
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
                  'timeRaw': u.time,
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

  List<Map<String, dynamic>> _activitiesFor(String type) {
    final list = switch (type) {
      "Vehicles" => vehicleActivities,
      "Transactions" => transactionActivities,
      _ => userActivities,
    };
    if (list.isNotEmpty) return list;
    return switch (type) {
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

  Widget buildActivityItem(String type, Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double mainFontSize = 14 * scale;
    final double subFontSize = 12 * scale;
    final double badgeFontSize = 11 * scale;
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(
      screenWidth,
    ); // 6-10

    final statusColors = getStatusColors(context);

    Widget avatar;
    Widget content;
    Widget right = const SizedBox.shrink();

    switch (type) {
      case "Vehicles":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.1,
          backgroundColor:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant,
          child: Icon(
            Icons.directions_car_outlined,
            size: 18 * scale,
            color: colorScheme.primary,
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _capitalizeFirst(_safeString(activity["name"], fallback: "")),
              maxLines: 2,
              style: GoogleFonts.roboto(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
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
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _formatDate(activity["timeRaw"]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: subFontSize,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
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
                  fontSize: badgeFontSize,
                  fontWeight: FontWeight.w600,
                  height: 14 / 11,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _relativeTime(activity["timeRaw"]),
              style: GoogleFonts.roboto(
                fontSize: subFontSize,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
          ],
        );

      case "Transactions":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.1,
          backgroundColor:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant,
          child: Icon(
            Icons.credit_card,
            size: 18 * scale,
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
                height: 20 / 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDateOnly(activity["timeRaw"]),
              style: GoogleFonts.roboto(
                fontSize: subFontSize,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
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
                height: 20 / 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _safeString(activity["status"], fallback: ""),
              style: GoogleFonts.roboto(
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w600,
                height: 14 / 11,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
          ],
        );
        break;

      default: // Users
        final name = _safeString(activity["name"], fallback: "—");
        final initials = name
            .split(" ")
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join();

        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.1,
          backgroundColor:
              Theme.of(context).brightness == Brightness.light
                  ? Colors.grey[200]
                  : colorScheme.surfaceVariant,
          child: Icon(
            Icons.group,
            size: 18 * scale,
            color: colorScheme.primary,
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 2,
              style: GoogleFonts.roboto(
                fontSize: mainFontSize,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              _safeString(activity["email"], fallback: ""),
              style: GoogleFonts.roboto(
                fontSize: subFontSize,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
            ),
          ],
        );

        right = Text(
          _formatDateOnly(activity["timeRaw"]),
          style: GoogleFonts.roboto(
            fontSize: subFontSize,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: colorScheme.onSurface.withOpacity(0.54),
          ),
        );
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.12),
          ),
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
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double linkFontSize = 14 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActivitySection(
          context,
          title: 'Recent Vehicles',
          loading: _loadingRecentVehicles,
          activities: _activitiesFor('Vehicles'),
          padding: padding,
          linkFontSize: linkFontSize,
          screenWidth: screenWidth,
        ),
        SizedBox(height: padding),
        _buildActivitySection(
          context,
          title: 'Transactions',
          loading: _loadingRecentTransactions,
          activities: _activitiesFor('Transactions'),
          padding: padding,
          linkFontSize: linkFontSize,
          screenWidth: screenWidth,
        ),
        SizedBox(height: padding),
        _buildActivitySection(
          context,
          title: 'Users',
          loading: _loadingRecentUsers,
          activities: _activitiesFor('Users'),
          padding: padding,
          linkFontSize: linkFontSize,
          screenWidth: screenWidth,
        ),
      ],
    );
  }

  Widget _buildActivitySection(
    BuildContext context, {
    required String title,
    required bool loading,
    required List<Map<String, dynamic>> activities,
    required double padding,
    required double linkFontSize,
    required double screenWidth,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (title) {
      'Transactions' => Icons.credit_card,
      'Users' => Icons.group,
      _ => Icons.directions_car,
    };
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[100]
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: GoogleFonts.roboto(
                          fontSize: 18 * scale,
                          height: 24 / 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                        if (loading)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child:
                                  AppShimmer(width: 14, height: 14, radius: 7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (title == 'Transactions')
                InkWell(
                  onTap: () => context.push('/superadmin/payments'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "View all",
                          style: GoogleFonts.roboto(
                            fontSize: linkFontSize,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: linkFontSize + 2,
                          color: colorScheme.primary.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: padding - 2),
          SizedBox(
            height: 320,
            child: loading
                ? ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, __) =>
                        _buildActivitySkeletonItem(screenWidth),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: activities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) =>
                        buildActivityItem(title, activities[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
