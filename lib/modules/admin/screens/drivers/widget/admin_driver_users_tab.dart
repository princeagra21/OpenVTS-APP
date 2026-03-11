import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDriverUsersTab extends StatelessWidget {
  final List<AdminUserListItem> items;
  final bool loading;
  final double bodyFontSize;
  final double smallFontSize;

  const AdminDriverUsersTab({
    super.key,
    required this.items,
    required this.loading,
    required this.bodyFontSize,
    required this.smallFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (loading) {
      return listShimmer(context, count: 3, height: 108);
    }
    if (items.isEmpty) {
      return emptyStateCard(
        context,
        title: 'No users found',
        subtitle: 'No users are linked to this driver.',
      );
    }

    return Column(
      children: items.map((user) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: detailsCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: cs.primary,
                      child: Text(
                        user.initials,
                        style: GoogleFonts.inter(
                          color: cs.onPrimary,
                          fontSize: smallFontSize + 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            safeText(user.fullName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: bodyFontSize + 1,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            safeText(user.email),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: smallFontSize + 1,
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    statusChip(context, user.statusLabel, smallFontSize),
                  ],
                ),
                const SizedBox(height: 12),
                detailLine(
                  context,
                  'Phone',
                  safeText(user.fullPhone),
                  bodyFontSize,
                ),
                const SizedBox(height: 8),
                detailLine(
                  context,
                  'Location',
                  safeText(user.location),
                  bodyFontSize,
                ),
                const SizedBox(height: 8),
                detailLine(
                  context,
                  'Joined',
                  formatDateLabel(user.joinedAt),
                  bodyFontSize,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
