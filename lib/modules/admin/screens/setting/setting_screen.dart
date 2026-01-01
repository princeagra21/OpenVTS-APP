import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _settingsViewKey = 'settings_view_mode';

  // Private field to hold current view mode
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool(_settingsViewKey, _isGridView);
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool(_settingsViewKey) ?? true; // default grid
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> settingsItems = [
      {'title': 'Profile', 'subtitle': 'Manage profile', 'icon': CupertinoIcons.person, 'route': '/admin/profile'},
      {'title': 'Notification Setting', 'subtitle': 'Alert preferences', 'icon': CupertinoIcons.bell, 'route': '/admin/notification-preferences'},
      {'title': 'Localization', 'subtitle': 'Language & region', 'icon': CupertinoIcons.globe, 'route': '/admin/localization'},
      {'title': 'App preferences', 'subtitle': 'App preferences', 'icon': CupertinoIcons.settings, 'route': '/admin/application-settings'},
    ];

    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;

    // Toggle icon: shows the view you will switch TO when tapped
    final IconData toggleIcon = _isGridView ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Settings",
      // Use the toggle icon and wire the tap to _toggleViewMode
      actionIcons: [toggleIcon],
      onActionTaps: [
        () => _toggleViewMode(),
      ],
      leftAvatarText: 'FS',
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
            ],
          ),

          SizedBox(height: hp * 1.2),

          /// SETTINGS ITEMS – GRID OR LIST
          if (_isGridView)
            ..._buildCardRows(settingsItems, width, hp, context)
          else
            ...settingsItems.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: hp),
                  child: _SettingsMenuCard(
                    title: item['title'],
                    subtitle: item['subtitle'],
                    icon: item['icon'],
                    route: item['route'],
                    isListMode: true,
                  ),
                )),
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
                isListMode: false, // explicit for clarity
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
                  isListMode: false,
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );

      rows.add(SizedBox(height: hp));
    }

    return rows;
  }
}

class _SettingsMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool isListMode;

  const _SettingsMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.isListMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;
    final double avatarSize = AdaptiveUtils.getAvatarSize(width);
    final double iconSize = AdaptiveUtils.getIconSize(width);

    // Adjust sizes slightly for list mode (more compact)
    final double containerSize = isListMode ? avatarSize * 1.2 : avatarSize * 1.5;
    final double innerIconSize = isListMode ? iconSize : iconSize * 1.2;

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
          child: isListMode
              ? Row(
                  children: [
                    Container(
                      height: containerSize,
                      width: containerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.05),
                      ),
                      child: Center(
                        child: Icon(icon, size: innerIconSize, color: colorScheme.primary.withOpacity(0.8)),
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
                            style: TextStyle(
                              fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface.withOpacity(0.9),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
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
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: iconSize * 0.9,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: avatarSize * 1.5,
                      width: avatarSize * 1.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withOpacity(0.05),
                      ),
                      child: Center(
                        child: Icon(icon, size: iconSize * 1.2, color: colorScheme.primary.withOpacity(0.8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.9),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
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