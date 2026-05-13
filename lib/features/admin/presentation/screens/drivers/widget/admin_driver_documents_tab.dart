import 'package:open_vts/features/admin/presentation/controllers/admin_driver_detail_controller.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_feedback.dart';
import 'package:open_vts/features/documents/presentation/screens/document_form_screen.dart';
import 'package:open_vts/features/admin/presentation/screens/account/widget/documents/file_card.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_driver_providers.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AdminDriverDocumentsTab extends ConsumerStatefulWidget {
  final String driverId;

  const AdminDriverDocumentsTab({super.key, required this.driverId});

  @override
  ConsumerState<AdminDriverDocumentsTab> createState() =>
      _AdminDriverDocumentsTabState();
}

class _AdminDriverDocumentsTabState extends ConsumerState<AdminDriverDocumentsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All';
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDocs);
  }

  @override
  void dispose() {
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

  Map<String, Object?> _mapDoc(AdminDocumentItem d) {
    final fileName = d.title.trim().isNotEmpty ? d.title.trim() : '—';
    return <String, Object?>{
      'id': d.id,
      'docTypeId': '',
      'fileName': fileName,
      'version': '',
      'fileSize': d.sizeBytes == 0 ? '' : _formatBytes(d.sizeBytes),
      'type': d.type,
      'fileType': '',
      'filePath': d.fileUrl,
      'title': d.title,
      'description': '',
      'tags': d.tags,
      'uploadedDate': d.uploadedAt,
      'createdAt': d.uploadedAt,
      'expiryAt': d.expiresAt,
      'expiryDate': d.expiresAt.isNotEmpty ? d.expiresAt : '—',
      'status': d.status,
      'isVisible': true,
      'associateType': '',
      'associateUserId': '',
      'associateDriverId': widget.driverId,
      'associateVehicleId': '',
      'uploadedByType': '',
      'uploadedByUserId': '',
      'uploadedByDriverId': '',
      'updatedAt': '',
      '_valid': d.isValid,
      '_warning': d.isWarning,
      '_expired': d.isExpired,
      '_sizeBytes': d.sizeBytes,
    };
  }


  Future<void> _loadDocs() async {
    await ref
        .read(adminDriverDetailControllerProvider(widget.driverId).notifier)
        .loadDocuments();
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

    final controllerProvider = adminDriverDetailControllerProvider(widget.driverId);
    final detailState = ref.watch(controllerProvider);
    ref.listen(controllerProvider.select((value) => value.effect), (previous, next) {
      if (next == null || !next.isError) return;
      OpenVtsFeedback.error(
        context,
        next.message,
        actionLabel: 'Retry',
        onAction: _loadDocs,
      );
      ref.read(controllerProvider.notifier).clearEffect();
    });

    final files = detailState.documents.map(_mapDoc).toList();
    final loading = detailState.isLoadingDocuments;
    final loadFailed = !loading && detailState.errorMessage != null && files.isEmpty;

    final query = _searchController.text.trim().toLowerCase();
    final filteredFiles = files.where((file) {
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
    final showEmpty = !loading && filteredFiles.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.surfaceContainerHighest),
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
                'Browse Documents',
                style: AppFonts.roboto(
                  fontSize: fsSection,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
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
                  onChanged: (_) => updateLocalUiState(this, () {}),
                  style: AppFonts.roboto(
                    fontSize: fsMain,
                    height: 20 / 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search title, type, status, tag...",
                    hintStyle: AppFonts.roboto(
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
                      _filterButton(
                        context,
                        cellWidth,
                        hp,
                        spacing,
                        iconSize,
                        fsMain,
                        colorScheme,
                      ),
                      _recordsButton(
                        context,
                        cellWidth,
                        hp,
                        spacing,
                        iconSize,
                        fsMain,
                        colorScheme,
                      ),
                      _uploadButton(
                        context,
                        cellWidth,
                        hp,
                        spacing,
                        iconSize,
                        fsMain,
                        colorScheme,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (loading)
                ...List<Widget>.generate(
                  3,
                  (_) => _buildFileSkeleton(colorScheme),
                ),
              if (showEmpty && !loadFailed) _emptyState(colorScheme),
              if (showEmpty && loadFailed) _errorState(colorScheme),
              if (!showEmpty && !loading)
                ...visibleFiles.map(
                  (file) => FileCard(document: file.cast(), onChanged: _loadDocs),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterButton(
    BuildContext context,
    double width,
    double hp,
    double spacing,
    double iconSize,
    double fs,
    ColorScheme cs,
  ) {
    return SizedBox(
      width: width,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          if (_selectedTab != value) updateLocalUiState(this, () => _selectedTab = value);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'All', child: Text('All')),
          PopupMenuItem(value: 'Valid', child: Text('Valid')),
          PopupMenuItem(value: 'Warning', child: Text('Warning')),
          PopupMenuItem(value: 'Expired', child: Text('Expired')),
        ],
        child: _buttonContainer(
          cs,
          hp,
          spacing,
          iconSize,
          fs,
          'Filter',
          Icons.tune,
        ),
      ),
    );
  }

  Widget _recordsButton(
    BuildContext context,
    double width,
    double hp,
    double spacing,
    double iconSize,
    double fs,
    ColorScheme cs,
  ) {
    return SizedBox(
      width: width,
      child: PopupMenuButton<int>(
        onSelected: (value) {
          if (_pageSize != value) updateLocalUiState(this, () => _pageSize = value);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 10, child: Text('10')),
          PopupMenuItem(value: 25, child: Text('25')),
          PopupMenuItem(value: 50, child: Text('50')),
        ],
        child: _buttonContainer(
          cs,
          hp,
          spacing,
          iconSize,
          fs,
          'Records',
          Icons.keyboard_arrow_down,
        ),
      ),
    );
  }

  Widget _uploadButton(
    BuildContext context,
    double width,
    double hp,
    double spacing,
    double iconSize,
    double fs,
    ColorScheme cs,
  ) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AdminAddDocumentScreen(
                associateId: widget.driverId,
                associateType: 'DRIVER',
              ),
            ),
          );
          if (updated == true) await _loadDocs();
        },
        borderRadius: BorderRadius.circular(12),
        child: _buttonContainer(
          cs,
          hp,
          spacing,
          iconSize,
          fs,
          'Upload',
          Icons.upload_outlined,
        ),
      ),
    );
  }

  Widget _buttonContainer(
    ColorScheme cs,
    double hp,
    double spacing,
    double iconSize,
    double fs,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hp, vertical: spacing),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: cs.onSurface),
          SizedBox(width: spacing / 2),
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: fs,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.surfaceContainerHighest),
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
            style: AppFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a document to see it listed here.',
            style: AppFonts.roboto(
              fontSize: 12,
              height: 1.45,
              color: cs.onSurface.withOpacity(0.68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Couldn't load documents.",
              style: AppFonts.roboto(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.75),
              ),
            ),
          ),
          TextButton(onPressed: _loadDocs, child: const Text('Retry')),
        ],
      ),
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
