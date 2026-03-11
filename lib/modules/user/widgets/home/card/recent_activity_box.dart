import 'package:fleet_stack/core/models/user_recent_alert_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBackground;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final hPadding = AdaptiveUtils.getHorizontalPadding(screenWidth) - 4;
    final vPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2;
    final fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackground ?? colorScheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class RecentActivityBox extends StatefulWidget {
  final bool loading;
  final List<UserRecentAlertItem> items;

  const RecentActivityBox({
    super.key,
    required this.loading,
    required this.items,
  });

  @override
  State<RecentActivityBox> createState() => _RecentActivityBoxState();
}

class _RecentActivityBoxState extends State<RecentActivityBox> {
  String activityTab = 'Recent Alerts';

  String _formatRelative(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '—';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '${weeks}w';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  Widget _buildShimmerItem() {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          CircleAvatar(
            radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
            backgroundColor: colorScheme.surfaceVariant,
            child: const AppShimmer(width: 18, height: 18, radius: 9),
          ),
          SizedBox(width: itemPadding + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppShimmer(width: double.infinity, height: 14, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: 160, height: 12, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(UserRecentAlertItem activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final mainFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final avatar = CircleAvatar(
      radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
      backgroundColor: activity.isRead
          ? colorScheme.surfaceVariant
          : colorScheme.primary.withOpacity(0.12),
      child: Icon(
        Icons.notifications_none_rounded,
        color: activity.isRead
            ? colorScheme.onSurface.withOpacity(0.7)
            : colorScheme.primary,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          avatar,
          SizedBox(width: itemPadding + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: mainFontSize - 3,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatRelative(activity.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: subFontSize,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final linkFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: AdaptiveUtils.getIconPaddingLeft(screenWidth) - 4,
                runSpacing: 8,
                children: [
                  SmallTab(
                    label: 'Recent Alerts',
                    selected: activityTab == 'Recent Alerts',
                    onTap: () => setState(() => activityTab = 'Recent Alerts'),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.push('/user/notifications'),
                child: Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: linkFontSize,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: widget.loading
                ? ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 5,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                    itemBuilder: (_, __) => _buildShimmerItem(),
                  )
                : widget.items.isEmpty
                ? Center(
                    child: Text(
                      'No alerts found',
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                    itemBuilder: (_, i) => _buildActivityItem(widget.items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
