// components/vehicle/vehicle_documents_tab.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:fleet_stack/core/models/vehicle_document_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/documents_tab/widget/add_document.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/documents_tab/widget/file_card.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDocumentsTab extends StatefulWidget {
  final List<VehicleDocumentItem>? documents;
  final bool loading;

  const VehicleDocumentsTab({super.key, this.documents, this.loading = false});

  @override
  State<VehicleDocumentsTab> createState() => _VehicleDocumentsTabState();
}

class _VehicleDocumentsTabState extends State<VehicleDocumentsTab> {
  late List<Map<String, dynamic>> _files;

  @override
  void initState() {
    super.initState();
    _files = _resolvedFiles(widget.documents);
  }

  @override
  void didUpdateWidget(covariant VehicleDocumentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documents != widget.documents) {
      setState(() {
        _files = _resolvedFiles(widget.documents);
      });
    }
  }

  List<Map<String, dynamic>> _resolvedFiles(List<VehicleDocumentItem>? docs) {
    final items = docs ?? const <VehicleDocumentItem>[];
    final mapped = <Map<String, dynamic>>[];
    for (final d in items) {
      mapped.add({
        "fileName": d.fileName.isNotEmpty ? d.fileName : 'Untitled document',
        "version": "v1",
        "fileSize": _formatBytes(d.sizeBytes),
        "rawSizeBytes": d.sizeBytes,
        "type": d.type.isNotEmpty ? d.type : 'Document',
        "tags": const <String>[],
        "uploadedDate": _displayValue(d.uploadedAt),
        "expiryDate": _displayValue(d.expiresAt),
        "status": _normalizedStatus(d.status),
      });
    }
    return mapped;
  }

  String _displayValue(String? value) {
    if (value == null) return '—';
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String _normalizedStatus(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Unknown';
    return trimmed;
  }

  String _formatBytes(int sizeBytes) {
    if (sizeBytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = sizeBytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final decimals = size >= 100 ? 0 : 2;
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    final files = _files;

    int validCount = files
        .where((f) => f['status'].toString().startsWith("Valid"))
        .length;
    int expiringCount = files
        .where((f) => f['status'].toString().startsWith("Expiring"))
        .length;
    int expiredCount = files
        .where((f) => f['status'].toString().startsWith("Expired"))
        .length;

    final int totalBytes = files.fold<int>(
      0,
      (sum, file) => sum + ((file['rawSizeBytes'] as int?) ?? 0),
    );
    final double usedStorage = totalBytes / (1024 * 1024 * 1024);
    final double totalStorage = usedStorage;
    final int totalDocs = files.length;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(hp),
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
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 20,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Vehicle Documents",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.loading)
                        const AppShimmer(width: 12, height: 12, radius: 6),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddDocumentScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        size: 22,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Health Status",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusItem(
                          context,
                          Icons.check_circle,
                          Colors.green,
                          validCount,
                        ),
                        _statusItem(
                          context,
                          Icons.warning,
                          Colors.orange,
                          expiringCount,
                        ),
                        _statusItem(
                          context,
                          Icons.error,
                          Colors.red,
                          expiredCount,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Storage used",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${usedStorage.toStringAsFixed(2)} / ${totalStorage.toStringAsFixed(2)} GB",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 2,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: PieChart(
                            PieChartData(
                              sections: totalDocs == 0
                                  ? [
                                      PieChartSectionData(
                                        value: 1,
                                        color: colorScheme.surfaceVariant,
                                        radius: 18,
                                        showTitle: false,
                                      ),
                                    ]
                                  : [
                                      PieChartSectionData(
                                        value: usedStorage <= 0
                                            ? 1
                                            : usedStorage,
                                        color: colorScheme.primary,
                                        radius: 18,
                                        showTitle: false,
                                      ),
                                    ],
                              startDegreeOffset: -90,
                              sectionsSpace: 0,
                              centerSpaceRadius: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total docs: $totalDocs",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Row(
                          children: [
                            _legendItem(context, colorScheme.primary, "Used"),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (files.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No documents found',
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This vehicle has no uploaded documents in the current API response.',
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 1,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          )
        else
          ...files.map(
            (file) => Padding(
              padding: EdgeInsets.only(bottom: hp / 2),
              child: FileCard(
                fileName: file['fileName'],
                version: file['version'],
                fileSize: file['fileSize'],
                type: file['type'],
                tags: List<String>.from(file['tags']),
                uploadedDate: file['uploadedDate'],
                expiryDate: file['expiryDate'],
                status: file['status'],
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusItem(
    BuildContext context,
    IconData icon,
    Color color,
    int count,
  ) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          "$count",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    final width = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
