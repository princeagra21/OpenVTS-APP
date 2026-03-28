import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SuperadminProfile? _profile;
  bool _loadingProfile = false;
  CancelToken? _profileToken;
  ApiClient? _apiClient;
  SuperadminRepository? _repo;
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _profileToken?.cancel('HomeScreen disposed');
    super.dispose();
  }

  void _ensureRepo() {
    if (_apiClient != null) return;
    final config = AppConfig.fromDartDefine();
    _apiClient = ApiClient(
      config: config,
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo = SuperadminRepository(api: _apiClient!);
    _baseUrl = _apiClient!.dio.options.baseUrl.trim();
  }

  Future<void> _loadProfile() async {
    _profileToken?.cancel('Reload home profile');
    final token = CancelToken();
    _profileToken = token;

    if (!mounted) return;
    setState(() => _loadingProfile = true);

    try {
      _ensureRepo();
      final res = await _repo!.getSuperadminProfile(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (profile) => setState(() {
          _profile = profile;
          _loadingProfile = false;
        }),
        failure: (_) => setState(() {
          _profile = null;
          _loadingProfile = false;
        }),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loadingProfile = false;
      });
    }
  }

  String _display(String? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _initials(String name, String username) {
    final source = name.isNotEmpty ? name : username;
    final clean = source.replaceAll('@', ' ').trim();
    if (clean.isEmpty) return '--';
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  String _appTitle() => 'FLEET STACK';

  String _buildAbsoluteUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }
    if (_baseUrl.isEmpty) return '';
    if (value.startsWith('/')) return '$_baseUrl$value';
    return '$_baseUrl/$value';
  }

  String _extractProfileImageUrl(SuperadminProfile? profile) {
    if (profile == null) return '';
    final raw = profile.raw;
    final List<Map<String, dynamic>> sources = [];

    sources.add(raw);
    final level1 = raw['data'];
    if (level1 is Map) {
      final level1Map = Map<String, dynamic>.from(level1.cast());
      sources.add(level1Map);
      final level2 = level1Map['data'];
      if (level2 is Map) {
        sources.add(Map<String, dynamic>.from(level2.cast()));
      }
    }

    final keys = [
      'profileUrl',
      'profileurl',
      'profile_url',
      'avatarUrl',
      'avatar_url',
      'avatar',
      'photoUrl',
      'photo_url',
      'imageUrl',
      'image_url',
      'profileImage',
      'profile_image',
    ];

    for (final map in sources) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isEmpty) continue;
        return _buildAbsoluteUrl(text);
      }
    }

    return '';
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
    final double rightAvatarRadius = AdaptiveUtils.getRightAvatarRadius(
      screenWidth,
    );
    final double rightAvatarFontSize = AdaptiveUtils.getRightAvatarFontSize(
      screenWidth,
    );
    final double titleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double subtitleFontSize = AdaptiveUtils.getSubtitleFontSize(
      screenWidth,
    );

    final double gridGap = hp * 1.3;
    final double tileSize =
        (screenWidth - (hp * 2) - (gridGap * 2)) / 3;
    final double labelFontSize = titleFontSize + 1;
    final double labelHeight = labelFontSize + AppUtils.spacingSmall;
    final double gridAspectRatio = tileSize / (tileSize + labelHeight);

    final String logoAsset = isDark
        ? 'assets/image/logo-dark.png'
        : 'assets/image/logo-light.png';

    final profile = _profile;
    final appTitle = _appTitle();
    final displayName = _display(profile?.fullName);
    final username = _display(profile?.username);
    final initials = _initials(displayName, username);
    final profileImageUrl = _extractProfileImageUrl(profile);
    final footerText = '$appTitle Super Admin';
    final roleLabel = _display(profile?.roleName, fallback: 'Super Admin');

    final List<_HomeShortcut> shortcuts = [
      _HomeShortcut(
        label: 'Dashboard',
        icon: Symbols.finance,
        route: '/superadmin/dashboard',
      ),
      _HomeShortcut(
        label: 'Administrators',
        icon: Symbols.verified_user,
        route: '/superadmin/admins',
      ),
      _HomeShortcut(
        label: 'Vehicles',
        icon: Symbols.sync_alt,
        route: '/superadmin/vehicles',
      ),
      _HomeShortcut(
        label: 'Map',
        icon: Symbols.map,
        route: '/superadmin/map',
      ),
      _HomeShortcut(
        label: 'Calendar',
        icon: Symbols.date_range,
        route: '/superadmin/calendar',
      ),
      _HomeShortcut(
        label: 'Server',
        icon: Symbols.dns,
        route: '/superadmin/server',
      ),
      _HomeShortcut(
        label: 'Support',
        icon: Symbols.help,
        route: '/superadmin/support',
      ),
      _HomeShortcut(
        label: 'Payments',
        icon: Symbols.credit_card,
        route: '/superadmin/payments',
      ),
      _HomeShortcut(
        label: 'Settings',
        icon: Symbols.brightness_5,
        route: '/superadmin/settings',
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
                      style: AppUtils.headlineSmallBase.copyWith(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Roboto',
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
                    onTap: () => context.push('/superadmin/notifications'),
                  ),
                  SizedBox(width: AppUtils.spacingSmall),
                  Row(
                    children: [
                      _ProfileAvatar(
                        radius: rightAvatarRadius,
                        fontSize: rightAvatarFontSize,
                        colorScheme: cs,
                        imageUrl: profileImageUrl,
                        initials: initials,
                        loading: _loadingProfile,
                      ),
                      SizedBox(width: AppUtils.spacingSmall),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: (screenWidth * 0.22).clamp(80, 140),
                            child: Text(
                              displayName.isNotEmpty ? displayName : username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppUtils.bodySmallBase.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Roboto',
                                color: cs.onSurface.withOpacity(0.85),
                              ),
                            ),
                          ),
                          SizedBox(height: AppUtils.spacingExtraSmall),
                          Text(
                            roleLabel,
                            style: AppUtils.bodySmallBase.copyWith(
                              fontSize: labelFontSize - 1,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Roboto',
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                hp,
                AppUtils.spacingMedium,
                hp * 0.5,
                AppUtils.spacingLarge,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppUtils.spacingLarge),
                    Center(
                      child: Image.asset(
                        logoAsset,
                        width: (screenWidth * 0.45).clamp(140, 200),
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: AppUtils.spacingLarge * 1.5),
                    Wrap(
                      alignment: WrapAlignment.center,
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
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  hp,
                  0,
                  hp,
                  AppUtils.spacingMedium,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    footerText,
                    textAlign: TextAlign.center,
                    style: AppUtils.bodySmallBase.copyWith(
                      color: cs.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Intentionally commented out for the new Super Admin Home layout.
      // bottomNavigationBar: const CustomBottomBar(),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.onSurface.withOpacity(0.2),
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
            style: AppUtils.bodySmallBase.copyWith(
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
  final String imageUrl;
  final String initials;
  final bool loading;

  const _ProfileAvatar({
    required this.radius,
    required this.fontSize,
    required this.colorScheme,
    required this.imageUrl,
    required this.initials,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      final double size = radius * 2;
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primaryContainer,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) => _InitialsAvatar(
              radius: radius,
              fontSize: fontSize,
              colorScheme: colorScheme,
              initials: initials,
            ),
          ),
        ),
      );
    }

    return _InitialsAvatar(
      radius: radius,
      fontSize: fontSize,
      colorScheme: colorScheme,
      initials: loading ? '--' : initials,
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final double radius;
  final double fontSize;
  final ColorScheme colorScheme;
  final String initials;

  const _InitialsAvatar({
    required this.radius,
    required this.fontSize,
    required this.colorScheme,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
