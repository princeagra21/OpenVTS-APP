import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/features/user/presentation/screens/notification/push_notification/config.dart';

class PushNotificationVehicleSection extends StatelessWidget {
  const PushNotificationVehicleSection({
    super.key,
    required this.padding,
    required this.spacing,
    required this.iconSize,
    required this.mainFontSize,
    required this.secondaryFontSize,
    required this.searchController,
    required this.onSearchChanged,
    required this.vehicleFilter,
    required this.onFilterChanged,
    required this.vehiclePageSize,
    required this.onPageSizeChanged,
    required this.onRefresh,
    required this.child,
  });

  final double padding;
  final double spacing;
  final double iconSize;
  final double mainFontSize;
  final double secondaryFontSize;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String vehicleFilter;
  final ValueChanged<String> onFilterChanged;
  final int vehiclePageSize;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicles',
            style: AppFonts.roboto(
              fontSize: 18,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: padding),
          Container(
            height: padding * 3.5,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: AppFonts.roboto(
                fontSize: mainFontSize,
                height: 20 / 14,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search vehicle name or plate...',
                hintStyle: AppFonts.roboto(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: secondaryFontSize,
                  height: 16 / 12,
                ),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  size: iconSize + 2,
                  color: colorScheme.onSurface,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: padding,
                ),
              ),
            ),
          ),
          SizedBox(height: padding),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = spacing;
              final cellWidth = (constraints.maxWidth - gap * 2) / 3;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cellWidth,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (vehicleFilter == value) return;
                        onFilterChanged(value);
                      },
                      itemBuilder: (context) {
                        return PushNotificationConfig.vehicleFilters
                            .map(
                              (filter) => PopupMenuItem<String>(
                                value: filter,
                                child: Text(filter),
                              ),
                            )
                            .toList();
                      },
                      child: _ActionChip(
                        padding: padding,
                        spacing: spacing,
                        iconSize: iconSize,
                        icon: Icons.tune,
                        text: 'Filter',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cellWidth,
                    child: PopupMenuButton<int>(
                      onSelected: (value) {
                        if (vehiclePageSize == value) return;
                        onPageSizeChanged(value);
                      },
                      itemBuilder: (context) {
                        return PushNotificationConfig.vehiclePageSizes
                            .map(
                              (size) => PopupMenuItem<int>(
                                value: size,
                                child: Text(size.toString()),
                              ),
                            )
                            .toList();
                      },
                      child: _ActionChip(
                        padding: padding,
                        spacing: spacing,
                        iconSize: iconSize,
                        text: 'Records',
                        trailing: Icon(
                          Icons.keyboard_arrow_down,
                          size: iconSize,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cellWidth,
                    child: InkWell(
                      onTap: onRefresh,
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: _ActionChip(
                        padding: padding,
                        spacing: spacing,
                        iconSize: iconSize,
                        icon: Icons.refresh,
                        text: 'Refresh',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: padding),
          child,
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.padding,
    required this.spacing,
    required this.iconSize,
    required this.text,
    this.icon,
    this.trailing,
  });

  final double padding;
  final double spacing;
  final double iconSize;
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(icon, size: iconSize, color: colorScheme.onSurface),
          if (icon != null) SizedBox(width: spacing / 2),
          Flexible(
            child: Text(
              text,
              style: AppFonts.roboto(
                fontSize: 11,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: spacing / 2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

