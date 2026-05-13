import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/documents/presentation/widgets/file_card.dart';

class VehicleDetailsDocumentsTab extends StatelessWidget {
  const VehicleDetailsDocumentsTab({
    super.key,
    required this.loadingDocuments,
    required this.documentsLoadFailed,
    required this.loadingDocTypes,
    required this.uploadingDocument,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterSelected,
    required this.onPageSizeSelected,
    required this.onUploadTap,
    required this.onRetry,
    required this.visibleDocuments,
    required this.showEmpty,
    required this.onDocumentChanged,
  });

  final bool loadingDocuments;
  final bool documentsLoadFailed;
  final bool loadingDocTypes;
  final bool uploadingDocument;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterSelected;
  final ValueChanged<int> onPageSizeSelected;
  final VoidCallback onUploadTap;
  final VoidCallback onRetry;
  final List<Map<String, dynamic>> visibleDocuments;
  final bool showEmpty;
  final Future<void> Function() onDocumentChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsSection = 18 * scale;
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final iconSize = 16 * scale;
    final cardPadding = horizontalPadding + 4;

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
                color: Colors.black.withValues(alpha: 0.06),
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
                height: horizontalPadding * 3.5,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: AppFonts.roboto(
                    fontSize: fsMain,
                    height: 20 / 14,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search title, type, status, tag...',
                    hintStyle: AppFonts.roboto(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: fsSecondary,
                      height: 16 / 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: iconSize,
                      color: colorScheme.onSurface,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: horizontalPadding,
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              LayoutBuilder(
                builder: (context, constraints) {
                  final gap = spacing;
                  final cellWidth = (constraints.maxWidth - gap * 2) / 3;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: cellWidth,
                        child: PopupMenuButton<String>(
                          onSelected: onFilterSelected,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'All', child: Text('All')),
                            PopupMenuItem(value: 'Valid', child: Text('Valid')),
                            PopupMenuItem(value: 'Warning', child: Text('Warning')),
                            PopupMenuItem(value: 'Expired', child: Text('Expired')),
                          ],
                          child: _actionCell(
                            context,
                            'Filter',
                            Icons.tune,
                            horizontalPadding,
                            spacing,
                            fsMain,
                            iconSize,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: cellWidth,
                        child: PopupMenuButton<int>(
                          onSelected: onPageSizeSelected,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 10, child: Text('10')),
                            PopupMenuItem(value: 25, child: Text('25')),
                            PopupMenuItem(value: 50, child: Text('50')),
                          ],
                          child: _actionCell(
                            context,
                            'Records',
                            Icons.keyboard_arrow_down,
                            horizontalPadding,
                            spacing,
                            fsMain,
                            iconSize,
                            trailing: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: cellWidth,
                        child: InkWell(
                          onTap: (loadingDocTypes || uploadingDocument)
                              ? null
                              : onUploadTap,
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          child: _actionCell(
                            context,
                            'Upload',
                            Icons.upload_outlined,
                            horizontalPadding,
                            spacing,
                            fsMain,
                            iconSize,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (loadingDocuments)
                ...List<Widget>.generate(
                  3,
                  (_) => _buildDocumentFileSkeleton(colorScheme),
                )
              else if (showEmpty && !documentsLoadFailed)
                _EmptyDocumentsCard(colorScheme: colorScheme)
              else if (showEmpty && documentsLoadFailed)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Couldn't load documents.",
                          style: AppFonts.roboto(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      TextButton(onPressed: onRetry, child: const Text('Retry')),
                    ],
                  ),
                )
              else
                ...visibleDocuments.map(
                  (document) =>
                      FileCard(document: document, onChanged: onDocumentChanged),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionCell(
    BuildContext context,
    String label,
    IconData icon,
    double horizontalPadding,
    double spacing,
    double fsMain,
    double iconSize, {
    bool trailing = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: spacing),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!trailing) ...[
            Icon(icon, size: iconSize, color: colorScheme.onSurface),
            SizedBox(width: spacing / 2),
          ],
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: fsMain,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (trailing) ...[
            SizedBox(width: spacing / 2),
            Icon(icon, size: iconSize, color: colorScheme.onSurface),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentFileSkeleton(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

class _EmptyDocumentsCard extends StatelessWidget {
  const _EmptyDocumentsCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload a document to see it listed here.',
            style: AppFonts.roboto(
              fontSize: 12,
              height: 1.45,
              color: colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
