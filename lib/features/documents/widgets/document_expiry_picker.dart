import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';

class DocumentExpiryPicker extends StatelessWidget {
  const DocumentExpiryPicker({
    super.key,
    required this.screenWidth,
    required this.labelSize,
    required this.selectedExpiryLabel,
    required this.onTap,
  });

  final double screenWidth;
  final double labelSize;
  final String? selectedExpiryLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiry Date (optional)',
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
                    selectedExpiryLabel ?? 'Select date',
                    style: AppFonts.roboto(
                      fontSize: labelSize,
                      color: selectedExpiryLabel == null
                          ? cs.onSurface.withValues(alpha: 0.5)
                          : cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
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
