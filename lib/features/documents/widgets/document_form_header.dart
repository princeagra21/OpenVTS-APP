import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class DocumentFormHeader extends StatelessWidget {
  const DocumentFormHeader({
    super.key,
    required this.isEdit,
    required this.titleSize,
    required this.labelSize,
    required this.onClose,
  });

  final bool isEdit;
  final double titleSize;
  final double labelSize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isEdit ? 'Edit Document' : 'Add Document',
              style: AppFonts.roboto(
                fontSize: titleSize + 2,
                fontWeight: FontWeight.w800,
                color: cs.onSurface.withValues(alpha: 0.9),
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 28,
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isEdit ? 'Update document details' : 'Upload a new document',
          style: AppFonts.roboto(
            fontSize: labelSize - 2,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.87),
          ),
        ),
      ],
    );
  }
}
