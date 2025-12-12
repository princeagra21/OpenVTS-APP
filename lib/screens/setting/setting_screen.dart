import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> settingsItems = [
      {'title': 'Profile', 'subtitle': 'Manage profile', 'icon': CupertinoIcons.person, 'route': '/profile'},
      {'title': 'White Label', 'subtitle': 'Brand customization', 'icon': CupertinoIcons.paintbrush, 'route': '/white-label'},
      {'title': 'Branding', 'subtitle': 'Company branding', 'icon': CupertinoIcons.briefcase, 'route': '/branding'},
      {'title': 'API Config', 'subtitle': 'Configure APIs', 'icon': CupertinoIcons.cloud, 'route': '/api-config'},
      {'title': 'SMTP Settings', 'subtitle': 'Email settings', 'icon': CupertinoIcons.mail, 'route': '/smtp-settings'},
      {'title': 'Localization', 'subtitle': 'Language & region', 'icon': CupertinoIcons.globe, 'route': '/localization'},
      {'title': 'Settings', 'subtitle': 'App preferences', 'icon': CupertinoIcons.settings, 'route': '/application-settings'},
    //  {'title': 'Email Templates', 'subtitle': 'Manage emails', 'icon': CupertinoIcons.doc, 'route': '/email-settings'},
    //  {'title': 'Push Notification Templates', 'subtitle': 'Manage push', 'icon': CupertinoIcons.bell, 'route': '/notification-settings'},
    //  {'title': 'Payment Gateway', 'subtitle': 'Configure payments', 'icon': CupertinoIcons.creditcard, 'route': '/payment-gateway'},
      {'title': 'Update User Policy', 'subtitle': 'User policy', 'icon': CupertinoIcons.doc_text, 'route': '/user-policy'},
    ];

    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Settings",
      actionIcons: const [CupertinoIcons.search, CupertinoIcons.bell],
      leftAvatarText: 'FS',
      showLeftAvatar: false,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
         Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      "Settings",
      style: TextStyle(
        fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 4,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface.withOpacity(0.85),
        letterSpacing: -0.3,
      ),
    ),

  //  SmallTab(
  //    label: "8 items",
 //     selected: true,
//      onTap: () {},
 //   ),
  ],
),

      
          SizedBox(height: hp * 1.2),
      
          /// SETTINGS CARDS IN ROWS (2 per row)
          ..._buildCardRows(settingsItems, width, hp, context),
        ],
      ),
    );
  }

  List<Widget> _buildCardRows(List<Map<String, dynamic>> items, double width, double hp, BuildContext context) {
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = (i + 1 < items.length) ? items[i + 1] : null;

      rows.add(
        Row(
          children: [
            Expanded(
              child: _SettingsMenuCard(
                title: left['title'],
                subtitle: left['subtitle'],
                icon: left['icon'],
                route: left['route'],
              ),
            ),
            SizedBox(width: hp),
            if (right != null)
              Expanded(
                child: _SettingsMenuCard(
                  title: right['title'],
                  subtitle: right['subtitle'],
                  icon: right['icon'],
                  route: right['route'],
                ),
              )
            else
              Expanded(child: Container()), // Empty for odd count
          ],
        ),
      );

      rows.add(SizedBox(height: hp)); // spacing between rows
    }

    return rows;
  }
}

class _SettingsMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _SettingsMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;

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
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ICON AVATAR
              Container(
                height: AdaptiveUtils.getAvatarSize(width) * 1.5,
                width: AdaptiveUtils.getAvatarSize(width) * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.05),
                ),
                child: Center(
                  child: Icon(icon, size: AdaptiveUtils.getIconSize(width) * 1.2, color: colorScheme.primary.withOpacity(0.8)),
                ),
              ),
              SizedBox(height: 12),

              /// CARD TITLE
              Text(
                title,
                style: TextStyle(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.9),
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 4),

              /// CARD SUBTITLE
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.5),
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