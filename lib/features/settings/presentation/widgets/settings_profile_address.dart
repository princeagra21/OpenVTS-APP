import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';

class SettingsProfileAddressCard extends StatelessWidget {
  const SettingsProfileAddressCard({
    super.key,
    required this.address,
    required this.loading,
  });

  final String address;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final fs = AdaptiveUtils.getTitleFontSize(width);
    final scale = fs / 14;
    final labelFs = 11 * scale;
    final titleFs = 14 * scale;
    final iconBox = 40 * scale;
    final iconSize = 18 * scale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.location_on_outlined,
              size: iconSize,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address',
                  style: AppFonts.roboto(
                    fontSize: labelFs,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                loading
                    ? const AppShimmer(width: double.infinity, height: 16, radius: 8)
                    : Text(
                        address,
                        style: AppFonts.roboto(
                          fontSize: titleFs,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
