import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md):
  // - GET /admin/vehicles (query: search, status, page, limit)
  //   Key mapping: data.data.vehicles | data.vehicles | vehicles
  // - GET /admin/map-telemetry
  //   Key mapping: data.data | data.points | telemetry
  // - PATCH /admin/vehicles/:id  body: { isActive: bool }
  //   Used for switch toggle persistence.

  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();
  int _pageSize = 10;

  List<AdminVehicleListItem>? _items;
  bool _loading = false;
  bool _errorShown = false;

  CancelToken? _loadToken;

  Timer? _searchDebounce;

  ApiClient? _apiClient;
  AdminVehiclesRepository? _repo;

  AdminVehiclesRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminVehiclesRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadVehicles();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Vehicles screen disposed');
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadVehicles();
    });
  }

  String? _statusQueryForTab(String tab) {
    switch (tab) {
      case 'Running':
        return 'running';
      case 'Stopped':
        return 'stopped';
      default:
        return null;
    }
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

  Future<void> _loadVehicles() async {
    _loadToken?.cancel('Reload vehicles');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _repoOrCreate().getVehicles(
        search: _searchController.text.trim(),
        status: null,
        page: 1,
        limit: 100,
        cancelToken: token,
      );
      if (!mounted) return;

      await result.when(
        success: (items) async {
          var merged = items;
          if (items.isNotEmpty) {
            final telemetryResult = await _repoOrCreate().getTelemetry(
              cancelToken: token,
            );

            merged = telemetryResult.when(
              success: (points) => _mergeTelemetry(items, points),
              failure: (_) => items,
            );
          }

          if (kDebugMode) {
            debugPrint(
              '[Admin Vehicles] GET /admin/vehicles + /admin/map-telemetry '
              'status=2xx count=${merged.length}',
            );
          }

          if (!mounted) return;
          setState(() {
            _items = merged;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) async {
          if (!mounted) return;
          setState(() {
            _items = const <AdminVehicleListItem>[];
            _loading = false;
          });

          if (_isCancelled(err)) return;

          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load vehicles.'
              : "Couldn't load vehicles.";
          _showLoadErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const <AdminVehicleListItem>[];
        _loading = false;
      });
      _showLoadErrorOnce("Couldn't load vehicles.");
    }
  }

  List<AdminVehicleListItem> _mergeTelemetry(
    List<AdminVehicleListItem> source,
    List<MapVehiclePoint> points,
  ) {
    final byVehicleId = <String, MapVehiclePoint>{};
    final byImei = <String, MapVehiclePoint>{};

    for (final point in points) {
      final id = point.vehicleId.trim();
      if (id.isNotEmpty) {
        byVehicleId[id] = point;
      }
      final imei = point.imei.trim();
      if (imei.isNotEmpty) {
        byImei[imei] = point;
      }
    }

    return source.map((item) {
      final id = item.id.trim();
      final imei = item.imei.trim();
      final point = byVehicleId[id] ?? byImei[imei];
      if (point == null) return item;

      final raw = Map<String, dynamic>.from(item.raw);

      final mappedStatus = _normalizeTelemetryStatus(point.status);
      if (mappedStatus.isNotEmpty) {
        raw['motion'] = mappedStatus;
        raw['status'] = mappedStatus;
      }

      if (point.speed != null) {
        final speed = point.speed!;
        final text = speed == speed.roundToDouble()
            ? '${speed.toInt()} km/h'
            : '${speed.toStringAsFixed(1)} km/h';
        raw['speed'] = text;
      }

      final seen = point.updatedAt.trim();
      if (seen.isNotEmpty) {
        raw['lastActivityAt'] = seen;
        raw['last_activity'] = seen;
        raw['lastSeenAt'] = seen;
      }

      return AdminVehicleListItem.fromRaw(raw);
    }).toList();
  }

  String _normalizeTelemetryStatus(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return '';

    if (value.contains('run') || value.contains('move') || value == 'active') {
      return 'RUNNING';
    }
    if (value.contains('stop') ||
        value.contains('idle') ||
        value == 'inactive') {
      return 'STOPPED';
    }

    return raw.trim().toUpperCase();
  }

  List<AdminVehicleListItem> _applyLocalFilters(
    List<AdminVehicleListItem> source,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    bool tabMatch(AdminVehicleListItem item) {
      if (selectedTab == 'All') return true;
      final expected = selectedTab.toLowerCase();
      final actual = _statusFor(item).toLowerCase();
      if (expected == 'running') return actual.contains('running');
      if (expected == 'stopped') {
        return actual.contains('stop') || actual.contains('idle');
      }
      return true;
    }

    bool queryMatch(AdminVehicleListItem item) {
      if (query.isEmpty) return true;
      final fields = [
        item.nameModel,
        item.plateNumber,
        item.imei,
        item.vin,
        _statusFor(item),
        item.durationLabel,
        item.speedLabel,
        item.userDisplayName,
        item.primaryUserName,
        item.driverName,
        item.lastActivityAt,
        item.expiry,
      ];
      return fields.any((v) => v.toLowerCase().contains(query));
    }

    return source.where((v) => tabMatch(v) && queryMatch(v)).toList()..sort(
      (a, b) => _safeParseDateTime(
        b.lastActivityAt,
      ).compareTo(_safeParseDateTime(a.lastActivityAt)),
    );
  }

  DateTime _safeParseDateTime(String dateStr) {
    final text = dateStr.trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed;

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _tryParseAnyDate(String input) {
    final value = input.trim();
    if (value.isEmpty || value == '-') return null;
    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso;
    try {
      return DateFormat('dd MMM yyyy').parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  String _formatDateLabel(String raw) {
    final dt = _tryParseAnyDate(raw);
    if (dt == null) return _safe(raw);
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String _formatTimeLabel(String raw) {
    final dt = _tryParseAnyDate(raw);
    if (dt == null) return _safe(raw);
    return DateFormat('HH:mm').format(dt);
  }

  String _firstNonEmpty(List<String> candidates) {
    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed != '-') return trimmed;
    }
    return '';
  }

  String _simNumber(AdminVehicleListItem item) {
    final raw = item.raw;
    final device = raw['device'];
    final fromDevice = device is Map
        ? device['simNumber'] ??
            device['sim'] ??
            device['simNo'] ??
            device['sim_number']
        : null;
    return _safe(
      raw['simNumber'] ??
          raw['sim'] ??
          raw['simNo'] ??
          raw['sim_number'] ??
          fromDevice?.toString(),
    );
  }

  String _statusFor(AdminVehicleListItem item) {
    final raw = item.raw;
    final candidates = <String>[
      _safe(raw['status']?.toString()),
      _safe(raw['motion']?.toString()),
      _safe(raw['state']?.toString()),
      _safe(raw['liveStatus']?.toString()),
      _safe(item.statusLabel),
    ];
    final picked = _firstNonEmpty(candidates);
    return picked.isEmpty ? '-' : picked;
  }

  String _safe(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '-';
    if (trimmed.toLowerCase() == 'null') return '-';
    return trimmed;
  }

  void _showExportOptions(List<AdminVehicleListItem> items) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Vehicles',
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(
                          MediaQuery.of(context).size.width,
                        ) +
                        1,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('CSV'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportCsv(items);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('PDF'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _exportPdf(items);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportPdf(List<AdminVehicleListItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicles to export.')),
      );
      return;
    }

    final total = items.length;
    final active = items.where((v) => v.isActive == true).length;
    final inactive = total - active;
    final filterLabel = selectedTab;
    final generatedAt = DateTime.now();
    final generatedAtText =
        _formatDateTimeExport(generatedAt.toIso8601String());

    final doc = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    final labelStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final tableCellStyle = pw.TextStyle(fontSize: 7, color: PdfColors.black);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated from Fleet Stack Admin',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (_) => [
          _buildVehiclesPdfHeader(
            headerStyle: headerStyle,
            labelStyle: labelStyle,
            generatedAtText: generatedAtText,
            total: total,
            filterLabel: filterLabel,
          ),
          pw.SizedBox(height: 12),
          _buildVehiclesPdfSummary(
            total: total,
            active: active,
            inactive: inactive,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          pw.SizedBox(height: 16),
          pw.Text('Vehicle Details',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _buildVehiclesPdfTable(
            items: items,
            tableHeaderStyle: tableHeaderStyle,
            tableCellStyle: tableCellStyle,
          ),
        ],
      ),
    );

    final filename =
        'admin_vehicles_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final dir = await _resolveDownloadDir();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsBytes(await doc.save());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${file.path}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  pw.Widget _buildVehiclesPdfHeader({
    required pw.TextStyle headerStyle,
    required pw.TextStyle labelStyle,
    required String generatedAtText,
    required int total,
    required String filterLabel,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Vehicles Report', style: headerStyle),
              pw.SizedBox(height: 6),
              pw.Text('Report Type', style: labelStyle),
              pw.Text('Admin Vehicles Export',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Generated On', style: labelStyle),
              pw.Text(generatedAtText, style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Text('Tab Filter', style: labelStyle),
              pw.Text(filterLabel,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVehiclesPdfSummary({
    required int total,
    required int active,
    required int inactive,
    required pw.TextStyle labelStyle,
    required pw.TextStyle valueStyle,
  }) {
    pw.Widget card(String label, String value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: labelStyle),
              pw.SizedBox(height: 4),
              pw.Text(value, style: valueStyle.copyWith(color: color, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Overview', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            card('Total Vehicles', total.toString(), PdfColors.blue900),
            pw.SizedBox(width: 8),
            card('Active', active.toString(), PdfColors.green800),
            pw.SizedBox(width: 8),
            card('Inactive', inactive.toString(), PdfColors.red900),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildVehiclesPdfTable({
    required List<AdminVehicleListItem> items,
    required pw.TextStyle tableHeaderStyle,
    required pw.TextStyle tableCellStyle,
  }) {
    final headers = [
      'ID',
      'Name',
      'Plate',
      'Type',
      'IMEI',
      'SIM',
      'Status',
      'User',
      'Created',
    ];

    final data = items.map((v) {
      final raw = v.raw;
      final type = _safe(
        raw['vehicleType'] is Map
            ? (raw['vehicleType']['name'] ?? raw['vehicleType']['title'])
            : raw['vehicleType'] ??
                raw['type'] ??
                raw['vehicle_type'] ??
                raw['category'],
      );
      final sim = _simNumber(v);
      final status = _statusFor(v);
      final user = _safe(v.userDisplayName);
      final createdRaw = _firstNonEmpty([
        _safe(raw['createdAt']?.toString()),
        _safe(raw['created_at']?.toString()),
        _safe(raw['createdDate']?.toString()),
        _safe(raw['created']?.toString()),
      ]);
      final created = _formatDateLabel(createdRaw);

      return [
        v.id,
        v.nameModel.length > 15 ? '${v.nameModel.substring(0, 12)}...' : v.nameModel,
        v.plateNumber,
        type,
        v.imei,
        sim,
        status,
        user.length > 15 ? '${user.substring(0, 12)}...' : user,
        created,
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      headerStyle: tableHeaderStyle,
      cellStyle: tableCellStyle,
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(2.0),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.0),
        7: const pw.FlexColumnWidth(2.0),
        8: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  Future<void> _exportCsv(List<AdminVehicleListItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicles to export.')),
      );
      return;
    }
    final headers = [
      'ID',
      'Name',
      'Plate',
      'Type',
      'IMEI',
      'SIM Number',
      'Status',
      'Primary User',
      'Created At',
    ];
    final rows = <List<String>>[];
    for (final v in items) {
      final raw = v.raw;
      final type = _safe(
        raw['vehicleType'] is Map
            ? (raw['vehicleType']['name'] ?? raw['vehicleType']['title'])
            : raw['vehicleType'] ??
                raw['type'] ??
                raw['vehicle_type'] ??
                raw['category'],
      );
      rows.add([
        v.id,
        v.nameModel,
        v.plateNumber,
        type,
        v.imei,
        _simNumber(v),
        _statusFor(v),
        _safe(v.userDisplayName),
        _safe(raw['createdAt']?.toString()),
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'admin_vehicles_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final dir = await _resolveDownloadDir();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(buffer.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved: ${file.path}'),
        duration: const Duration(seconds: 5),
      ),
    );
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

  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }

  String _formatDateTimeExport(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsMain = 14 * scale;
    final double fsSecondary = 12 * scale;
    final double fsMeta = 11 * scale;
    final double iconSize = 16 * scale;
    final double cardPadding = hp + 4;

    final allItems = _items ?? const <AdminVehicleListItem>[];
    var filteredVehicles = _applyLocalFilters(allItems);
    final fullFilteredVehicles = filteredVehicles; // For export
    if (filteredVehicles.length > _pageSize) {
      filteredVehicles = filteredVehicles.take(_pageSize).toList();
    }

    final showNoData = !_loading && filteredVehicles.isEmpty;
    final showSkeletonCards = _loading;

    final topPadding = MediaQuery.of(context).padding.top;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(width)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(width)
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
              children: [
                // SUMMARY HEADER
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: hp * 0.9,
                    vertical: hp * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "All Vehicles",
                        style: GoogleFonts.roboto(
                          fontSize: fsSection,
                          height: 24 / 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        allItems.isEmpty
                            ? "No vehicles registered."
                            : "${allItems.length} vehicle(s) registered",
                        style: GoogleFonts.roboto(
                          fontSize: fsSecondary,
                          height: 16 / 12,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: spacing * 0.6),
                    ],
                  ),
                ),
                SizedBox(height: spacing * 1.5),

                // BROWSE VEHICLES
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: colorScheme.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Browse Vehicles",
                            style: GoogleFonts.roboto(
                              fontSize: fsSection,
                              height: 24 / 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final created =
                                  await context.push<bool>('/admin/vehicles/add');
                              if (created == true) {
                                _loadVehicles();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: hp,
                                vertical: spacing,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: iconSize,
                                    color: colorScheme.surface,
                                  ),
                                  SizedBox(width: spacing / 2),
                                  Text(
                                    "New",
                                    style: GoogleFonts.roboto(
                                      fontSize: fsMain,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),
                      Container(
                        height: hp * 3.5,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.roboto(
                            fontSize: fsMain,
                            height: 20 / 14,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search plate, type, user, IMEI...",
                            hintStyle: GoogleFonts.roboto(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontSize: fsSecondary,
                              height: 16 / 12,
                            ),
                            prefixIcon: Icon(
                              CupertinoIcons.search,
                              size: iconSize,
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
                      SizedBox(height: spacing),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double gap = spacing;
                          final double cellWidth =
                              (constraints.maxWidth - gap * 2) / 3;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              SizedBox(
                                width: cellWidth,
                                child: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (selectedTab == value) return;
                                    setState(() => selectedTab = value);
                                    _loadVehicles();
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: "All",
                                      child: Text('All'),
                                    ),
                                    PopupMenuItem(
                                      value: "Running",
                                      child: Text('Running'),
                                    ),
                                    PopupMenuItem(
                                      value: "Stopped",
                                      child: Text('Stopped'),
                                    ),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: hp,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: iconSize,
                                          color: colorScheme.onSurface,
                                        ),
                                        SizedBox(width: spacing / 2),
                                        Text(
                                          "Filter",
                                          style: GoogleFonts.roboto(
                                            fontSize: fsMain,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cellWidth,
                                child: PopupMenuButton<int>(
                                  onSelected: (value) {
                                    if (_pageSize == value) return;
                                    setState(() => _pageSize = value);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 10,
                                      child: Text('10'),
                                    ),
                                    PopupMenuItem(
                                      value: 25,
                                      child: Text('25'),
                                    ),
                                    PopupMenuItem(
                                      value: 50,
                                      child: Text('50'),
                                    ),
                                  ],
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: hp,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Records",
                                          style: GoogleFonts.roboto(
                                            fontSize: fsMain,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(width: spacing / 2),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: iconSize,
                                          color: colorScheme.onSurface,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: cellWidth,
                                child: InkWell(
                                  onTap: () => _showExportOptions(fullFilteredVehicles),
                                  borderRadius: BorderRadius.circular(12),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: hp,
                                      vertical: spacing,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload,
                                          size: iconSize,
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        SizedBox(width: spacing / 2),
                                        Text(
                                          "Export",
                                          style: GoogleFonts.roboto(
                                            fontSize: fsMain,
                                            height: 20 / 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
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
                    ],
                  ),
                ),
                SizedBox(height: spacing * 1.5),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: colorScheme.surfaceVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showNoData)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: hp),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No vehicles found',
                                style: GoogleFonts.roboto(
                                  fontSize: fsMain,
                                  height: 20 / 14,
                                  color:
                                      colorScheme.onSurface.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ask superadmin to assign vehicles.',
                                style: GoogleFonts.roboto(
                                  fontSize: fsSecondary,
                                  height: 16 / 12,
                                  color: colorScheme.onSurface
                                      .withOpacity(0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (showSkeletonCards)
                        ...List<Widget>.generate(
                          3,
                          (index) => _buildVehicleSkeletonCard(
                            index: index,
                            hp: hp,
                            spacing: spacing,
                            cardPadding: cardPadding,
                            width: width,
                            iconSize: iconSize,
                            bodyFs: fsMain,
                            smallFs: fsMeta,
                            colorScheme: colorScheme,
                          ),
                        ),
                      if (!showNoData && !showSkeletonCards)
                        ...filteredVehicles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final vehicle = entry.value;
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300 + index * 50),
                            curve: Curves.easeOut,
                            margin: EdgeInsets.only(bottom: hp),
                            child: _buildVehicleCard(
                              vehicle: vehicle,
                              colorScheme: colorScheme,
                              width: width,
                              spacing: spacing,
                              fsMain: fsMain,
                              fsSecondary: fsSecondary,
                              fsMeta: fsMeta,
                              iconSize: iconSize,
                              cardPadding: cardPadding,
                              hp: hp,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                SizedBox(height: hp * 3),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Vehicles',
              leadingIcon: Symbols.sync_alt,
              onClose: () => context.go('/admin/home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({
    required AdminVehicleListItem vehicle,
    required ColorScheme colorScheme,
    required double width,
    required double spacing,
    required double fsMain,
    required double fsSecondary,
    required double fsMeta,
    required double iconSize,
    required double cardPadding,
    required double hp,
  }) {
    final raw = vehicle.raw;
    final plate = _safe(vehicle.plateNumber);
    final name = _safe(vehicle.nameModel);
    final type = _safe(
      raw['vehicleType'] is Map
          ? (raw['vehicleType']['name'] ?? raw['vehicleType']['title'])
          : raw['vehicleType'] ??
              raw['type'] ??
              raw['vehicle_type'] ??
              raw['category'],
    );
    final imei = _safe(vehicle.imei);
    final simNumber = _simNumber(vehicle);
    final primaryName = _safe(vehicle.userDisplayName);
    final addedByName = _safe(
      raw['addedByName'] ??
          raw['createdByName'] ??
          raw['createdBy'] ??
          raw['addedBy'],
    );
    final status = _statusFor(vehicle);
    final isActive = vehicle.isActive == true;

    final createdRaw = _firstNonEmpty([
      _safe(raw['createdAt']?.toString()),
      _safe(raw['created_at']?.toString()),
      _safe(raw['createdDate']?.toString()),
      _safe(raw['created']?.toString()),
    ]);
    final createdDate = _formatDateLabel(createdRaw);
    final createdTime = _formatTimeLabel(createdRaw);
    final displayTitle = name == '-'
        ? (type.isNotEmpty && type != '-' ? type : 'Vehicle')
        : name;

    final vehicleId = vehicle.id.trim();

    return Container(
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
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: vehicleId.isEmpty
              ? null
              : () => context.push('/admin/vehicles/details/$vehicleId'),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40 * (fsMain / 14),
                      height: 40 * (fsMain / 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceVariant
                            : Colors.grey.shade50,
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.car_detailed,
                        size: 18 * (fsMain / 14),
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: spacing * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: GoogleFonts.roboto(
                              fontSize: fsMain,
                              height: 20 / 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            softWrap: true,
                          ),
                          SizedBox(height: spacing * 0.4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing + 4,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? (isActive
                                      ? colorScheme.primary.withOpacity(0.15)
                                      : colorScheme.error.withOpacity(0.15))
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              plate,
                              style: GoogleFonts.roboto(
                                fontSize: fsMeta,
                                height: 14 / 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? (isActive
                                        ? colorScheme.primary
                                        : colorScheme.error)
                                    : colorScheme.onSurface,
                              ),
                              softWrap: true,
                            ),
                          ),
                          SizedBox(height: spacing * 0.4),
                          Text(
                            type.isEmpty ? '-' : type,
                            style: GoogleFonts.roboto(
                              fontSize: fsSecondary,
                              height: 16 / 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing + 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? (isActive
                                ? colorScheme.primary.withOpacity(0.15)
                                : colorScheme.error.withOpacity(0.15))
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.check_circle : Icons.cancel,
                            size: fsMeta + 2,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? (isActive
                                        ? colorScheme.primary
                                        : colorScheme.error)
                                    : colorScheme.onSurface,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: GoogleFonts.roboto(
                              fontSize: fsMeta,
                              height: 14 / 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? (isActive
                                      ? colorScheme.primary
                                      : colorScheme.error)
                                  : colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing * 1.2,
                          vertical: spacing - 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Symbols.memory,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "IMEI",
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMeta,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              imei,
                              style: GoogleFonts.roboto(
                                fontSize: fsMain,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: hp * 0.5),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing * 1.2,
                          vertical: spacing - 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Symbols.memory,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "SIM",
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMeta,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              simNumber,
                              style: GoogleFonts.roboto(
                                fontSize: fsMain,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 0.8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing * 1.2,
                          vertical: spacing - 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Primary User",
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMeta,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              primaryName,
                              style: GoogleFonts.roboto(
                                fontSize: fsMain,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 0.8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing * 1.2,
                          vertical: spacing - 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_outlined,
                                  size: iconSize,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Created On",
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMeta,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  createdDate,
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMain,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  createdTime,
                                  style: GoogleFonts.roboto(
                                    fontSize: fsSecondary,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildVehicleSkeletonCard({
    required int index,
    required double hp,
    required double spacing,
    required double cardPadding,
    required double width,
    required double iconSize,
    required double bodyFs,
    required double smallFs,
    required ColorScheme colorScheme,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(
                  width: AdaptiveUtils.getAvatarSize(width),
                  height: AdaptiveUtils.getAvatarSize(width),
                  radius: AdaptiveUtils.getAvatarSize(width),
                ),
                SizedBox(width: spacing * 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppShimmer(
                              width: double.infinity,
                              height: bodyFs + 4,
                              radius: 4,
                            ),
                          ),
                          const SizedBox(width: 24),
                          AppShimmer(width: 60, height: smallFs + 6, radius: 12),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppShimmer(width: 100, height: smallFs + 6, radius: 12),
                      const SizedBox(height: 6),
                      AppShimmer(width: 80, height: smallFs, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppShimmer(width: double.infinity, height: 48, radius: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppShimmer(width: double.infinity, height: 48, radius: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppShimmer(width: double.infinity, height: 48, radius: 12),
            const SizedBox(height: 12),
            AppShimmer(width: double.infinity, height: 48, radius: 12),
          ],
        ),
      ),
    );
  }
}
