import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Widget _buildItemsBlock({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
    required double width,
    required double hp,
    required ColorScheme colorScheme,
    required bool isGridView,
  }) {
    final int crossAxisCount = isGridView
        ? (width > 1100
            ? 4
            : width > 700
                ? 3
                : 2)
        : 1;

    final double childAspectRatio = isGridView ? 0.95 : 4.5;
    final double mainAxisSpacing = isGridView ? hp : 12;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: hp,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _MoreMenuCard(
          title: item['title'],
          subtitle: item['subtitle'],
          icon: item['icon'],
          route: item['route'],
          width: width,
          hp: hp,
          isListMode: !isGridView,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;

    /// Flat list of notification items (no section headers)
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Fleet Truck A',
        'subtitle': '1234',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/1234',
      },
      {
        'title': 'Delivery Van B',
        'subtitle': '123456789',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/123456789',
      },
      {
        'title': 'Service Vehicle C',
        'subtitle': '136-MH43N0642',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/136-MH43N0642',
      },
      {
        'title': 'Emergency Unit D',
        'subtitle': '138-MH46D75864',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/138-MH46D75864',
      },
      {
        'title': 'Transport Truck E',
        'subtitle': '138-MH46K0268',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/138-MH46K0268',
      },
      {
        'title': 'City Delivery F',
        'subtitle': '2722',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/2722',
      },
      {
        'title': 'Long Haul G',
        'subtitle': '2726',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/2726',
      },
      {
        'title': 'Local Service H',
        'subtitle': '2765',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/2765',
      },
      {
        'title': 'Express Van I',
        'subtitle': '2853',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/2853',
      },
      {
        'title': 'Heavy Duty J',
        'subtitle': '2857',
        'icon': CupertinoIcons.bell,
        'route': '/user/toggle/2857',
      },
    ];

    return AppLayout(
      title: "USER",
      subtitle: "Notifications",
      showLeftAvatar: false,
      horizontalPadding: 5,
      actionIcons: [],
      onActionTaps: [],
      leftAvatarText: 'NO',
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hp, 0, hp, hp * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemsBlock(
                context: context,
                items: menuItems,
                width: width,
                hp: hp,
                colorScheme: colorScheme,
                isGridView: false,
              ),
              SizedBox(height: hp),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final double width;
  final double hp;
  final bool isListMode;

  const _MoreMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.width,
    required this.hp,
    this.isListMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final double iconContainerSize = isListMode
        ? AdaptiveUtils.getAvatarSize(width) * 1.1
        : AdaptiveUtils.getAvatarSize(width) * 1.3;

    final double innerIconSize = isListMode
        ? AdaptiveUtils.getIconSize(width)
        : AdaptiveUtils.getIconSize(width);

    final EdgeInsets cardPadding = isListMode
        ? EdgeInsets.symmetric(horizontal: hp * 1.2, vertical: hp * 0.7)
        : EdgeInsets.all(hp * 0.8);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(route),
          child: Padding(
            padding: cardPadding,
            child: isListMode
                ? Row(
                    children: [
                      Container(
                        height: iconContainerSize,
                        width: iconContainerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: innerIconSize,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 1,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: AdaptiveUtils.getTitleFontSize(width) - 1,
                                color: colorScheme.onSurface.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: AdaptiveUtils.getIconSize(width) * 0.8,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: iconContainerSize,
                        width: iconContainerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: innerIconSize,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 1,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) - 1,
                          color: colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}