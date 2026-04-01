// components/vehicle/widget/vehicle_logs_tab.dart
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_log_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleLogsTab extends StatefulWidget {
  final String? imei;
  final String? fallbackVehicleId;

  const VehicleLogsTab({super.key, this.imei, this.fallbackVehicleId});

  @override
  State<VehicleLogsTab> createState() => _VehicleLogsTabState();
}

class _VehicleLogsTabState extends State<VehicleLogsTab> {
  List<DateTime?> _selectedRange = [
    DateTime.now().subtract(const Duration(days: 1)),
    DateTime.now(),
  ];
  final TextEditingController _searchController = TextEditingController();

  List<VehicleLogItem> _logs = const [];
  bool _loading = false;
  bool _errorShown = false;
  bool _missingImeiShown = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadLogs();
  }

  @override
  void dispose() {
    _token?.cancel('VehicleLogsTab disposed');
    _searchController.dispose();
    super.dispose();
  }

  String _isoDate(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<VehicleLogItem> get _filteredLogs {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _logs;
    return _logs.where((item) {
      final haystack =
          '${item.type} ${item.message} ${item.time} ${item.lat ?? ''} ${item.lng ?? ''} ${item.speed ?? ''}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  String get formattedRange {
    final start = _selectedRange[0];
    final end = _selectedRange[1];
    if (start == null || end == null) return "Select date range";
    return "${_formatDate(start)} – ${_formatDate(end)}";
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
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
      await _loadLogs();
    }
  }

  Future<void> _loadLogs() async {
    final imei = widget.imei?.trim() ?? '';
    if (imei.isEmpty) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (kDebugMode && !_missingImeiShown) {
        _missingImeiShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IMEI not available. Using fallback logs view.'),
          ),
        );
      }
      return;
    }

    _token?.cancel('Reload vehicle logs');
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

      final res = await _repo!.getVehicleLogs(
        imei,
        from: _isoDate(_selectedRange[0]),
        to: _isoDate(_selectedRange[1]),
        limit: 100,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          if (!mounted) return;
          setState(() {
            _logs = items;
            _loading = false;
            _errorShown = false;
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
              ? 'Not authorized to view logs.'
              : "Couldn't load logs. Showing current view.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load logs. Showing current view."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final double smallFs = fs - 2;
    final filtered = _filteredLogs;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(hp),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.list_alt_rounded,
                    size: fs + 4,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: hp / 2),
                  Text(
                    "Vehicle Logs",
                    style: GoogleFonts.roboto(
                      fontSize: fs + 2,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: _loading
                        ? const AppShimmer(width: 12, height: 12, radius: 6)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Generate and filter vehicle GPS logs",
                style: GoogleFonts.roboto(
                  fontSize: smallFs,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: hp,
                    vertical: hp * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: fs + 4,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formattedRange,
                        style: GoogleFonts.roboto(
                          fontSize: fs,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: GoogleFonts.roboto(
                  fontSize: fs,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "Search by IMEI, coordinate, attributes...",
                  hintStyle: GoogleFonts.roboto(
                    fontSize: fs,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: fs + 4,
                    color: colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant,
                  contentPadding: EdgeInsets.symmetric(vertical: hp * 0.9),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        Icons.file_download,
                        size: fs + 2,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        "Export CSV",
                        style: GoogleFonts.roboto(
                          fontSize: fs,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: hp * 0.9),
                        side: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(
                        Icons.email,
                        size: fs + 2,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        "Email",
                        style: GoogleFonts.roboto(
                          fontSize: fs,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: hp * 0.9),
                        side: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(hp * 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No Logs Found",
                        style: GoogleFonts.roboto(
                          fontSize: fs + 2,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Try adjusting your date range or search filter",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: smallFs,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map(
                  (log) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(hp),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.type.isNotEmpty ? log.type : 'Log',
                          style: GoogleFonts.roboto(
                            fontSize: fs,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          log.message.isNotEmpty ? log.message : 'No message',
                          style: GoogleFonts.roboto(
                            fontSize: smallFs,
                            color: colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          log.time.isNotEmpty ? log.time : '—',
                          style: GoogleFonts.roboto(
                            fontSize: smallFs,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
