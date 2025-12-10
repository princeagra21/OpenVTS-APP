// components/vehicle/vehicle_documents_tab.dart
import 'package:fleet_stack/components/admin/documents_tab/widget/add_document.dart';
import 'package:fleet_stack/components/admin/documents_tab/widget/file_card.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDocumentsTab extends StatelessWidget {
  const VehicleDocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    final List<Map<String, dynamic>> files = [
      {
        "fileName": "Vendor NDA (Traccar Integration).pdf",
        "version": "v2",
        "fileSize": "793.94 KB",
        "type": "NDA / Confidentiality Agreement",
        "tags": ["legal", "nda"],
        "uploadedDate": "02 Dec 2025",
        "expiryDate": "03 Dec 2025",
        "status": "Expired",
      },
      {
        "fileName": "Driver Employment Contract – Aarav Sharma.pdf",
        "version": "v1",
        "fileSize": "1023.55 KB",
        "type": "Employment Contract",
        "tags": ["hr", "driver"],
        "uploadedDate": "01 Dec 2025",
        "expiryDate": "19 Dec 2025",
        "status": "Expiring · 15d",
      },
      {
        "fileName": "Company PAN Certificate.pdf",
        "version": "v3",
        "fileSize": "340.41 KB",
        "type": "PAN Card",
        "tags": ["finance", "compliance"],
        "uploadedDate": "22 Nov 2025",
        "expiryDate": "18 Jan 2026",
        "status": "Valid · 45d",
      },
      {
        "fileName": "Insurance Policy – HQ Servers.docx",
        "version": "v5",
        "fileSize": "520 KB",
        "type": "Insurance Policy",
        "tags": ["ops", "infra"],
        "uploadedDate": "04 Nov 2025",
        "expiryDate": "—",
        "status": "Valid",
      },
    ];

    int validCount = files.where((f) => f['status'].toString().startsWith("Valid")).length;
    int expiringCount = files.where((f) => f['status'].toString().startsWith("Expiring")).length;
    int expiredCount = files.where((f) => f['status'].toString().startsWith("Expired")).length;

    final double usedStorage = 3.12;
    final double totalStorage = 5;
    final int totalDocs = files.length;

    return Column(
      children: [
        // MAIN CARD
        Container(
          padding: EdgeInsets.all(hp),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER + ADD BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, size: 20, color: colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        "Vehicle Documents",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDocumentScreen())),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Icon(Icons.add, size: 22, color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // HEALTH STATUS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Text(
                      "Health Status",
                      style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width), fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statusItem(context, Icons.check_circle, Colors.green, validCount),
                        _statusItem(context, Icons.warning, Colors.orange, expiringCount),
                        _statusItem(context, Icons.error, Colors.red, expiredCount),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // STORAGE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Storage used", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width), fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.7))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${usedStorage.toStringAsFixed(2)} / ${totalStorage.toStringAsFixed(0)} GB", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(value: usedStorage, color: colorScheme.primary, radius: 18, showTitle: false),
                                PieChartSectionData(value: totalStorage - usedStorage, color: colorScheme.surfaceVariant, radius: 18, showTitle: false),
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
                        Text("Total docs: $totalDocs", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 2, color: colorScheme.onSurface.withOpacity(0.7))),
                        Row(
                          children: [
                            _legendItem(context, colorScheme.primary, "Used"),
                            const SizedBox(width: 16),
                            _legendItem(context, colorScheme.surfaceVariant, "Remaining"),
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

        // FILE LIST
        ...files.map((file) => Padding(
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
            )),
      ],
    );
  }

  Widget _statusItem(BuildContext context, IconData icon, Color color, int count) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text("$count", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    final width = MediaQuery.of(context).size.width;
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
      ],
    );
  }
}