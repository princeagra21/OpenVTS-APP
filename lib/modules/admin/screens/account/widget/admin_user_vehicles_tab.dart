import 'dart:io';

import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AdminUserVehiclesTab extends StatefulWidget {
  final String userId;
  final List<AdminVehicleListItem> items;
  final bool loading;
  final Future<void> Function()? onAssigned;

  const AdminUserVehiclesTab({
    super.key,
    required this.userId,
    required this.items,
    required this.loading,
    this.onAssigned,
  });

  @override
  State<AdminUserVehiclesTab> createState() => _AdminUserVehiclesTabState();
}

class _AdminUserVehiclesTabState extends State<AdminUserVehiclesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  late List<AdminVehicleListItem> _vehicles;
  ApiClient? _apiClient;
  AdminUsersRepository? _repo;
  bool _assigning = false;

  AdminUsersRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminUsersRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _vehicles = widget.items;
    _searchController.addListener(() {
      final next = _searchController.text;
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
  }

  @override
  void didUpdateWidget(covariant AdminUserVehiclesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _vehicles = widget.items;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _openAssignVehicleSheet() async {
    final cs = Theme.of(context).colorScheme;
    final result = await _repoOrCreate().getUnlinkedVehicles(
      userId: widget.userId,
    );
    if (!mounted) return;

    result.when(
      success: (all) async {
        final existingIds = _vehicles.map((v) => v.id).toSet();
        final available = all.where((v) => !existingIds.contains(v.id)).toList();

        if (available.isEmpty) {
          _showNoAvailableWarning(cs);
          return;
        }

        final searchController = TextEditingController();
        String query = '';
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: cs.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            final width = MediaQuery.of(context).size.width;
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = available.where((v) {
                  final text =
                      '${v.nameModel} ${v.plateNumber} ${v.imei}'.toLowerCase();
                  return text.contains(query.toLowerCase());
                }).toList();
                return SafeArea(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Assign Vehicle',
                                  style: GoogleFonts.roboto(
                                    fontSize:
                                        AdaptiveUtils.getTitleFontSize(width) + 1,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: searchController,
                            onChanged: (value) =>
                                setSheetState(() => query = value),
                            decoration: InputDecoration(
                              hintText: 'Search available vehicles',
                              filled: true,
                              fillColor:
                                  cs.surfaceContainerHighest.withValues(alpha: 0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      'No available vehicle to assign.',
                                      style: GoogleFonts.roboto(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurface.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final v = filtered[index];
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () async {
                                          Navigator.of(context).pop();
                                          await _assignVehicle(v);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: cs.surface,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: cs.onSurface.withValues(
                                                alpha: 0.1,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v.nameModel,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: cs.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${v.plateNumber} · ${v.imei}',
                                                style: GoogleFonts.roboto(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: cs.onSurface.withValues(
                                                    alpha: 0.7,
                                                  ),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
        searchController.dispose();
      },
      failure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't load available vehicles.")),
        );
      },
    );
  }

  void _showNoAvailableWarning(ColorScheme cs) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                'No available vehicle to assign.',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _assignVehicle(AdminVehicleListItem vehicle) async {
    if (_assigning) return;
    setState(() => _assigning = true);
    final result = await _repoOrCreate().assignVehicleToUser(
      userId: widget.userId,
      vehicleId: vehicle.id,
    );
    if (!mounted) return;
    setState(() => _assigning = false);

    result.when(
      success: (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle assigned successfully.')),
        );
        if (widget.onAssigned != null) {
          await widget.onAssigned!.call();
        }
      },
      failure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't assign vehicle.")),
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
    final filterLabel = _selectedFilter;
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
                'Generated from Open VTS Admin',
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
          pw.SizedBox(height: 12),
          _buildVehiclesPdfTable(
            items: items,
            tableHeaderStyle: tableHeaderStyle,
            tableCellStyle: tableCellStyle,
          ),
        ],
      ),
    );

    final filename =
        'admin_user_vehicles_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
              pw.Text('User Vehicles Report', style: headerStyle),
              pw.SizedBox(height: 6),
              pw.Text('Report Type', style: labelStyle),
              pw.Text('Admin User Linked Vehicles',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Generated On', style: labelStyle),
              pw.Text(generatedAtText, style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Text('Filter', style: labelStyle),
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
      'Created At',
    ];

    final data = items.map((v) {
      final type = _vehicleType(v);
      final sim = (v.raw['simNumber'] ?? '').toString();
      final status = v.isActive == true ? 'ACTIVE' : 'INACTIVE';
      final created = (v.raw['createdAt'] ?? '').toString();

      return [
        v.id,
        v.nameModel.length > 15 ? '${v.nameModel.substring(0, 12)}...' : v.nameModel,
        v.plateNumber,
        type,
        v.imei,
        sim,
        status,
        created,
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Vehicle Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
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
            7: const pw.FlexColumnWidth(1.5),
          },
        ),
      ],
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
      'Created At',
    ];
    final rows = <List<String>>[];
    for (final v in items) {
      rows.add([
        v.id,
        v.nameModel,
        v.plateNumber,
        _vehicleType(v),
        v.imei,
        (v.raw['simNumber'] ?? '').toString(),
        v.isActive == true ? 'Active' : 'Inactive',
        (v.raw['createdAt'] ?? '').toString(),
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'admin_user_vehicles_export_${DateTime.now().millisecondsSinceEpoch}.csv';
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
    if (widget.loading) {
      return const AppShimmer(width: double.infinity, height: 320, radius: 12);
    }

    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth) + 4;
    final fs = AdaptiveUtils.getTitleFontSize(screenWidth);
    final scale = fs / 14;
    final headerSize = 18 * scale;
    final fsMain = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    const spacing = 12.0;
    const iconSize = 18.0;

    final filtered = _filteredVehicles();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin Vehicles',
                style: GoogleFonts.roboto(
                  fontSize: headerSize,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              InkWell(
                onTap: _assigning ? null : _openAssignVehicleSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.onSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _assigning
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.surface,
                              ),
                            )
                          : Icon(
                              Icons.add,
                              size: 16,
                              color: cs.surface,
                            ),
                      const SizedBox(width: 6),
                      Text(
                        'Assign',
                        style: GoogleFonts.roboto(
                          fontSize: fsMain,
                          fontWeight: FontWeight.w600,
                          color: cs.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (widget.loading)
            const AppShimmer(width: 140, height: 16, radius: 6)
          else
            Text(
              '${_vehicles.length} vehicle(s) registered',
              style: GoogleFonts.roboto(
                fontSize: AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search vehicles...',
                    hintStyle: GoogleFonts.roboto(
                      fontSize:
                          AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.onSurface.withOpacity(0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.onSurface.withOpacity(0.12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: cs.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (_selectedFilter == value) return;
                          setState(() => _selectedFilter = value);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'All',
                            child: Text('All'),
                          ),
                          PopupMenuItem(
                            value: 'Active',
                            child: Text('Active'),
                          ),
                          PopupMenuItem(
                            value: 'Inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: spacing,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune,
                                size: iconSize,
                                color: cs.onSurface,
                              ),
                              const SizedBox(width: spacing / 2),
                              Flexible(
                                child: Text(
                                  'Filter',
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMain,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!mounted) return;
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: spacing,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: iconSize,
                                color: cs.onSurface,
                              ),
                              const SizedBox(width: spacing / 2),
                              Flexible(
                                child: Text(
                                  'Refresh',
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMain,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showExportOptions(filtered),
                        borderRadius: BorderRadius.circular(12),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: spacing,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_outlined,
                                size: iconSize,
                                color: cs.onSurface,
                              ),
                              const SizedBox(width: spacing / 2),
                              Flexible(
                                child: Text(
                                  'Export',
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMain,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (widget.loading)
            const AppShimmer(width: double.infinity, height: 120, radius: 12)
          else if (filtered.isEmpty)
            Text(
              'No vehicles found.',
              style: GoogleFonts.roboto(
                fontSize: fsMain,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.7),
              ),
            )
          else
            Column(
              children: filtered
                  .map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _vehicleRow(context, v),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  List<AdminVehicleListItem> _filteredVehicles() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _vehicles.where((v) {
      final name = v.nameModel.toLowerCase();
      final type = _vehicleType(v).toLowerCase();
      final imei = v.imei.toLowerCase();
      final sim = (v.raw['simNumber'] ?? '').toString().toLowerCase();
      final plate = v.plateNumber.toLowerCase();
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          type.contains(query) ||
          imei.contains(query) ||
          sim.contains(query) ||
          plate.contains(query);
      if (!matchesQuery) return false;
      if (_selectedFilter == 'Active') return v.isActive == true;
      if (_selectedFilter == 'Inactive') return v.isActive == false;
      return true;
    });
    return filtered.toList();
  }

  String _vehicleType(AdminVehicleListItem v) {
    final raw = v.raw['vehicleType'];
    if (raw is Map && raw['name'] != null) {
      return raw['name'].toString();
    }
    return v.raw['type']?.toString() ?? v.raw['vehicleTypeName']?.toString() ?? '';
  }

  Widget _vehicleRow(BuildContext context, AdminVehicleListItem v) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final name = v.nameModel.isNotEmpty ? v.nameModel : '—';
    final plate = v.plateNumber.isNotEmpty ? v.plateNumber : '—';
    final imei = v.imei.isNotEmpty ? v.imei : '—';
    final vin = v.vin.isNotEmpty ? v.vin : '—';
    final secondaryExpiry = (v.raw['secondaryExpiry'] ?? '').toString();
    final expiry = secondaryExpiry.isNotEmpty ? secondaryExpiry : v.expiry;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? cs.surfaceVariant
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withOpacity(0.12)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.directions_bus_outlined,
                  size: 20,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      softWrap: true,
                      style: GoogleFonts.roboto(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? cs.surfaceVariant
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        plate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final cardWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _infoCard(
                    context,
                    width: cardWidth,
                    title: 'IMEI',
                    lines: [imei],
                  ),
                  _infoCard(
                    context,
                    width: cardWidth,
                    title: 'VIN',
                    lines: [vin],
                  ),
                  if (expiry.isNotEmpty)
                    _infoCard(
                      context,
                      width: cardWidth,
                      title: 'Expiry',
                      lines: [_formatDate(expiry)],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  Widget _infoCard(
    BuildContext context, {
    required double width,
    required String title,
    required List<String> lines,
  }) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final valueSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 1;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
