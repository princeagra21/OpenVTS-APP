// components/admin/documents_tab/documents_tab.dart
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
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentsTab extends StatefulWidget {
  final String adminId;

  const DocumentsTab({super.key, required this.adminId});

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _files = <Map<String, dynamic>>[];
  bool _loading = false;
  bool _errorShown = false;
  bool _loadFailed = false;
  CancelToken? _token;
  String _selectedTab = 'All';
  int _pageSize = 10;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  @override
  void dispose() {
    _token?.cancel('DocumentsTab disposed');
    _searchController.dispose();
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
    final rawFileName = (d.raw['fileName'] ?? d.raw['filename'] ?? '')
        .toString();
    final rawTitle = (d.raw['title'] ?? '').toString();
    return <String, dynamic>{
      "id": d.id,
      "docTypeId": d.raw['docTypeId'] ?? d.raw['doc_type_id'] ?? '',
      "fileName": rawFileName.trim().isNotEmpty
          ? rawFileName
          : (rawTitle.trim().isNotEmpty ? rawTitle : '—'),
      "version": "",
      "fileSize": d.sizeBytes == 0 ? '' : _formatBytes(d.sizeBytes),
      "type": d.type,
      "fileType": d.raw['fileType'] ?? '',
      "filePath": d.raw['filePath'] ?? d.raw['file_path'] ?? d.fileUrl,
      "title": rawTitle,
      "description": d.raw['description'] ?? '',
      "tags": d.tags,
      "uploadedDate": d.uploadedAt,
      "createdAt": d.uploadedAt,
      "expiryAt": d.expiresAt,
      "expiryDate": d.expiresAt.isNotEmpty ? d.expiresAt : '—',
      "status": d.status,
      "isVisible": d.raw['isVisible'] == true,
      "associateType": d.raw['associateType'] ?? '',
      "associateUserId": d.raw['associateUserId'] ?? '',
      "associateDriverId": d.raw['associateDriverId'] ?? '',
      "associateVehicleId": d.raw['associateVehicleId'] ?? '',
      "uploadedByType": d.raw['uploadedByType'] ?? '',
      "uploadedByUserId": d.raw['uploadedByUserId'] ?? '',
      "uploadedByDriverId": d.raw['uploadedByDriverId'] ?? '',
      "updatedAt": d.raw['updatedAt'] ?? '',
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

          setState(() {
            _loading = false;
            _errorShown = false;
            _loadFailed = false;
            _files
              ..clear()
              ..addAll(mapped);
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _loadFailed = true;
            _files.clear();
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
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsMain = 14 * scale;
    final double fsSecondary = 12 * scale;
    final double iconSize = 16 * scale;
    final double cardPadding = hp + 4;

    final query = _searchController.text.trim().toLowerCase();
    final filteredFiles = _files.where((file) {
      final matchesSearch =
          query.isEmpty ||
          file['fileName'].toString().toLowerCase().contains(query) ||
          file['type'].toString().toLowerCase().contains(query) ||
          file['status'].toString().toLowerCase().contains(query) ||
          file['expiryDate'].toString().toLowerCase().contains(query) ||
          file['uploadedDate'].toString().toLowerCase().contains(query) ||
          (file['tags'] as List<String>).any(
            (tag) => tag.toLowerCase().contains(query),
          );
      final matchesTab = switch (_selectedTab) {
        'All' => true,
        'Valid' => file['_valid'] == true,
        'Warning' => file['_warning'] == true,
        'Expired' => file['_expired'] == true,
        _ => true,
      };
      return matchesSearch && matchesTab;
    }).toList();
    final visibleFiles = filteredFiles.take(_pageSize).toList();
    final showEmpty = !_loading && filteredFiles.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.surfaceVariant),
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
                  Text(
                    'Browse Documents',
                    style: GoogleFonts.roboto(
                      fontSize: fsSection,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.roboto(
                    fontSize: fsMain,
                    height: 20 / 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search title, type, status, tag...",
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
                  final double cellWidth = (constraints.maxWidth - gap * 2) / 3;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: cellWidth,
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (_selectedTab == value) return;
                            setState(() => _selectedTab = value);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'All', child: Text('All')),
                            PopupMenuItem(value: 'Valid', child: Text('Valid')),
                            PopupMenuItem(
                              value: 'Warning',
                              child: Text('Warning'),
                            ),
                            PopupMenuItem(
                              value: 'Expired',
                              child: Text('Expired'),
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
                                color: colorScheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: iconSize,
                                  color: colorScheme.onSurface,
                                ),
                                SizedBox(width: spacing / 2),
                                Text(
                                  'Filter',
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
                            PopupMenuItem(value: 10, child: Text('10')),
                            PopupMenuItem(value: 25, child: Text('25')),
                            PopupMenuItem(value: 50, child: Text('50')),
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
                                color: colorScheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Records',
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMain,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
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
                          onTap: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddDocumentScreen(
                                  associateId: widget.adminId,
                                  associateType: 'USER',
                                ),
                              ),
                            );
                            if (updated == true) {
                              await _loadDocs();
                            }
                          },
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
                                color: colorScheme.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.upload_outlined,
                                  size: iconSize,
                                  color: colorScheme.onSurface,
                                ),
                                SizedBox(width: spacing / 2),
                                Text(
                                  'Upload',
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
              const SizedBox(height: 16),
              if (_loading)
                ...List<Widget>.generate(
                  3,
                  (_) => _buildFileSkeleton(colorScheme),
                ),
              if (showEmpty && !_loadFailed)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.surfaceVariant),
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
                        'No documents found',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upload a document to see it listed here.',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          height: 1.45,
                          color: colorScheme.onSurface.withOpacity(0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              if (showEmpty && _loadFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Couldn't load documents.",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadDocs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (!showEmpty && !_loading)
                ...visibleFiles.map(
                  (file) => FileCard(document: file, onChanged: _loadDocs),
                ),
            ],
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
