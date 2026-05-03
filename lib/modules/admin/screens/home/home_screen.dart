import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_profile_repository.dart';
import 'package:fleet_stack/core/repositories/role_notifications_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/utils/app_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CancelToken? _badgeToken;
  Timer? _badgeRefreshTimer;
  ApiClient? _apiClient;
  RoleNotificationsRepository? _repo;
  int _unreadCount = 0;
  AdminProfile? _profile;
  bool _loadingProfile = false;
  CancelToken? _profileToken;
  AdminProfileRepository? _profileRepo;

  String get _badgeText => _unreadCount > 9 ? '9+' : '$_unreadCount';

  RoleNotificationsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= RoleNotificationsRepository(
      api: _apiClient!,
      pathPrefix: '/admin/notifications',
    );
    return _repo!;
  }

  AdminProfileRepository _profileRepoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _profileRepo ??= AdminProfileRepository(api: _apiClient!);
    return _profileRepo!;
  }

  Future<void> _loadUnreadCount() async {
    _badgeToken?.cancel('Reload home notifications badge');
    final token = CancelToken();
    _badgeToken = token;

    _repo = null;
    final result = await _repoOrCreate().getNotifications(cancelToken: token);
    if (!mounted) return;

    result.when(
      success: (items) {
        final unread = items.where((item) => !item.isRead).length;
        if (!mounted) return;
        setState(() => _unreadCount = unread);
      },
      failure: (_) {
        if (!mounted) return;
        setState(() => _unreadCount = 0);
      },
    );
  }

  void _startBadgeRefresh() {
    _badgeRefreshTimer?.cancel();
    _badgeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadUnreadCount();
    });
  }

  Future<void> _loadProfile() async {
    _profileToken?.cancel('Reload profile');
    final token = CancelToken();
    _profileToken = token;

    if (!mounted) return;
    setState(() => _loadingProfile = true);

    try {
      final res = await _profileRepoOrCreate().getMyProfile(
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          setState(() {
            _profile = profile;
            _loadingProfile = false;
          });
        },
        failure: (error) {
          if (error is ApiException &&
              (error.statusCode == 401 || error.statusCode == 403)) {
            if (!mounted) return;
            setState(() {
              _profile = null;
              _loadingProfile = false;
            });
            return;
          }
          if (!mounted) return;
          setState(() {
            _profile = null;
            _loadingProfile = false;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loadingProfile = false;
      });
    }
  }

  String _initials(String name, String username) {
    final source = name.isNotEmpty ? name : username;
    final clean = source.replaceAll('@', ' ').trim();
    if (clean.isEmpty) return '--';
    final parts =
        clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmDialog(),
    );
    if (shouldLogout != true) return;
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

  Future<void> _showProfileMenu({
    required BuildContext anchorContext,
    required String displayName,
    required String initials,
  }) async {
    final box = anchorContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final media = MediaQuery.of(context);
    final topOffset =
        media.padding.top + AppUtils.appBarHeightCustom + 12 + 8;
    final rightEdge = overlay.size.width - 12;
    final menuWidth = 200.0;
    final position = RelativeRect.fromLTRB(
      rightEdge - menuWidth,
      topOffset,
      12,
      overlay.size.height - topOffset,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: SizedBox(
            width: menuWidth,
            child: Row(
              children: [
                _ProfileAvatar(
                  radius: 22,
                  fontSize: 14,
                  colorScheme: Theme.of(context).colorScheme,
                  initials: initials,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName.isNotEmpty ? displayName : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Text(
                      //   roleLabel,
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: GoogleFonts.roboto(
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w500,
                      //     color: Theme.of(context)
                      //         .colorScheme
                      //         .onSurface
                      //         .withOpacity(0.6),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuDivider(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
        PopupMenuItem<String>(
          value: 'profile',
          height: 36,
          child: Row(
            children: const [
              Expanded(child: Text('Profile')),
              Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
        PopupMenuDivider(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          height: 36,
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              Icon(Icons.logout, size: 18, color: Colors.red),
            ],
          ),
        ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected == 'profile') {
      context.push('/admin/settings');
    } else if (selected == 'logout') {
      await _confirmLogout();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _startBadgeRefresh();
    _loadProfile();
  }

  @override
  void dispose() {
    _badgeRefreshTimer?.cancel();
    _badgeToken?.cancel('HomeScreen disposed');
    _profileToken?.cancel('HomeScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = theme.brightness == Brightness.dark;

    final double hp = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final double buttonSize = AdaptiveUtils.getButtonSize(screenWidth);
    final double subtitleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double bellNotificationFontSize =
        AdaptiveUtils.getBellNotificationFontSize(screenWidth);

    final double gridGap = hp * 1.3;
    final double tileSize = (screenWidth - (hp * 2) - (gridGap * 2)) / 3;
    final double labelFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    final String logoAsset = AppLogo.assetFor(context);

    const footerText = '© 2026 Open VTS All rights reserved.';

    final List<_HomeShortcut> shortcuts = [
      _HomeShortcut(
        label: 'Dashboard',
        icon: Symbols.dashboard,
        route: '/admin/dashboard',
      ),
      _HomeShortcut(label: 'Users', icon: Symbols.group, route: '/admin/users'),
      _HomeShortcut(
        label: 'Vehicles',
        icon: Symbols.directions_car,
        route: '/admin/vehicles',
      ),
      _HomeShortcut(
        label: 'Drivers',
        icon: Symbols.badge,
        route: '/admin/drivers',
      ),
      _HomeShortcut(label: 'Team', icon: Symbols.groups, route: '/admin/teams'),
      _HomeShortcut(
        label: 'Inventory',
        icon: Symbols.inventory_2,
        route: '/admin/inventory',
      ),
      _HomeShortcut(label: 'Maps', icon: Symbols.map, route: '/admin/map'),
      _HomeShortcut(
        label: 'Transactions',
        icon: Symbols.receipt_long,
        route: '/admin/transactions',
      ),
      _HomeShortcut(
        label: 'Payments',
        icon: Symbols.credit_card,
        route: '/admin/payments',
      ),
      _HomeShortcut(
        label: 'Support',
        icon: Symbols.help,
        route: '/admin/support',
      ),
      _HomeShortcut(
        label: 'Calendar',
        icon: Symbols.date_range,
        route: '/admin/calendar',
      ),
      _HomeShortcut(label: 'Logs', icon: Symbols.list_alt, route: '/admin/logs'),
      _HomeShortcut(
        label: 'Plans',
        icon: Symbols.widgets,
        route: '/admin/plans',
      ),
      // _HomeShortcut(
      //   label: 'Roles',
      //   icon: Symbols.admin_panel_settings,
      //   route: '/admin/roles',
      // ),
      _HomeShortcut(
        label: 'Settings',
        icon: Symbols.settings,
        route: '/admin/settings',
      ),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        toolbarHeight: AppUtils.appBarHeightCustom + 12,
        titleSpacing: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppUtils.spacingExtraSmall),
                    Text(
                      'Fleet OS',
                      style: GoogleFonts.roboto(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _HeaderIconButton(
                    icon: CupertinoIcons.bell,
                    size: buttonSize,
                    iconSize: iconSize,
                    colorScheme: cs,
                    badgeText: _badgeText,
                    showBadge: _unreadCount > 0,
                    badgeFontSize: bellNotificationFontSize,
                    onTap: () async {
                      await context.push('/admin/notifications');
                      if (!mounted) return;
                      _loadUnreadCount();
                    },
                  ),
                  SizedBox(width: AppUtils.spacingSmall),
                  Builder(
                    builder: (avatarContext) => InkWell(
                      borderRadius: BorderRadius.circular(buttonSize / 2),
                      onTap: () {
                        final profile = _profile;
                        final name = profile?.fullName.trim() ?? '';
                        final username = profile?.username.trim() ?? '';
                        final displayName =
                            name.isNotEmpty ? name : username;
                        _showProfileMenu(
                          anchorContext: avatarContext,
                          displayName: displayName,
                          initials: _initials(name, username),
                        );
                      },
                      child: _ProfileAvatar(
                        radius: AdaptiveUtils.getRightAvatarRadius(screenWidth),
                        fontSize:
                            AdaptiveUtils.getRightAvatarFontSize(screenWidth),
                        colorScheme: cs,
                        initials: _initials(
                          _profile?.fullName ?? '',
                          _profile?.username ?? '',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    hp,
                    AppUtils.spacingMedium,
                    hp * 0.5,
                    AppUtils.spacingLarge,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppUtils.spacingSmall),
                        Center(
                          child: Image.asset(
                            logoAsset,
                            width: (screenWidth * 0.45).clamp(140, 200),
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: AppUtils.spacingLarge),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: gridGap,
                          runSpacing: gridGap,
                          children: shortcuts.map((item) {
                            return SizedBox(
                              width: tileSize,
                              child: _HomeShortcutTile(
                                item: item,
                                tileSize: tileSize,
                                labelFontSize: labelFontSize,
                                colorScheme: cs,
                                onTap: () => context.go(item.route),
                              ),
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                        Text(
                          footerText,
                          textAlign: TextAlign.center,
                          style: AppUtils.bodySmallBase.copyWith(
                            color: cs.onSurface.withOpacity(0.55),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final ColorScheme colorScheme;
  final bool showBadge;
  final String badgeText;
  final double badgeFontSize;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.colorScheme,
    required this.showBadge,
    required this.badgeText,
    required this.badgeFontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.2),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: colorScheme.primary,
            ),
          ),
          if (showBadge)
            Positioned(
              top: -size * 0.15,
              right: -size * 0.15,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeShortcut {
  final String label;
  final IconData icon;
  final String route;

  const _HomeShortcut({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class _HomeShortcutTile extends StatelessWidget {
  final _HomeShortcut item;
  final double tileSize;
  final double labelFontSize;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _HomeShortcutTile({
    required this.item,
    required this.tileSize,
    required this.labelFontSize,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color neutralColor = cs.onSurface.withOpacity(isDark ? 0.86 : 0.75);
    final double iconContainerSize = tileSize * 0.6;
    final double iconSize = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 20
        : AdaptiveUtils.isSmallScreen(screenWidth)
            ? 22
            : 24;
    return InkWell(
      onTap: onTap,
      borderRadius: AppUtils.borderRadiusMedium,
      splashColor: cs.surfaceVariant.withOpacity(0.4),
      highlightColor: cs.surfaceVariant.withOpacity(0.4),
      hoverColor: cs.surfaceVariant.withOpacity(0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: iconContainerSize,
            width: iconContainerSize,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              border: Border.all(
                color: cs.onSurface.withOpacity(0.2),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              item.icon,
              size: iconSize,
              color: cs.primary,
            ),
          ),
          SizedBox(height: AppUtils.spacingSmall),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              color: neutralColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final double fontSize;
  final ColorScheme colorScheme;
  final String initials;

  const _ProfileAvatar({
    required this.radius,
    required this.fontSize,
    required this.colorScheme,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final double size = radius * 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade50
            : colorScheme.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.2),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
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
                    style: GoogleFonts.roboto(
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
              style: GoogleFonts.roboto(
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
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
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
                      style: GoogleFonts.roboto(fontWeight: FontWeight.w700),
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
