import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_log_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_logs_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/screens/logs/log_details_screen.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md):
  // - GET /admin/logs/options
  // - GET /admin/logs/activity
  // - GET /admin/logs/events
  // Repository merges list rows and sorts by latest time.
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  List<AdminLogItem>? _logs;
  bool _loading = false;
  bool _errorShown = false;

  CancelToken? _loadToken;
  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminLogsRepository? _repo;

  AdminLogsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminLogsRepository(api: _apiClient!);
    return _repo!;
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  DateTime _safeParseDateTime(String dateStr) {
    final parsed = _parseLogDate(dateStr);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _parseLogDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final numeric = int.tryParse(value);
    if (numeric != null) {
      if (numeric > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          numeric,
          isUtc: true,
        ).toLocal();
      }
      if (numeric > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          numeric * 1000,
          isUtc: true,
        ).toLocal();
      }
    }

    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso.toLocal();

    final commaParts = value.split(',');
    if (commaParts.isNotEmpty) {
      final dateParts = commaParts.first.trim().split('/');
      if (dateParts.length == 3) {
        final d = int.tryParse(dateParts[0]);
        final m = int.tryParse(dateParts[1]);
        final y = int.tryParse(dateParts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d).toLocal();
        }
      }
    }

    return null;
  }

  String _compactRelativeTime(String? raw) {
    final date = _parseLogDate(raw);
    if (date == null) return '';

    final now = DateTime.now();
    var diff = now.difference(date);
    if (diff.isNegative) diff = Duration.zero;

    if (diff.inMinutes < 1) return '0m';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  String? _cleanValue(String? value, {bool hideUnknown = true}) {
    final out = (value ?? '').trim();
    if (out.isEmpty) return null;
    final lower = out.toLowerCase();
    if (lower == 'null' || lower == '-' || lower == '—') return null;
    if (hideUnknown && (lower == 'unknown' || lower == 'n/a')) return null;
    return out;
  }

  String? _userDisplay(AdminLogItem log) {
    final user = log.raw['user'];
    if (user is Map<String, dynamic>) {
      return _cleanValue(
        (user['name'] ?? user['username'] ?? user['uid'])?.toString(),
      );
    }
    if (user is Map) {
      final map = Map<String, dynamic>.from(user.cast());
      return _cleanValue(
        (map['name'] ?? map['username'] ?? map['uid'])?.toString(),
      );
    }
    return null;
  }

  String _toTitleWords(String raw) {
    final source = raw.trim();
    if (source.isEmpty) return '';
    final words = source
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) {
          final lower = w.toLowerCase();
          if (lower.length <= 1) return lower.toUpperCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .toList();
    return words.join(' ');
  }

  String _summaryLabel(AdminLogItem log) {
    final actionRaw = _cleanValue(log.raw['action']?.toString());
    final action = actionRaw == null ? null : _toTitleWords(actionRaw);
    final entity = _cleanValue(log.entity);
    final user = _userDisplay(log);

    if (entity != null && action != null) return '$entity • $action';
    if (user != null && action != null) return '$user • $action';
    if (action != null) return action;
    if (entity != null) return entity;
    if (user != null) return user;

    final type = _cleanValue(log.type);
    if (type != null) return type;
    return 'Activity';
  }

  Future<void> _loadLogs() async {
    _loadToken?.cancel('Reload logs');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getLogs(
      search: _searchController.text.trim(),
      level: selectedTab,
      limit: 100,
      cancelToken: token,
    );

    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _logs = items;
          _loading = false;
          _errorShown = false;
        });
      },
      failure: (err) {
        setState(() {
          _logs = const <AdminLogItem>[];
          _loading = false;
        });
        if (_isCancelled(err)) return;
        final message = err is ApiException
            ? err.message
            : "Couldn't load logs.";
        _showLoadErrorOnce(message);
      },
    );
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadLogs();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLogs();
  }

  @override
  void dispose() {
    _loadToken?.cancel('LogsScreen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final double iconSize = titleFs + 2;
    final double cardPadding = hp + 4;

    final allLogs = _logs ?? const <AdminLogItem>[];
    final searchQuery = _searchController.text.trim().toLowerCase();

    bool matchesTab(AdminLogItem log) {
      if (selectedTab == 'All') return true;
      if (selectedTab == 'Info') return log.normalizedSeverity == 'info';
      if (selectedTab == 'Warning') return log.normalizedSeverity == 'warning';
      if (selectedTab == 'Error') return log.normalizedSeverity == 'error';
      return true;
    }

    bool matchesSearch(AdminLogItem log) {
      if (searchQuery.isEmpty) return true;
      final fields = [
        log.time,
        log.type,
        log.entity,
        log.message,
        log.severity,
        log.channel,
      ];
      return fields.any((v) => v.toLowerCase().contains(searchQuery));
    }

    final filteredLogs =
        allLogs.where((log) => matchesTab(log) && matchesSearch(log)).toList()
          ..sort(
            (a, b) => _safeParseDateTime(
              b.time,
            ).compareTo(_safeParseDateTime(a.time)),
          );

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'Logs & Activity',
      actionIcons: const [CupertinoIcons.gear],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: hp * 3.5,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: bodyFs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Search time, type, entity, message...',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: bodyFs,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: iconSize,
                    color: colorScheme.primary.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  focusColor: colorScheme.primary,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: hp,
                    vertical: hp,
                  ),
                ),
              ),
            ),
            SizedBox(height: hp),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: ['All', 'Info', 'Warning', 'Error'].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: selectedTab == tab,
                  onTap: () {
                    if (selectedTab == tab) return;
                    setState(() => selectedTab = tab);
                    _loadLogs();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: hp),
            Text(
              'Showing ${filteredLogs.length} of ${allLogs.length} logs',
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
            SizedBox(height: spacing * 1.5),
            if (_loading)
              ...List.generate(
                3,
                (_) => _buildShimmerCard(
                  colorScheme,
                  width,
                  hp,
                  spacing,
                  cardPadding,
                ),
              )
            else if (filteredLogs.isEmpty)
              _buildEmptyStateCard(
                colorScheme: colorScheme,
                bodyFs: bodyFs,
                cardPadding: cardPadding,
                hp: hp,
              )
            else
              ...filteredLogs.map(
                (log) => _buildLogCard(
                  log: log,
                  colorScheme: colorScheme,
                  width: width,
                  spacing: spacing,
                  hp: hp,
                  bodyFs: bodyFs,
                  smallFs: smallFs,
                  iconSize: iconSize,
                  cardPadding: cardPadding,
                ),
              ),
            SizedBox(height: hp * 3),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required ColorScheme colorScheme,
    required double bodyFs,
    required double cardPadding,
    required double hp,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: hp),
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
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Text(
          'No logs found',
          style: GoogleFonts.inter(
            fontSize: bodyFs + 1,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(
    ColorScheme colorScheme,
    double width,
    double hp,
    double spacing,
    double cardPadding,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: hp),
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
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer(
              width: AdaptiveUtils.getAvatarSize(width),
              height: AdaptiveUtils.getAvatarSize(width),
              radius: AdaptiveUtils.getAvatarSize(width) / 2,
            ),
            SizedBox(width: spacing * 1.5),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(width: 180, height: 14, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: double.infinity, height: 13, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 120, height: 13, radius: 7),
                  SizedBox(height: 8),
                  AppShimmer(width: 90, height: 13, radius: 7),
                  SizedBox(height: 10),
                  AppShimmer(width: 170, height: 12, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard({
    required AdminLogItem log,
    required ColorScheme colorScheme,
    required double width,
    required double spacing,
    required double hp,
    required double bodyFs,
    required double smallFs,
    required double iconSize,
    required double cardPadding,
  }) {
    final severity = _cleanValue(log.normalizedSeverity, hideUnknown: false);
    final severityColor = getSeverityColor(severity ?? '');
    final summary = _summaryLabel(log);
    final relativeTime = _compactRelativeTime(log.time);
    final message = _cleanValue(log.message);
    final type = _cleanValue(log.type);
    final channel = _cleanValue(log.channel);
    final user = _userDisplay(log);
    final entityId = _cleanValue(log.raw['entityId']?.toString());

    final detailRows = <Widget>[];
    void addRow(Widget row) {
      if (detailRows.isNotEmpty) {
        detailRows.add(SizedBox(height: spacing / 2));
      }
      detailRows.add(row);
    }

    Widget buildInfoRow({required IconData icon, required String value}) {
      return Row(
        children: [
          Icon(
            icon,
            size: iconSize,
            color: colorScheme.primary.withOpacity(0.6),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: bodyFs,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (message != null) {
      addRow(buildInfoRow(icon: CupertinoIcons.text_bubble, value: message));
    }
    if (type != null) {
      addRow(buildInfoRow(icon: CupertinoIcons.tag, value: type));
    }
    if (user != null) {
      addRow(buildInfoRow(icon: CupertinoIcons.person, value: user));
    }
    if (channel != null) {
      addRow(buildInfoRow(icon: CupertinoIcons.device_laptop, value: channel));
    }
    if (entityId != null) {
      addRow(buildInfoRow(icon: CupertinoIcons.number, value: 'ID: $entityId'));
    }

    return Container(
      margin: EdgeInsets.only(bottom: hp),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          child: InkWell(
            borderRadius: BorderRadius.circular(25),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminLogDetailsScreen(log: log),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: AdaptiveUtils.getAvatarSize(width),
                        height: AdaptiveUtils.getAvatarSize(width),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.6),
                          ),
                        ),
                        child: Icon(
                          _getIconForType((type ?? '').toLowerCase()),
                          size: AdaptiveUtils.getFsAvatarFontSize(width),
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: spacing * 1.5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    summary,
                                    style: GoogleFonts.inter(
                                      fontSize: bodyFs + 2,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (relativeTime.isNotEmpty) ...[
                                  SizedBox(width: spacing),
                                  Text(
                                    relativeTime,
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs + 1,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.75,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (severity != null) ...[
                              SizedBox(height: spacing / 2),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing + 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: severityColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    severity.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: smallFs,
                                      fontWeight: FontWeight.w600,
                                      color: severityColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (detailRows.isNotEmpty) ...[
                              SizedBox(height: spacing / 2),
                              ...detailRows,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color getSeverityColor(String severity) {
    if (severity.isEmpty) return Colors.grey;
    if (severity == 'info') return Colors.blue;
    if (severity == 'warning') return Colors.orange;
    if (severity == 'error') return Colors.red;
    return Colors.grey;
  }

  IconData _getIconForType(String type) {
    if (type.contains('vehicle')) return CupertinoIcons.car;
    if (type.contains('user')) return CupertinoIcons.person;
    if (type.contains('driver')) return CupertinoIcons.person_alt_circle;
    return CupertinoIcons.info;
  }
}
