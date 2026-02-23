// components/admin/documents_tab/documents_tab.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_document_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/documents_tab/widget/add_document.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/documents_tab/widget/file_card.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentsTab extends StatefulWidget {
  final String adminId;

  const DocumentsTab({super.key, required this.adminId});

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  final List<Map<String, dynamic>> _files = <Map<String, dynamic>>[];
  bool _loading = false;
  bool _errorShown = false;
  bool _loadFailed = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  double _usedStorageGb = 0;
  final double _totalStorageGb = 5;
  int _totalDocs = 0;
  int _validCount = 0;
  int _warningCount = 0;
  int _expiredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  @override
  void dispose() {
    _token?.cancel('DocumentsTab disposed');
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  Map<String, dynamic> _mapDoc(AdminDocumentItem d) {
    return <String, dynamic>{
      "fileName": d.title.isNotEmpty ? d.title : '—',
      "version": "",
      "fileSize": d.sizeBytes == 0 ? '' : _formatBytes(d.sizeBytes),
      "type": d.type,
      "tags": d.tags,
      "uploadedDate": d.uploadedAt,
      "expiryDate": d.expiresAt.isNotEmpty ? d.expiresAt : '—',
      "status": d.status,
      "_valid": d.isValid,
      "_warning": d.isWarning,
      "_expired": d.isExpired,
      "_sizeBytes": d.sizeBytes,
    };
  }

  Future<void> _loadDocs() async {
    _token?.cancel('Reload admin documents');
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

      final res = await _repo!.getAdminDocuments(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (docs) {
          if (!mounted) return;
          final mapped = docs.map(_mapDoc).toList();

          int valid = 0;
          int warning = 0;
          int expired = 0;
          int bytes = 0;
          for (final f in mapped) {
            bytes += (f['_sizeBytes'] as int?) ?? 0;
            if (f['_expired'] == true) {
              expired += 1;
            } else if (f['_warning'] == true) {
              warning += 1;
            } else if (f['_valid'] == true) {
              valid += 1;
            }
          }

          setState(() {
            _loading = false;
            _errorShown = false;
            _loadFailed = false;
            _files
              ..clear()
              ..addAll(mapped);
            _totalDocs = mapped.length;
            _validCount = valid;
            _warningCount = warning;
            _expiredCount = expired;
            _usedStorageGb = bytes / (1024 * 1024 * 1024);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _loadFailed = true;
            _files.clear();
            _totalDocs = 0;
            _validCount = 0;
            _warningCount = 0;
            _expiredCount = 0;
            _usedStorageGb = 0;
          });
          if (_errorShown) return;
          _errorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view documents.'
              : "Couldn't load documents.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              action: SnackBarAction(label: 'Retry', onPressed: _loadDocs),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _files.clear();
        _totalDocs = 0;
        _validCount = 0;
        _warningCount = 0;
        _expiredCount = 0;
        _usedStorageGb = 0;
      });
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't load documents."),
          action: SnackBarAction(label: 'Retry', onPressed: _loadDocs),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);

    final showNoData = !_loading && _files.isEmpty;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(padding),
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
              // Top row: Admin Documents text + add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Admin Documents",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.7),
                                letterSpacing: 0.8,
                              ),
                            ),
                            if (_loading)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: AppShimmer(
                                    width: 64,
                                    height: 14,
                                    radius: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Add button
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
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Health Status container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 16),
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
                  children: [
                    Text(
                      "Health Status",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildHealthItem(
                          icon: Icons.check_circle,
                          color: Colors.green,
                          count: _validCount.toString(),
                          colorScheme: colorScheme,
                        ),
                        _buildHealthItem(
                          icon: Icons.warning,
                          color: Colors.orange,
                          count: _warningCount.toString(),
                          colorScheme: colorScheme,
                        ),
                        _buildHealthItem(
                          icon: Icons.error,
                          color: Colors.red,
                          count: _expiredCount.toString(),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Storage Used container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                      "Storage used",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${_usedStorageGb.toStringAsFixed(2)} / ${_totalStorageGb.toStringAsFixed(0)} GB",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _usedStorageGb,
                                  color: colorScheme.primary,
                                  radius: 20,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: (_totalStorageGb - _usedStorageGb)
                                      .clamp(0, _totalStorageGb),
                                  color: colorScheme.primary.withOpacity(0.1),
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
                          "Total docs: $_totalDocs",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.7),
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
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Used",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
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
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Remaining",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
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
        if (_loading)
          ...List<Widget>.generate(3, (_) => _buildFileSkeleton(colorScheme)),
        if (showNoData && !_loadFailed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No documents found.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ),
        if (showNoData && _loadFailed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Couldn't load documents.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
                TextButton(onPressed: _loadDocs, child: const Text('Retry')),
              ],
            ),
          ),
        if (!showNoData && !_loading)
          ..._files.map(
            (file) => FileCard(
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
      ],
    );
  }

  Widget _buildHealthItem({
    required IconData icon,
    required Color color,
    required String count,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFileSkeleton(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(width: 200, height: 16, radius: 8),
          SizedBox(height: 10),
          AppShimmer(width: 130, height: 14, radius: 8),
          SizedBox(height: 8),
          AppShimmer(width: double.infinity, height: 14, radius: 8),
          SizedBox(height: 8),
          AppShimmer(width: 170, height: 14, radius: 8),
        ],
      ),
    );
  }
}
