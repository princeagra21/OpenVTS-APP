import 'package:fleet_stack/modules/superadmin/components/card/adoption_widget.dart';
import 'package:fleet_stack/modules/superadmin/components/card/fleet_card.dart';
import 'package:fleet_stack/modules/superadmin/components/card/vehicle_status_box.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_recent_vehicle.dart';
import 'package:fleet_stack/core/models/superadmin_recent_transaction.dart';
import 'package:fleet_stack/core/models/superadmin_recent_user.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/components/bottom_bar/custom_bottom_bar.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 10.0
            : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 28,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                FleetOverviewBox(),
                SizedBox(height: 24),
                AdoptionGrowthBox(),
                SizedBox(height: 24),
                VehicleStatusBox(),
                SizedBox(height: 24),
                _RecentVehiclesSection(),
                SizedBox(height: 24),
                _RecentTransactionsSection(),
                SizedBox(height: 24),
                _RecentUsersSection(),
                SizedBox(height: 24),
                SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: SuperAdminHomeAppBar(
              title: 'Dashboard',
              leadingIcon: Symbols.grid_view,
            ),
          ),
        ],
      ),
      // bottomNavigationBar: const CustomBottomBar(),
    );
  }
}

class _RecentVehiclesSection extends StatefulWidget {
  const _RecentVehiclesSection();

  @override
  State<_RecentVehiclesSection> createState() => _RecentVehiclesSectionState();
}

class _RecentVehiclesSectionState extends State<_RecentVehiclesSection> {
  final CancelToken _cancelToken = CancelToken();
  ApiClient? _api;
  SuperadminRepository? _repo;
  bool _loading = false;
  bool _errorShown = false;
  List<SuperadminRecentVehicle> _vehicles = const <SuperadminRecentVehicle>[];

  @override
  void initState() {
    super.initState();
    _loadRecentVehicles();
  }

  @override
  void dispose() {
    _cancelToken.cancel('RecentVehiclesSection disposed');
    super.dispose();
  }

  Future<void> _loadRecentVehicles() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.getRecentVehicles(cancelToken: _cancelToken);
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _loading = false;
            _errorShown = false;
            _vehicles = items;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to load recent vehicles.'
                  : "Couldn't load recent vehicles.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load recent vehicles.")),
      );
    }
  }

  String _safeString(Object? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _vehicleTypeLabel(SuperadminRecentVehicle v) {
    final fromGetter = v.vehicleTypeName;
    if (fromGetter.trim().isNotEmpty) return fromGetter;
    final raw = v.raw;
    final vt = raw['vehicleType'];
    if (vt is Map) {
      final name = vt['name'] ?? vt['title'] ?? vt['type'] ?? vt['slug'];
      final s = _safeString(name, fallback: '');
      if (s.isNotEmpty) return s;
    }
    return '—';
  }

  String _relativeTime(Object? value) {
    final raw = _safeString(value, fallback: '');
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
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

  String _formatDateOnly(Object? value) {
    final raw = _safeString(value, fallback: '');
    if (raw.isEmpty) return '';
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
    return '${date.day} $m ${date.year}';
  }

  String _timeLabel(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return _formatDateOnly(raw);
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays <= 7) return '${diff.inDays}d ago';
    return _formatDateOnly(raw);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;
    final pad = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double sectionTitleFs = 18 * scale;
    final double mainRowFs = 14 * scale;
    final double secondaryFs = 12 * scale;
    final double metaFs = 11 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Vehicles',
                style: AppUtils.headlineSmallBase.copyWith(
                  fontSize: sectionTitleFs,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push('/superadmin/vehicle'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.roboto(
                        fontSize: mainRowFs,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: mainRowFs + 2,
                      color: cs.primary.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            Column(
              children: const [
                AppShimmer(width: double.infinity, height: 64, radius: 12),
                SizedBox(height: 10),
                AppShimmer(width: double.infinity, height: 64, radius: 12),
              ],
            )
          else if (_vehicles.isEmpty)
            Text(
              'No recent vehicles',
              style: GoogleFonts.roboto(
                fontSize: secondaryFs,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          else
            Column(
              children: _vehicles.take(5).map((v) {
                final name = v.name.isNotEmpty ? v.name : '—';
                final type = _vehicleTypeLabel(v);
                final status = v.status.isNotEmpty ? v.status : 'Active';
                final timeText = _timeLabel(v.time);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness ==
                                  Brightness.light
                              ? Colors.grey.shade50
                              : cs.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.directions_car_outlined,
                          size: 18,
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: mainRowFs,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: secondaryFs,
                                height: 16 / 12,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.grey.shade50
                                      : cs.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.roboto(
                                fontSize: metaFs,
                                height: 14 / 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            timeText,
                            style: GoogleFonts.roboto(
                              fontSize: metaFs,
                              height: 14 / 11,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSection extends StatefulWidget {
  const _RecentTransactionsSection();

  @override
  State<_RecentTransactionsSection> createState() =>
      _RecentTransactionsSectionState();
}

class _RecentTransactionsSectionState extends State<_RecentTransactionsSection> {
  final CancelToken _cancelToken = CancelToken();
  ApiClient? _api;
  SuperadminRepository? _repo;
  bool _loading = false;
  bool _errorShown = false;
  List<SuperadminRecentTransaction> _transactions =
      const <SuperadminRecentTransaction>[];

  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  @override
  void dispose() {
    _cancelToken.cancel('RecentTransactionsSection disposed');
    super.dispose();
  }

  Future<void> _loadRecentTransactions() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.getRecentTransactions(
        limit: 5,
        cancelToken: _cancelToken,
      );
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _loading = false;
            _errorShown = false;
            _transactions = items;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to load recent transactions.'
                  : "Couldn't load recent transactions.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load recent transactions.")),
      );
    }
  }

  String _safeString(Object? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _relativeTime(Object? value) {
    final raw = _safeString(value, fallback: '');
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
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

  String _formatDateOnly(Object? value) {
    final raw = _safeString(value, fallback: '');
    if (raw.isEmpty) return '';
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
    return '${date.day} $m ${date.year}';
  }

  String _timeLabel(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return _formatDateOnly(raw);
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays <= 7) return '${diff.inDays}d ago';
    return _formatDateOnly(raw);
  }

  String _amountText(SuperadminRecentTransaction t) {
    final amount = _safeString(t.amount, fallback: '—');
    final currency = _safeString(t.currency, fallback: '');
    if (currency.isEmpty || currency == '—') return amount;
    return '$amount $currency';
  }

  (String text, IconData icon, Color color) _statusMeta(
    String raw,
    ColorScheme cs,
  ) {
    final status = raw.toUpperCase();
    if (status.contains('SUCCESS')) {
      return ('Success', Icons.check_circle, cs.primary);
    }
    if (status.contains('FAIL')) {
      return ('Failed', Icons.cancel, cs.error);
    }
    return ('Pending', Icons.schedule, cs.onSurface.withOpacity(0.6));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;
    final pad = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double sectionTitleFs = 18 * scale;
    final double mainRowFs = 14 * scale;
    final double secondaryFs = 12 * scale;
    final double metaFs = 11 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.credit_card,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Transactions',
                style: AppUtils.headlineSmallBase.copyWith(
                  fontSize: sectionTitleFs,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.push('/superadmin/payments'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.roboto(
                        fontSize: mainRowFs,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: cs.primary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: mainRowFs + 2,
                      color: cs.primary.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            Column(
              children: const [
                AppShimmer(width: double.infinity, height: 64, radius: 12),
                SizedBox(height: 10),
                AppShimmer(width: double.infinity, height: 64, radius: 12),
              ],
            )
          else if (_transactions.isEmpty)
            Text(
              'No recent transactions',
              style: GoogleFonts.roboto(
                fontSize: secondaryFs,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          else
            Column(
              children: _transactions.map<Widget>((t) {
                final name = t.fromUserName.isNotEmpty
                    ? t.fromUserName
                    : (t.actorName.isNotEmpty ? t.actorName : '—');
                final date = _timeLabel(t.time);
                final amount = _amountText(t);
                final (statusText, statusIcon, statusColor) =
                    _statusMeta(t.status, cs);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness ==
                                  Brightness.light
                              ? Colors.grey.shade50
                              : cs.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person_outline,
                          size: 18,
                          color: cs.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: mainRowFs,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: secondaryFs,
                                height: 16 / 12,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amount,
                            style: GoogleFonts.roboto(
                              fontSize: mainRowFs,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.grey.shade50
                                      : cs.surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: GoogleFonts.roboto(
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
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _RecentUsersSection extends StatefulWidget {
  const _RecentUsersSection();

  @override
  State<_RecentUsersSection> createState() => _RecentUsersSectionState();
}

class _RecentUsersSectionState extends State<_RecentUsersSection> {
  final CancelToken _cancelToken = CancelToken();
  ApiClient? _api;
  SuperadminRepository? _repo;
  bool _loading = false;
  bool _errorShown = false;
  List<SuperadminRecentUser> _users = const <SuperadminRecentUser>[];

  @override
  void initState() {
    super.initState();
    _loadRecentUsers();
  }

  @override
  void dispose() {
    _cancelToken.cancel('RecentUsersSection disposed');
    super.dispose();
  }

  Future<void> _loadRecentUsers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);
      final res = await _repo!.getRecentUsers(cancelToken: _cancelToken);
      if (!mounted) return;
      res.when(
        success: (items) {
          setState(() {
            _loading = false;
            _errorShown = false;
            _users = items;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to load recent users.'
                  : "Couldn't load recent users.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load recent users.")),
      );
    }
  }

  String _safeString(Object? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _formatDateOnly(Object? value) {
    final raw = _safeString(value, fallback: '');
    if (raw.isEmpty) return '';
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
    return '${date.day} $m ${date.year}';
  }

  String _timeLabel(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return _formatDateOnly(raw);
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays <= 7) return '${diff.inDays}d ago';
    return _formatDateOnly(raw);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;
    final pad = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double sectionTitleFs = 18 * scale;
    final double mainRowFs = 14 * scale;
    final double secondaryFs = 12 * scale;
    final double metaFs = 11 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[100]
                      : cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.group,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Users',
                style: AppUtils.headlineSmallBase.copyWith(
                  fontSize: sectionTitleFs,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            Column(
              children: const [
                AppShimmer(width: double.infinity, height: 64, radius: 12),
                SizedBox(height: 10),
                AppShimmer(width: double.infinity, height: 64, radius: 12),
              ],
            )
          else if (_users.isEmpty)
            Text(
              'No recent users',
              style: GoogleFonts.roboto(
                fontSize: secondaryFs,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.6),
              ),
            )
          else
            Column(
              children: _users.take(5).map<Widget>((u) {
                final name = u.name.isNotEmpty ? u.name : '—';
                final email = u.email.isNotEmpty ? u.email : '—';
                final date = _timeLabel(u.time);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name.trim()[0].toUpperCase() : 'U',
                          style: GoogleFonts.roboto(
                            fontSize: mainRowFs,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: mainRowFs,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: secondaryFs,
                                height: 16 / 12,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        date,
                        style: GoogleFonts.roboto(
                          fontSize: metaFs,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
