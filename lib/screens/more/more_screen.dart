import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    /// Updated menu items — Added SSL & Roles
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Server',
        'subtitle': 'Status and setup',
        'icon': CupertinoIcons.settings,
        'route': '/server',
      },
      {
        'title': 'Calendar',
        'subtitle': 'Jobs and events',
        'icon': CupertinoIcons.calendar,
        'route': '/calendar',
      },
      {
        'title': 'Support',
        'subtitle': 'Help center',
        'icon': CupertinoIcons.question_circle,
        'route': '/support',
      },
      {
        'title': 'Setting',
        'subtitle': 'App and account',
        'icon': CupertinoIcons.settings_solid,
        'route': '/settings',
      },

      /// NEW ITEMS
      {
        'title': 'SSL',
        'subtitle': 'Certificate & HTTPS',
        'icon': CupertinoIcons.lock_shield,
        'route': '/ssl',
      },
      {
        'title': 'Roles',
        'subtitle': 'Admin & permissions',
        'icon': CupertinoIcons.person_2_fill,
        'route': '/roles',
      },
    ];

    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Menu",
      actionIcons: const [CupertinoIcons.search, CupertinoIcons.bell],
      leftAvatarText: 'FS',

      child: Container(
        padding: EdgeInsets.fromLTRB(hp, hp, hp, hp * 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black.withOpacity(0.03),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tools & Settings",
              style: TextStyle(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 4,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.85),
                letterSpacing: -0.3,
              ),
            ),

            SizedBox(height: hp * 1.2),

            /// FIRST ROW (Server, Calendar)
            _buildRow(menuItems[0], menuItems[1], width, hp, context),
            SizedBox(height: hp),

            /// SECOND ROW (Support, Setting)
            _buildRow(menuItems[2], menuItems[3], width, hp, context),
            SizedBox(height: hp),

            /// THIRD ROW (SSL, Roles)
            _buildRow(menuItems[4], menuItems[5], width, hp, context),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
    double width,
    double hp,
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: _MoreMenuCard(
            title: left['title'],
            subtitle: left['subtitle'],
            icon: left['icon'],
            width: width,
            hp: hp,
            route: left['route'],
          ),
        ),
        SizedBox(width: hp),
        Expanded(
          child: _MoreMenuCard(
            title: right['title'],
            subtitle: right['subtitle'],
            icon: right['icon'],
            width: width,
            hp: hp,
            route: right['route'],
          ),
        ),
      ],
    );
  }
}

class _MoreMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double width;
  final double hp;
  final String route;

  const _MoreMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.width,
    required this.hp,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (route.isNotEmpty) {
            context.push(route);
          }
        },
        child: Container(
          padding: EdgeInsets.all(hp),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ICON
              Container(
                height: AdaptiveUtils.getAvatarSize(width) * 1.5,
                width: AdaptiveUtils.getAvatarSize(width) * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.05),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: AdaptiveUtils.getIconSize(width) * 1.2,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// TITLE
              Text(
                title,
                style: TextStyle(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                  fontWeight: FontWeight.bold,
                  color: Colors.black.withOpacity(0.9),
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: AdaptiveUtils.isVerySmallScreen(width) ? 4 : 6),

              /// SUBTITLE
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.5),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
