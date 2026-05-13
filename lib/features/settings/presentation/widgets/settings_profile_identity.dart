import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_status_chip.dart';
import 'package:open_vts/features/settings/presentation/widgets/settings_profile_avatar.dart';

class SettingsProfileIdentityCard extends StatelessWidget {
  const SettingsProfileIdentityCard({
    super.key,
    required this.name,
    required this.username,
    required this.verified,
    required this.imageUrl,
    required this.loading,
  });

  final String name;
  final String username;
  final bool verified;
  final String imageUrl;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final nameSize = AdaptiveUtils.getSubtitleFontSize(width) + 2;
    final handleSize = AdaptiveUtils.getTitleFontSize(width) - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          if (loading)
            const AppShimmer(width: 56, height: 56, radius: 28)
          else
            SettingsProfileAvatar(
              name: name,
              imageUrl: imageUrl,
              size: 56 * scale,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loading ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.roboto(
                    fontSize: nameSize,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.roboto(
                    fontSize: handleSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!loading)
            OpenVtsStatusChip(
              label: verified ? 'Verified' : 'Unverified',
              tone: verified
                  ? OpenVtsStatusTone.success
                  : OpenVtsStatusTone.danger,
              icon: verified ? Icons.verified : Icons.error_outline,
              compact: true,
            ),
        ],
      ),
    );
  }
}

class SettingsProfileDatesGrid extends StatelessWidget {
  const SettingsProfileDatesGrid({
    super.key,
    required this.loading,
    required this.createdDate,
    required this.createdTime,
    required this.updatedDate,
    required this.updatedTime,
  });

  final bool loading;
  final String createdDate;
  final String createdTime;
  final String updatedDate;
  final String updatedTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 4;
    final timeSize = AdaptiveUtils.getSubtitleFontSize(width) - 3;

    Widget cell({
      required String label,
      required String date,
      required String time,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: labelSize,
                height: 14 / 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loading ? '—' : date,
              style: AppFonts.roboto(
                fontSize: valueSize,
                height: 18 / 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loading ? '—' : time,
              style: AppFonts.roboto(
                fontSize: timeSize,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AdaptiveUtils.getLeftSectionSpacing(width) + 6;
        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: cell(
                label: 'Updated',
                date: updatedDate,
                time: updatedTime,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: cell(
                label: 'Created',
                date: createdDate,
                time: createdTime,
              ),
            ),
          ],
        );
      },
    );
  }
}
