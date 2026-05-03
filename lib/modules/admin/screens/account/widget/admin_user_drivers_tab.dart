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
        final name = driver.fullName;
        final username = driver.username;
        final email = driver.email;
        final phone = driver.fullPhone;
        final status = driver.statusLabel;
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
                                  name.isEmpty ? 'Unknown Driver' : name,
                                  style: GoogleFonts.roboto(
                                    fontSize: titleFs,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                              if (status.isNotEmpty) ...[
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
                                    status,
                                    style: GoogleFonts.roboto(
                                      fontSize: statusFs,
                                      height: 14 / 11,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (username.isNotEmpty) ...[
                            SizedBox(height: spacing / 2),
                            _infoRow(Icons.person_outline, username, iconSize,
                                subtitleFs, cs),
                          ],
                          if (email.isNotEmpty) ...[
                            SizedBox(height: spacing / 2),
                            _infoRow(Icons.mail_outline, email, iconSize,
                                subtitleFs, cs),
                          ],
                          if (phone.isNotEmpty) ...[
                            SizedBox(height: spacing / 2),
                            _infoRow(Icons.phone_outlined, phone, iconSize,
                                subtitleFs, cs),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (joined != '—' && joined.isNotEmpty) ...[
                  SizedBox(height: spacing * 1.5),
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
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String text, double iconSize, double fs,
      ColorScheme cs) {
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: cs.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: fs,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.7),
            ),
            softWrap: true,
          ),
        ),
      ],
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
}
