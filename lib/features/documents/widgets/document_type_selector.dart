import 'package:flutter/material.dart';
import 'package:open_vts/core/models/superadmin_document_type.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';

class DocumentTypeSelectorField extends StatelessWidget {
  const DocumentTypeSelectorField({
    super.key,
    required this.screenWidth,
    required this.labelSize,
    required this.selectedType,
    required this.loading,
    required this.onTap,
  });

  final double screenWidth;
  final double labelSize;
  final SuperadminDocumentType? selectedType;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Type *',
          style: AppFonts.roboto(
            fontSize: 12 * (screenWidth / 420).clamp(0.9, 1.0),
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedType?.name ?? 'Select document type',
                    style: AppFonts.roboto(
                      fontSize: labelSize,
                      color: selectedType == null
                          ? cs.onSurface.withValues(alpha: 0.5)
                          : cs.onSurface,
                    ),
                  ),
                ),
                loading
                    ? const AppShimmer(width: 16, height: 16, radius: 8)
                    : Icon(
                        Icons.expand_more,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DocumentTypeSelectionSheet extends StatefulWidget {
  const DocumentTypeSelectionSheet({
    super.key,
    required this.docTypes,
    required this.selectedDocType,
    required this.loadingDocTypes,
  });

  final List<SuperadminDocumentType> docTypes;
  final SuperadminDocumentType? selectedDocType;
  final bool loadingDocTypes;

  @override
  State<DocumentTypeSelectionSheet> createState() =>
      _DocumentTypeSelectionSheetState();
}

class _DocumentTypeSelectionSheetState
    extends State<DocumentTypeSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.docTypes.where((item) {
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.docFor.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select Document Type',
              style: AppFonts.roboto(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search document type...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: widget.loadingDocTypes
                  ? ListView.separated(
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, __) => const AppShimmer(
                        width: double.infinity,
                        height: 56,
                        radius: 12,
                      ),
                    )
                  : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No document types found',
                        style: AppFonts.roboto(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        final isSelected =
                            widget.selectedDocType?.id == item.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          title: Text(
                            item.name,
                            style: AppFonts.roboto(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            item.docFor.isEmpty
                                ? '—'
                                : item.docFor.toUpperCase(),
                            style: AppFonts.roboto(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check, color: cs.primary)
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
