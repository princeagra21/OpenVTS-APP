import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/role_notifications_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/utils/app_logo.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_utils.dart';
import '../../utils/adaptive_utils.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<IconData>? icons;
  final List<VoidCallback>? onIconTaps;
  final bool enableBellBadge;
  final String notificationPathPrefix;
  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;
  final bool showLogo;
  final double scrollOffset;

  CustomAppBar({
    super.key,
    required this.title,
    required String subtitle,
    this.icons,
    this.onIconTaps,
    this.enableBellBadge = true,
    this.notificationPathPrefix = '/admin/notifications',
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.showLogo = false,
    this.scrollOffset = 0,
  }) : subtitle = subtitle.length > 18
           ? '${subtitle.substring(0, 15)}...'
           : subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with WidgetsBindingObserver {
  CancelToken? _badgeToken;
  Timer? _badgeRefreshTimer;
  ApiClient? _apiClient;
  RoleNotificationsRepository? _repo;
  int _unreadCount = 0;

  bool get _hasBellIcon =>
      widget.enableBellBadge &&
      (widget.icons?.any((icon) => icon == CupertinoIcons.bell) ?? false);

  String get _badgeText => _unreadCount > 9 ? '9+' : '$_unreadCount';

  RoleNotificationsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= RoleNotificationsRepository(
      api: _apiClient!,
      pathPrefix: widget.notificationPathPrefix,
    );
    return _repo!;
  }

  Future<void> _loadUnreadCount() async {
    if (!_hasBellIcon) return;

    _badgeToken?.cancel('Reload appbar notifications badge');
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
    if (!_hasBellIcon) return;
    _badgeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadUnreadCount();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnreadCount();
    _startBadgeRefresh();
  }

  @override
  void didUpdateWidget(covariant CustomAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldHasBell =
        oldWidget.enableBellBadge &&
        (oldWidget.icons?.any((icon) => icon == CupertinoIcons.bell) ?? false);
    final pathChanged =
        oldWidget.notificationPathPrefix != widget.notificationPathPrefix;
    if (_hasBellIcon != oldHasBell || pathChanged) {
      _loadUnreadCount();
      _startBadgeRefresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _badgeRefreshTimer?.cancel();
    _badgeToken?.cancel('CustomAppBar disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(
      screenWidth,
    );
    final double iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final double avatarSize = AdaptiveUtils.getAvatarSize(screenWidth);
    final double buttonSize = AdaptiveUtils.getButtonSize(screenWidth);
    final double titleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double subtitleFontSize = AdaptiveUtils.getSubtitleFontSize(
      screenWidth,
    );
    final double leftSectionSpacing = AdaptiveUtils.getLeftSectionSpacing(
      screenWidth,
    );
    final double iconPaddingLeft = AdaptiveUtils.getIconPaddingLeft(
      screenWidth,
    );
    final double rightAvatarPaddingLeft =
        AdaptiveUtils.getRightAvatarPaddingLeft(screenWidth);
    final double bellNotificationFontSize =
        AdaptiveUtils.getBellNotificationFontSize(screenWidth);
    final double rightAvatarRadius = AdaptiveUtils.getRightAvatarRadius(
      screenWidth,
    );
    final double rightAvatarFontSize = AdaptiveUtils.getRightAvatarFontSize(
      screenWidth,
    );

    final bool showTitleAndSubtitle =
        !widget.showLogo && !widget.showLeftAvatar;

    final double blurAmount = widget.scrollOffset > 20 ? 20 : 0;
    final double bgOpacity = widget.scrollOffset > 20 ? 0.7 : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            color: cs.background.withOpacity(bgOpacity),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 0,
                ),
                child: Row(
                  children: [
                    // LEFT SIDE
                    Expanded(
                      child: Row(
                        children: [
                          if (widget.showLogo)
                            SizedBox(
                              height: 45,
                              width: 230,
                                child: Image.asset(
                                  AppLogo.assetFor(context),
                                  fit: BoxFit.contain,
                                ),
                            )
                          else if (widget.showLeftAvatar)
                            SizedBox(
                              height: 45,
                              width: 230,
                                child: Image.asset(
                                  AppLogo.assetFor(context),
                                  fit: BoxFit.contain,
                                ),
                            )
                          else
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                height: avatarSize,
                                width: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.surface,
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.shadow.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  size: iconSize,
                                  color: cs.primary,
                                ),
                              ),
                            ),

                          if (showTitleAndSubtitle)
                            SizedBox(width: leftSectionSpacing),

                          if (showTitleAndSubtitle)
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: AppUtils.subtitleBase.copyWith(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.subtitle,
                                      style: AppUtils.headlineSmallBase
                                          .copyWith(
                                            fontSize: subtitleFontSize,
                                            fontWeight: FontWeight.w900,
                                            color: cs.onBackground,
                                            letterSpacing: -0.5,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // RIGHT SIDE
                    if ((widget.icons != null && widget.icons!.isNotEmpty) ||
                        widget.showRightAvatar)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icons != null)
                            ...widget.icons!.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final IconData icon = entry.value;
                              final bool isBell = icon == CupertinoIcons.bell;

                              return Padding(
                                padding: EdgeInsets.only(left: iconPaddingLeft),
                                child: GestureDetector(
                                  onTap:
                                      widget.onIconTaps != null &&
                                          index < widget.onIconTaps!.length
                                      ? widget.onIconTaps![index]
                                      : null,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        height: buttonSize,
                                        width: buttonSize,
                                        decoration: BoxDecoration(
                                          color: cs.surface,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: cs.shadow.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          icon,
                                          size: iconSize,
                                          color: cs.primary,
                                        ),
                                      ),

                                      // ONLY SHOW BADGE ON BELL
                                      if (isBell && _unreadCount > 0)
                                        Positioned(
                                          top: -buttonSize * 0.15,
                                          right: -buttonSize * 0.15,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              _badgeText,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: cs.onPrimary,
                                                fontSize:
                                                    bellNotificationFontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),

                          if (widget.showRightAvatar)
                            Padding(
                              padding: EdgeInsets.only(
                                left: rightAvatarPaddingLeft,
                              ),
                              child: CircleAvatar(
                                radius: rightAvatarRadius,
                                backgroundColor: cs.primaryContainer,
                                child: Text(
                                  "AV",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: rightAvatarFontSize,
                                    color: cs.onPrimaryContainer,
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
          ),
        ),
      ),
    );
  }
}
