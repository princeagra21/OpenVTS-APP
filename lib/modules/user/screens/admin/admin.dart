import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isGridView = true;
  static const String _viewModeKey = 'more_screen_view_mode';

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool(_viewModeKey) ?? true; // default = grid
    });
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool(_viewModeKey, _isGridView);
  }

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

    /// Flat list of admin items (no section headers)
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Share Track Link',
        'subtitle': 'Generate & share live link',
        'icon': CupertinoIcons.link,
        'route': '/user/share-track',
      },
      {
        'title': 'Route Optimization',
        'subtitle': 'Optimize routes & stops',
        'icon': Icons.alt_route,
        'route': '/user/route-optimization',
      },
      {
        'title': 'Vehicles',
        'subtitle': 'Manage fleet vehicles',
        'icon': CupertinoIcons.bus,
        'route': '/user/vehicles',
      },
      {
        'title': 'Drivers',
        'subtitle': 'Driver profiles & licenses',
        'icon': CupertinoIcons.person_crop_square,
        'route': '/user/drivers',
      },
      {
        'title': 'Sub-users',
        'subtitle': 'Create & manage sub users',
        'icon': CupertinoIcons.person_2,
        'route': '/user/sub-users',
      },
      {
        'title': 'Support',
        'subtitle': 'Help center & tickets',
        'icon': CupertinoIcons.question_circle,
        'route': '/user/support',
      },
      {
        'title': 'Transactions',
        'subtitle': 'Payment & billing history',
        'icon': CupertinoIcons.doc_text,
        'route': '/user/transactions',
      },
    ];

    final IconData _toggleViewIcon =
        _isGridView ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2;

    return AppLayout(
      title: "Open VTS",
      subtitle: "Admin Menu",
      horizontalPadding: 5,
      actionIcons: [_toggleViewIcon],
      onActionTaps: [
        _toggleViewMode,
      ],
      leftAvatarText: 'AD',
      child: MediaQuery.removePadding(  // Added this to remove automatic top safe area padding
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
                isGridView: _isGridView,
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