import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class DocumentFilePicker extends StatelessWidget {
  const DocumentFilePicker({
    super.key,
    required this.isEdit,
    required this.screenWidth,
    required this.labelSize,
    required this.selectedFileName,
    required this.selectedFileSize,
    required this.currentFileName,
    required this.onTap,
  });

  final bool isEdit;
  final double screenWidth;
  final double labelSize;
  final String? selectedFileName;
  final int selectedFileSize;
  final String currentFileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEdit ? 'File Selection (optional)' : 'File Selection *',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedFileName ??
                      (isEdit ? currentFileName : 'Click to upload'),
                  style: AppFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEdit
                      ? 'Choose a new file only if you want to replace the current document.'
                      : 'JPG, JPEG, PNG, PDF, DOC, DOCX, WEBP (max 5.0 MB per file)',
                  style: AppFonts.roboto(
                    fontSize: labelSize - 4,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                if (selectedFileSize > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${(selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: AppFonts.roboto(
                      fontSize: labelSize - 4,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
