// components/admin/documents_tab/documents_tab.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:fleet_stack/components/admin/documents_tab/widget/add_document.dart';
import 'package:fleet_stack/components/admin/documents_tab/widget/file_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';

class DocumentsTab extends StatelessWidget {
  const DocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double FontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 2;
    double usedStorage = 2.62; // in GB
    double totalStorage = 5;    // in GB
    int totalDocs = 411;        // Total documents

    // List of file maps
    final List<Map<String, dynamic>> files = [
      {
        "fileName": "Company PAN Certificate.pdf",
        "version": "v3",
        "fileSize": "340.41 KB",
        "type": "PAN Card",
        "tags": ["finance", "compliance"],
        "uploadedDate": "19 Nov 2025",
        "expiryDate": "15 Jan 2026",
        "status": "Valid · 45d",
      },
      {
        "fileName": "Driver Employment Contract – Aarav Sharma.pdf",
        "version": "v1",
        "fileSize": "1023.55 KB",
        "type": "Employment Contract",
        "tags": ["hr", "driver"],
        "uploadedDate": "28 Nov 2025",
        "expiryDate": "16 Dec 2025",
        "status": "Expiring · 15d",
      },
      {
        "fileName": "Vendor NDA (Traccar Integration).pdf",
        "version": "v2",
        "fileSize": "793.94 KB",
        "type": "NDA / Confidentiality Agreement",
        "tags": ["legal", "nda"],
        "uploadedDate": "29 Nov 2025",
        "expiryDate": "30 Nov 2025",
        "status": "Expired",
      },
      {
        "fileName": "Insurance Policy – HQ Servers.docx",
        "version": "v5",
        "fileSize": "520 KB",
        "type": "Insurance Policy",
        "tags": ["ops", "infra"],
        "uploadedDate": "01 Nov 2025",
        "expiryDate": "—",
        "status": "Valid",
      },
    ];

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
              // Top row: Admin Documents text + small circular + icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Admin Documents",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.7),
                          letterSpacing: 0.8,
                        ),
                      )
                    ],
                  ),
                  // Small circular + icon
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
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        
              const SizedBox(height: 24),
        
              // Health Status container with 3 icons
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
        
                    // Row with 3 icons and their numbers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "1",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "4",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "2",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
        
              // Storage Used container (full width)
        
        
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
          // Top: Storage used title
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
        
          // Middle row: Usage text + Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Usage text
              Text(
                "${usedStorage.toStringAsFixed(2)} / ${totalStorage.toStringAsFixed(0)} GB",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        
              // Pie chart
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
        
          // Bottom row: Total documents text + color indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total documents
              Text(
                "Total docs: $totalDocs",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
        
              // Color indicators
              Row(
                children: [
                  // Used
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
                  // Remaining
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
        )
            ],
          ),
        ),
        SizedBox(height: 24,),
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