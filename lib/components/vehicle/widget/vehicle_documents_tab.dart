// components/vehicle/vehicle_documents_tab.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:fleet_stack/components/admin/documents_tab/widget/add_document.dart';
import 'package:fleet_stack/components/admin/documents_tab/widget/file_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class VehicleDocumentsTab extends StatelessWidget {
  const VehicleDocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);

    // Vehicle file data (must be declared before using it)
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

    // Health Status counts
    int validCount = files.where((f) => f['status'].toString().startsWith("Valid")).length;
    int expiringCount = files.where((f) => f['status'].toString().startsWith("Expiring")).length;
    int expiredCount = files.where((f) => f['status'].toString().startsWith("Expired")).length;

    final double usedStorage = 3.12; // GB
    final double totalStorage = 5; // GB
    final int totalDocs = files.length;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
              // Header row: Vehicle Documents + add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: Colors.black.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(
                        "Vehicle Documents",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.7),
                          letterSpacing: 0.8,
                        ),
                      )
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddDocumentScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 20, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Health Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 28),
                            const SizedBox(height: 4),
                            Text("$validCount",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                )),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 28),
                            const SizedBox(height: 4),
                            Text("$expiringCount",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                )),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 28),
                            const SizedBox(height: 4),
                            Text("$expiredCount",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Storage container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${usedStorage.toStringAsFixed(2)} / ${totalStorage.toStringAsFixed(0)} GB",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: usedStorage,
                                  color: Colors.black,
                                  radius: 20,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: totalStorage - usedStorage,
                                  color: Colors.black.withOpacity(0.1),
                                  radius: 20,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                        Row(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Used",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Remaining",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
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

        // File list
        ...files.map((file) => FileCard(
              fileName: file['fileName'],
              version: file['version'],
              fileSize: file['fileSize'],
              type: file['type'],
              tags: List<String>.from(file['tags']),
              uploadedDate: file['uploadedDate'],
              expiryDate: file['expiryDate'],
              status: file['status'],
            )).toList(),
      ],
    );
  }
}
