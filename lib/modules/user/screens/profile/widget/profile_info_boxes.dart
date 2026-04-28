// components/profile/profile_info_boxes.dart
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart'
    show AdaptiveUtils;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileInfoBoxes extends StatelessWidget {
  final AdminProfile? profile;
  final bool loading;

  const ProfileInfoBoxes({
    super.key,
    required this.profile,
    required this.loading,
  });

  String _formatDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '—';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = dt.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:$mm $ampm';
  }

  String _relativeOrDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '—';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} h ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
    return _formatDate(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(
      screenWidth,
    );
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 1;
    final double labelFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double smallFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 0.5;
    final double spacing =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth) * 1.2;

    final String lastLoginExact = _formatDate(profile?.lastLoginAt ?? '');
    final String createdDate = _formatDate(profile?.createdAt ?? '');
    final String passwordChanged = _relativeOrDate(
      profile?.passwordChangedAt ?? '',
    );

    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account activity',
            style: GoogleFonts.inter(
              fontSize: titleFontSize - 2,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          SizedBox(height: spacing / 1.1),
          Divider(height: 1.5, color: colorScheme.primary.withOpacity(0.5)),
          SizedBox(height: spacing / 1.1),
          _infoRow(
            label: 'Last login',
            valueTitle: lastLoginExact,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            subtitleFontSize: smallFontSize,
            colorScheme: colorScheme,
            singleLine: true,
            loading: loading,
          ),
          SizedBox(height: spacing / 1.1),
          _infoRow(
            label: 'Created',
            valueTitle: createdDate,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            subtitleFontSize: smallFontSize,
            colorScheme: colorScheme,
            singleLine: true,
            loading: loading,
          ),
          SizedBox(height: spacing / 1.1),
          _infoRow(
            label: 'Password last change',
            valueTitle: passwordChanged,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            subtitleFontSize: smallFontSize,
            colorScheme: colorScheme,
            labelFontWeight: FontWeight.w400,
            valueFontWeight: FontWeight.w200,
            singleLine: true,
            loading: loading,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String valueTitle,
    String? valueSubtitle,
    required double labelFontSize,
    required double valueFontSize,
    required double subtitleFontSize,
    required ColorScheme colorScheme,
    FontWeight valueFontWeight = FontWeight.w200,
    FontWeight labelFontWeight = FontWeight.w500,
    bool singleLine = false,
    required bool loading,
  }) {
    if (singleLine) {
      return Row(
        children: [
          Expanded(
            child: loading
                ? const AppShimmer(
                    width: double.infinity,
                    height: 14,
                    radius: 7,
                  )
                : Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$label: ',
                          style: GoogleFonts.inter(
                            fontSize: labelFontSize,
                            fontWeight: labelFontWeight,
                            color: colorScheme.onSurface.withOpacity(0.85),
                          ),
                        ),
                        TextSpan(
                          text: valueTitle,
                          style: GoogleFonts.inter(
                            fontSize: valueFontSize,
                            fontWeight: valueFontWeight,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: labelFontSize,
              fontWeight: labelFontWeight,
              color: colorScheme.onSurface.withOpacity(0.85),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              loading
                  ? const AppShimmer(width: 140, height: 14, radius: 7)
                  : Text(
                      valueTitle,
                      style: GoogleFonts.inter(
                        fontSize: valueFontSize,
                        fontWeight: valueFontWeight,
                        color: colorScheme.onSurface,
                      ),
                    ),
              if (valueSubtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  valueSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: subtitleFontSize,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
