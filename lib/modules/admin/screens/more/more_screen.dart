import 'package:fleet_stack/core/services/push_notifications_service.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
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
  bool _isGridView = true;
  static const String _viewModeKey = 'more_screen_view_mode';

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
    final storage = TokenStorage.defaultInstance();
    final superToken = await storage.popImpersonatorToken();
    if (superToken != null && superToken.isNotEmpty) {
      await storage.writeAccessToken(superToken);
      if (!mounted) return;
      context.go('/superadmin/home');
      return;
    }
    await storage.clear();
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

  Widget _buildSection({
    required BuildContext context,
    required String category,
    required List<Map<String, dynamic>> items,
    required double width,
    required double hp,
    required ColorScheme colorScheme,
    required bool isGridView,
  }) {
    final int crossAxisCount = width > 1100
        ? 4
        : width > 700
        ? 3
        : 2;
    final double childAspectRatio = width < 380 ? 0.84 : 0.95;
    final double gridSpacing = isGridView ? hp : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            category.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
              color: colorScheme.primary.withOpacity(0.85),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (isGridView)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: hp,
              mainAxisSpacing: gridSpacing,
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
              );
            },
          ),
        if (!isGridView)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _MoreMenuCard(
                title: item['title'],
                subtitle: item['subtitle'],
                icon: item['icon'],
                route: item['route'],
                width: width,
                hp: hp,
                isListMode: true,
              );
            },
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;

    /// =======================
    /// GROUPED MENU DATA
    /// =======================
    final Map<String, List<Map<String, dynamic>>> groupedMenu = {
      'Account': [
        {
          'title': 'User',
          'subtitle': 'Manage users',
          'icon': CupertinoIcons.person,
          'route': '/admin/users',
        },
        {
          'title': 'Vehicle',
          'subtitle': 'Fleet vehicles',
          'icon': CupertinoIcons.bus,
          'route': '/admin/vehicles',
        },
        {
          'title': 'Drivers',
          'subtitle': 'Driver profiles',
          'icon': CupertinoIcons.person_crop_square,
          'route': '/admin/drivers',
        },
      ],
      'Asset': [
        {
          'title': 'Devices',
          'subtitle': 'Tracking hardware',
          'icon': CupertinoIcons.device_phone_portrait,
          'route': '/admin/devices',
        },
        {
          'title': 'Sim Card',
          'subtitle': 'Network connectivity',
          'icon': Icons.sim_card_outlined,
          'route': '/admin/sims',
        },
      ],
      'Finance': [
        {
          'title': 'Transaction History',
          'subtitle': 'All transactions',
          'icon': CupertinoIcons.doc_text,
          'route': '/admin/transactions',
        },
      ],
      'Others': [
        {
          'title': 'Support',
          'subtitle': 'Help center',
          'icon': CupertinoIcons.question_circle,
          'route': '/admin/support',
        },
        {
          'title': 'Calendar',
          'subtitle': 'Schedules',
          'icon': CupertinoIcons.calendar,
          'route': '/admin/calendar',
        },
        {
          'title': 'Logs',
          'subtitle': 'System activity',
          'icon': CupertinoIcons.list_bullet,
          'route': '/admin/logs',
        },
      ],
    };

    final IconData toggleViewMode = _isGridView
        ? CupertinoIcons.list_bullet
        : CupertinoIcons.square_grid_2x2;

    return AppLayout(
      title: "Open VTS",
      subtitle: "Menu",
      horizontalPadding: 5,
      actionIcons: [CupertinoIcons.square_arrow_right, toggleViewMode],
      onActionTaps: [_confirmLogout, _toggleViewMode],
      leftAvatarText: 'FS',
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(hp, hp, hp, hp * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...groupedMenu.entries.map(
              (entry) => _buildSection(
                context: context,
                category: entry.key,
                items: entry.value,
                width: width,
                hp: hp,
                colorScheme: colorScheme,
                isGridView: _isGridView,
              ),
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

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.08)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          Container(
            height: 42,
            width: 42,
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
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'You will need to log in again to continue using the Admin dashboard.',
        style: GoogleFonts.inter(
          fontSize: 14,
          height: 1.5,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.08),
                    ),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }
}
