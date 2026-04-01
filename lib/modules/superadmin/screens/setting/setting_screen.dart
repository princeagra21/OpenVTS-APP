import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _settingsViewKey = 'superadmin_settings_view_mode';
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
      _isGridView = prefs.getBool(_settingsViewKey) ?? true;
    });
  }

  Future<void> _toggleViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isGridView = !_isGridView;
    });
    await prefs.setBool(_settingsViewKey, _isGridView);
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
        return _SettingsMenuCard(
          title: item['title'],
          subtitle: item['subtitle'],
          icon: item['icon'],
          route: item['route'],
          isListMode: !isGridView,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) * 1.5;

    final List<Map<String, dynamic>> settingsItems = [
      {
        'title': 'Profile',
        'subtitle': 'Manage profile',
        'icon': CupertinoIcons.person,
        'route': '/superadmin/profile',
      },
      {
        'title': 'White Label',
        'subtitle': 'Brand customization',
        'icon': CupertinoIcons.paintbrush,
        'route': '/superadmin/white-label',
      },
      // {
      //   'title': 'Branding',
      //   'subtitle': 'Company branding',
      //   'icon': CupertinoIcons.briefcase,
      //   'route': '/superadmin/branding',
      // },
      {
        'title': 'API Config',
        'subtitle': 'Configure APIs',
        'icon': CupertinoIcons.cloud,
        'route': '/superadmin/api-config',
      },
      {
        'title': 'SMTP Settings',
        'subtitle': 'Email settings',
        'icon': CupertinoIcons.mail,
        'route': '/superadmin/smtp-settings',
      },
      {
        'title': 'Localization',
        'subtitle': 'Language & region',
        'icon': CupertinoIcons.globe,
        'route': '/superadmin/localization',
      },
      {
        'title': 'App Preferences',
        'subtitle': 'App preferences',
        'icon': CupertinoIcons.settings,
        'route': '/superadmin/application-settings',
      },
      {
        'title': 'Update User Policy',
        'subtitle': 'User policy',
        'icon': CupertinoIcons.doc_text,
        'route': '/superadmin/user-policy',
      },
    ];

    final IconData toggleIcon =
        _isGridView ? CupertinoIcons.list_bullet : CupertinoIcons.square_grid_2x2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Settings",
      actionIcons: [toggleIcon, CupertinoIcons.bell],
      onActionTaps: [
        _toggleViewMode,
        () => context.push('/superadmin/notifications'),
      ],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Settings",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 4,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.85),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: hp * 1.2),
          _buildItemsBlock(
            context: context,
            items: settingsItems,
            width: width,
            hp: hp,
            isGridView: _isGridView,
          ),
        ],
      ),
    );
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
          child: isListMode
              ? Row(
                  children: [
                    Container(
                      height: containerSize,
                      width: containerSize,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: innerIconSize,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: hp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                              color:
                                  colorScheme.onSurface.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: containerSize,
                      width: containerSize,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: innerIconSize,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: hp),
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        color: colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
