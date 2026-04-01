import 'dart:io';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_vehicle_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminVehiclesTab extends StatefulWidget {
  final String adminId;

  const AdminVehiclesTab({super.key, required this.adminId});

  @override
  State<AdminVehiclesTab> createState() => _AdminVehiclesTabState();
}

class _AdminVehiclesTabState extends State<AdminVehiclesTab> {
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  ApiClient? _api;
  SuperadminRepository? _repo;

  List<AdminVehicleItem> _vehicles = const [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _searchController.addListener(() {
      final next = _searchController.text;
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
  }

  @override
  void dispose() {
    _token?.cancel('AdminVehiclesTab disposed');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    _token?.cancel('Reload admin vehicles');
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

      final res = await _repo!.getAdminVehicles(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          setState(() {
            _loading = false;
            _vehicles = items;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg = err is ApiException
              ? (err.message.isNotEmpty
                  ? err.message
                  : "Couldn't load vehicles.")
              : "Couldn't load vehicles.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load vehicles.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShimmer(
        width: double.infinity,
        height: 320,
        radius: 12,
      );
    }
    final cs = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth) + 4;
    final double fs = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double scale = fs / 14;
    final double headerSize = 18 * scale;
    final double fsMain = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double spacing = 12;
    final double iconSize = 18;

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
          if (_loading)
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
                SizedBox(height: spacing),
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
                          padding: EdgeInsets.symmetric(
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
                              SizedBox(width: spacing / 2),
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
                        onTap: _loadVehicles,
                        borderRadius: BorderRadius.circular(12),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: Container(
                          padding: EdgeInsets.symmetric(
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
                              SizedBox(width: spacing / 2),
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
                          padding: EdgeInsets.symmetric(
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
                              SizedBox(width: spacing / 2),
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
          if (_loading)
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

  List<AdminVehicleItem> _filteredVehicles() {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _vehicles.where((v) {
      final name = v.name.toLowerCase();
      final type = v.type.toLowerCase();
      final imei = v.imei.toLowerCase();
      final sim = v.simNumber.toLowerCase();
      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          type.contains(query) ||
          imei.contains(query) ||
          sim.contains(query);
      if (!matchesQuery) return false;
      if (_selectedFilter == 'Active') return v.isActive;
      if (_selectedFilter == 'Inactive') return !v.isActive;
      return true;
    });
    return filtered.toList();
  }

  String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final cleaned = value.replaceAll('"', '""');
    return needsQuote ? '"$cleaned"' : cleaned;
  }

  Future<void> _exportCsv(List<AdminVehicleItem> items) async {
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
        v.name,
        v.type,
        v.imei,
        v.simNumber,
        v.status,
        v.updatedAt,
      ]);
    }

    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }

    final filename =
        'admin_vehicles_${widget.adminId}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsString(buffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported CSV: ${file.path}')),
    );
  }

  void _showExportOptions(List<AdminVehicleItem> items) {
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

  Future<void> _exportPdf(List<AdminVehicleItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicles to export.')),
      );
      return;
    }
    final lines = <String>[
      'Admin Vehicles (${items.length})',
      'Admin ID: ${widget.adminId}',
      '',
      'ID | Name | Type | IMEI | SIM | Status | Created At',
    ];
    for (final v in items) {
      lines.add(
        '${v.id} | ${v.name} | ${v.type} | ${v.imei} | ${v.simNumber} | ${v.status} | ${v.updatedAt}',
      );
    }
    final pdf = _simplePdf(lines);
    final filename =
        'admin_vehicles_${widget.adminId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
    objects.add('4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
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

  Widget _vehicleRow(BuildContext context, AdminVehicleItem v) {
    final cs = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final String name = v.name.isNotEmpty ? v.name : '—';
    final String type = v.type.isNotEmpty ? v.type : '—';
    final imei = v.imei.isNotEmpty ? v.imei : '—';
    final sim = v.simNumber.isNotEmpty ? v.simNumber : '—';
    final tz = v.raw['gmtOffset']?.toString().isNotEmpty == true
        ? v.raw['gmtOffset'].toString()
        : '—';
    final expiry = _expiryText(v.raw['primaryExpiry']?.toString() ?? '');
    final created = _formatDateTime(v.raw['createdAt']?.toString() ?? '');

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
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: labelSize,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withOpacity(0.7),
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
                    title: 'Device Info',
                    lines: [
                      'IMEI: $imei',
                      'SIM: $sim',
                    ],
                  ),
                  _infoCard(
                    context,
                    width: cardWidth,
                    title: 'Timezone',
                    lines: [tz],
                  ),
                  _infoCard(
                    context,
                    width: cardWidth,
                    title: 'Expiry',
                    lines: [expiry],
                  ),
                  _infoCard(
                    context,
                    width: cardWidth,
                    title: 'Created',
                    lines: created.isEmpty ? ['—'] : created.split('\n'),
                  ),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 1;
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

  String _expiryText(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '—';
    final now = DateTime.now();
    if (dt.isBefore(now)) return 'Expired';
    final months = (dt.year - now.year) * 12 + dt.month - now.month;
    final m = months <= 0 ? 1 : months;
    return 'Expires in $m month(s)';
  }

  String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toLocal();
    final month = _monthName(local.month);
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year\\n$hour:$minute $amPm';
  }

  String _monthName(int m) {
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
    if (m < 1 || m > 12) return '';
    return months[m - 1];
  }
}
