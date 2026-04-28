import 'package:fleet_stack/core/models/admin_driver_list_item.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserDriversTab extends StatelessWidget {
  final List<AdminDriverListItem> items;
  final bool loading;
  final double bodyFontSize;
  final double smallFontSize;

  const AdminUserDriversTab({
    super.key,
    required this.items,
    required this.loading,
    required this.bodyFontSize,
    required this.smallFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final titleFs = 14 * scale;
    final subtitleFs = 12 * scale;
    final statusFs = 11 * scale;
    final iconSize = subtitleFs + 2;
    if (loading) {
      return listShimmer(context, count: 3, height: 108);
    }
    if (items.isEmpty) {
      return emptyStateCard(
        context,
        title: 'No drivers found',
        subtitle: 'No drivers are linked to this user.',
      );
    }

    return Column(
      children: items.map((driver) {
        final name = safeText(driver.fullName);
        final username = safeText(driver.username);
        final email = safeText(driver.email);
        final phone = safeText(driver.fullPhone);
        final primary = safeText(driver.primaryUserName);
        final location = safeText(driver.addressLocation);
        final joined = _formatDateOnly(driver.raw['createdAt']?.toString());
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: detailsCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.surface,
                      radius: AdaptiveUtils.getAvatarSize(width) / 2,
                      foregroundColor: cs.onSurface,
                      child: Container(
                        width: AdaptiveUtils.getAvatarSize(width),
                        height: AdaptiveUtils.getAvatarSize(width),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          driver.initials,
                          style: GoogleFonts.roboto(
                            color: cs.onSurface,
                            fontSize: AdaptiveUtils.getFsAvatarFontSize(width),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing * 2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.roboto(
                                    fontSize: titleFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? cs.surfaceVariant
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  safeText(driver.statusLabel),
                                  style: GoogleFonts.roboto(
                                    fontSize: statusFs,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: iconSize,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  username,
                                  style: GoogleFonts.roboto(
                                    fontSize: subtitleFs,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: iconSize,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  email,
                                  style: GoogleFonts.roboto(
                                    fontSize: subtitleFs,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: iconSize,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: GoogleFonts.roboto(
                                    fontSize: subtitleFs,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing / 2),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: iconSize,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  primary,
                                  style: GoogleFonts.roboto(
                                    fontSize: subtitleFs,
                                    height: 16 / 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 1.5),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = spacing;
                    final cellWidth = (constraints.maxWidth - gap) / 2;
                    final primaryUser = _safeText(driver.primaryUserName);
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: cellWidth,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  AdaptiveUtils.getHorizontalPadding(width),
                              vertical: spacing,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Primary User",
                                  style: GoogleFonts.roboto(
                                    fontSize: subtitleFs,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: spacing / 2),
                                Text(
                                  primaryUser,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.roboto(
                                    fontSize: subtitleFs,
                                    height: 16 / 12,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: cellWidth,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  AdaptiveUtils.getHorizontalPadding(width),
                              vertical: spacing - 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: iconSize,
                                      color: cs.onSurface.withOpacity(0.7),
                                    ),
                                    SizedBox(width: spacing),
                                    Expanded(
                                      child: Text(
                                        "Joined",
                                        style: GoogleFonts.roboto(
                                          fontSize: subtitleFs,
                                          height: 14 / 11,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: spacing),
                                Text(
                                  joined,
                                  style: GoogleFonts.roboto(
                                    fontSize: titleFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: spacing),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: AdaptiveUtils.getHorizontalPadding(width),
                    vertical: spacing,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Location",
                        style: GoogleFonts.roboto(
                          fontSize: subtitleFs,
                          height: 14 / 11,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: spacing / 2),
                      Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: subtitleFs,
                          height: 16 / 12,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDateOnly(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '—';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    final local = dt.toLocal();
    const months = <String>[
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
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year.toString();
    return '$day $month $year';
  }

  String _safeText(String? value, {String fallback = '—'}) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return fallback;
    return trimmed;
  }

  String _countryCode(AdminDriverListItem driver) {
    final raw = driver.raw['address'];
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw.cast());
      final code = _safeText(map['countryCode']?.toString());
      if (code != '—') return code;
    }
    return _safeText(driver.raw['countryCode']?.toString());
  }
}
