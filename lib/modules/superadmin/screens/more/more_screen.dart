import 'package:fleet_stack/core/services/push_notifications_service.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  static const String _viewModeKey = 'superadmin_more_screen_view_mode';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isGridView = prefs.getBool(_viewModeKey) ?? true;
    });
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool(_viewModeKey, _isGridView);
  }

  Future<void> _logout() async {
    await PushNotificationsService.instance.unregisterForLogout();
    await TokenStorage.defaultInstance().clear();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmDialog(),
    );
    if (shouldLogout != true) return;
    await _logout();
  }

  Widget _buildItemsBlock({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
    required double width,
    required double hp,
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

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Server',
        'subtitle': 'Status and setup',
        'icon': CupertinoIcons.settings,
        'route': '/superadmin/server',
      },
      {
        'title': 'Calendar',
        'subtitle': 'Jobs and events',
        'icon': CupertinoIcons.calendar,
        'route': '/superadmin/calendar',
      },
      {
        'title': 'Support',
        'subtitle': 'Help center',
        'icon': CupertinoIcons.question_circle,
        'route': '/superadmin/support',
      },
      {
        'title': 'Setting',
        'subtitle': 'App and account',
        'icon': CupertinoIcons.settings_solid,
        'route': '/superadmin/settings',
      },
      {
        'title': 'SSL',
        'subtitle': 'Certificate & HTTPS',
        'icon': CupertinoIcons.lock_shield,
        'route': '/superadmin/ssl',
      },
      {
        'title': 'Roles',
        'subtitle': 'Admin & permissions',
        'icon': CupertinoIcons.person_2_fill,
        'route': '/superadmin/roles',
      },
    ];

    final IconData toggleViewIcon = _isGridView
        ? CupertinoIcons.list_bullet
        : CupertinoIcons.square_grid_2x2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Menu",
      actionIcons: [CupertinoIcons.square_arrow_right, toggleViewIcon],
      onActionTaps: [_confirmLogout, _toggleViewMode],
      leftAvatarText: 'FS',
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hp, hp, hp, hp * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tools & Settings",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 4,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withOpacity(0.9),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: hp * 1.2),
            _buildItemsBlock(
              context: context,
              items: menuItems,
              width: width,
              hp: hp,
              isGridView: _isGridView,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.square_arrow_right,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Log out?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your current session will end. You will need to log in again to continue.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Log out',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

    final double innerIconSize = AdaptiveUtils.getIconSize(width);

    final EdgeInsets cardPadding = isListMode
        ? EdgeInsets.symmetric(horizontal: hp * 1.2, vertical: hp * 0.7)
        : EdgeInsets.all(hp * 0.8);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.05),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    1,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getTitleFontSize(width) - 1,
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
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 1,
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
