import 'package:fleet_stack/core/models/user_top_asset_item.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TopCustomersBox extends StatelessWidget {
  final bool loading;
  final List<UserTopAssetItem> items;

  const TopCustomersBox({
    super.key,
    required this.loading,
    required this.items,
  });

  Widget _buildShimmerItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          SizedBox(width: itemPadding + 2),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: double.infinity, height: 14, radius: 8),
                SizedBox(height: 8),
                AppShimmer(width: 140, height: 12, radius: 8),
              ],
            ),
          ),
          SizedBox(width: itemPadding + 2),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: itemPadding + 2,
              vertical: itemPadding - 2,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const AppShimmer(width: 58, height: 14, radius: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem(
    BuildContext context,
    UserTopAssetItem item,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final mainFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final chipColors = [
      colorScheme.primary,
      colorScheme.secondary,
      Colors.green,
      Colors.orange,
    ];
    final chipColor = chipColors[index % chipColors.length];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: mainFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          item.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: subFontSize,
            color: colorScheme.onSurface.withOpacity(0.54),
          ),
        ),
      ],
    );

    final right = Container(
      padding: EdgeInsets.symmetric(
        horizontal: itemPadding + 2,
        vertical: itemPadding - 2,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 110),
        child: Text(
          item.metricLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: colorScheme.onPrimary,
            fontSize: badgeFontSize,
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          SizedBox(width: itemPadding + 2),
          Expanded(child: content),
          SizedBox(width: itemPadding + 2),
          right,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
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
              Text(
                'Top Assets',
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              InkWell(
                onTap: () => context.push('/user/vehicles'),
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
          SizedBox(height: padding),
          SizedBox(
            height: 320,
            child: loading
                ? ListView.separated(
                    itemCount: 4,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                    itemBuilder: (_, __) => _buildShimmerItem(context),
                  )
                : items.isEmpty
                ? Center(
                    child: Text(
                      'No assets found',
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                    itemBuilder: (_, i) =>
                        _buildAssetItem(context, items[i], i),
                  ),
          ),
        ],
      ),
    );
  }
}
