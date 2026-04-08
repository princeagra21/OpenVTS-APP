import 'dart:io';

import 'package:fleet_stack/core/models/admin_vehicle_list_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserVehiclesTab extends StatefulWidget {
  final List<AdminVehicleListItem> items;
  final bool loading;

  const AdminUserVehiclesTab({
    super.key,
    required this.items,
    required this.loading,
  });

  @override
  State<AdminUserVehiclesTab> createState() => _AdminUserVehiclesTabState();
}

class _AdminUserVehiclesTabState extends State<AdminUserVehiclesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  late List<AdminVehicleListItem> _vehicles;

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
          Text(
            'Admin Vehicles',
            style: GoogleFonts.roboto(
              fontSize: headerSize,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
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
    final sim = (v.raw['simNumber']?.toString().isNotEmpty == true)
        ? v.raw['simNumber'].toString()
        : '—';
    final vin = v.vin.isNotEmpty ? v.vin : '—';

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  // Expiry/Created removed (not provided by admin vehicles API).
                ],
              );
            },
          ),
        ],
      ),
    );
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
      'Type',
      'IMEI',
      'SIM',
      'Status',
      'Created At',
    ];
    final rows = <List<String>>[];
    for (final v in items) {
      rows.add([
        v.id,
        v.nameModel,
        _vehicleType(v),
        v.imei,
        v.raw['simNumber']?.toString() ?? '',
        v.statusLabel,
        v.raw['createdAt']?.toString() ?? '',
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'admin_user_vehicles_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported CSV: ${file.path}')),
    );
  }

  Future<void> _exportPdf(List<AdminVehicleListItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicles to export.')),
      );
      return;
    }
    final lines = <String>[
      'Admin Vehicles (${items.length})',
      '',
      'ID | Name | Type | IMEI | SIM | Status | Created At',
    ];
    for (final v in items) {
      lines.add(
        '${v.id} | ${v.nameModel} | ${_vehicleType(v)} | ${v.imei} | ${v.raw['simNumber']?.toString() ?? ''} | ${v.statusLabel} | ${v.raw['createdAt']?.toString() ?? ''}',
      );
    }
    final pdf = _simplePdf(lines);
    final filename =
        'admin_user_vehicles_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsBytes(pdf);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported PDF: ${file.path}')),
    );
  }

  List<int> _simplePdf(List<String> lines) {
    String esc(String s) =>
        s.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');

    final text = StringBuffer();
    text.writeln('BT');
    text.writeln('/F1 12 Tf');
    text.writeln('50 780 Td');
    for (int i = 0; i < lines.length; i++) {
      final line = esc(lines[i]);
      if (i == 0) {
        text.writeln('($line) Tj');
      } else {
        text.writeln('0 -16 Td');
        text.writeln('($line) Tj');
      }
    }
    text.writeln('ET');
    final content = text.toString();

    final objects = <String>[];
    objects.add('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
    objects.add('2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj');
    objects.add(
      '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj',
    );
    objects
        .add('4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
    objects.add(
      '5 0 obj << /Length ${content.length} >> stream\n$content\nendstream endobj',
    );

    final xref = <int>[];
    final buffer = StringBuffer();
    buffer.writeln('%PDF-1.4');
    int offset = buffer.length;
    for (final obj in objects) {
      xref.add(offset);
      buffer.writeln(obj);
      offset = buffer.length;
    }
    final xrefStart = offset;
    buffer.writeln('xref');
    buffer.writeln('0 ${objects.length + 1}');
    buffer.writeln('0000000000 65535 f ');
    for (final off in xref) {
      buffer.writeln(off.toString().padLeft(10, '0') + ' 00000 n ');
    }
    buffer.writeln('trailer << /Size ${objects.length + 1} /Root 1 0 R >>');
    buffer.writeln('startxref');
    buffer.writeln(xrefStart);
    buffer.writeln('%%EOF');
    return buffer.toString().codeUnits;
  }

  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }
}
