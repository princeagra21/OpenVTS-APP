import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/shell/presentation/providers/app_bar_notification_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_logo.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/shell/presentation/widgets/open_vts_page_title_bar.dart';

enum OpenVtsAppBarVariant { standard, home }

class OpenVtsAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  OpenVtsAppBar({
    super.key,
    required this.title,
    required String subtitle,
    this.icons,
    this.onIconTaps,
    this.enableBellBadge = true,
    this.notificationPathPrefix,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.showLogo = false,
    this.scrollOffset = 0,
    this.variant = OpenVtsAppBarVariant.standard,
    this.leadingIcon,
    this.onClose,
    this.showLeading = true,
    this.borderRadius = 16,
  }) : subtitle =
            subtitle.length > 18 ? '${subtitle.substring(0, 15)}...' : subtitle;

  final String title;
  final String subtitle;
  final List<IconData>? icons;
  final List<VoidCallback>? onIconTaps;
  final bool enableBellBadge;
  final String? notificationPathPrefix;
  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;
  final bool showLogo;
  final double scrollOffset;

  final OpenVtsAppBarVariant variant;
  final IconData? leadingIcon;
  final VoidCallback? onClose;
  final bool showLeading;
  final double borderRadius;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  ConsumerState<OpenVtsAppBar> createState() => _OpenVtsAppBarState();
}

class _OpenVtsAppBarState extends ConsumerState<OpenVtsAppBar>
    with WidgetsBindingObserver {
  Timer? _badgeRefreshTimer;

  bool get _hasBellIcon {
    return widget.variant == OpenVtsAppBarVariant.standard &&
        widget.enableBellBadge &&
        (widget.icons?.any((icon) => icon == CupertinoIcons.bell) ?? false) &&
        widget.notificationPathPrefix != null &&
        widget.notificationPathPrefix!.trim().isNotEmpty;
  }

  String _badgeText(int unreadCount) => unreadCount > 9 ? '9+' : '$unreadCount';

  int _watchUnreadCount() {
    if (!_hasBellIcon) return 0;
    final pathPrefix = widget.notificationPathPrefix?.trim() ?? '';
    if (pathPrefix.isEmpty) return 0;
    return ref.watch(appBarUnreadCountProvider(pathPrefix)).maybeWhen(
          data: (count) => count,
          orElse: () => 0,
        );
  }

  void _reloadUnreadCount() {
    if (!_hasBellIcon || !mounted) return;
    final pathPrefix = widget.notificationPathPrefix?.trim() ?? '';
    if (pathPrefix.isEmpty) return;
    ref.read(appBarNotificationBadgeControllerProvider(pathPrefix)).reload();
  }

  void _scheduleUnreadCountReload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reloadUnreadCount();
    });
  }

  void _startBadgeRefresh() {
    _badgeRefreshTimer?.cancel();
    if (!_hasBellIcon) return;
    _badgeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _reloadUnreadCount();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startBadgeRefresh();
  }

  @override
  void didUpdateWidget(covariant OpenVtsAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldHasBell = oldWidget.variant == OpenVtsAppBarVariant.standard &&
        oldWidget.enableBellBadge &&
        (oldWidget.icons?.any((icon) => icon == CupertinoIcons.bell) ??
            false) &&
        oldWidget.notificationPathPrefix != null;

    final pathChanged =
        oldWidget.notificationPathPrefix != widget.notificationPathPrefix;

    if (_hasBellIcon != oldHasBell || pathChanged) {
      _startBadgeRefresh();
      _scheduleUnreadCountReload();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleUnreadCountReload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _badgeRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == OpenVtsAppBarVariant.home) {
      return _buildHomeStyle(context);
    }
    return _buildStandardStyle(context, unreadCount: _watchUnreadCount());
  }

  Widget _buildHomeStyle(BuildContext context) {
    return OpenVtsPageTitleBar(
      title: widget.title,
      leadingIcon: widget.leadingIcon ?? Icons.apps_outlined,
      onClose: widget.onClose,
      borderRadius: widget.borderRadius,
    );
  }

  Widget _buildStandardStyle(BuildContext context, {required int unreadCount}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final avatarSize = AdaptiveUtils.getAvatarSize(screenWidth);
    final buttonSize = AdaptiveUtils.getButtonSize(screenWidth);
    final titleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final subtitleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final leftSectionSpacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final iconPaddingLeft = AdaptiveUtils.getIconPaddingLeft(screenWidth);
    final rightAvatarPaddingLeft = AdaptiveUtils.getRightAvatarPaddingLeft(
      screenWidth,
    );
    final bellNotificationFontSize = AdaptiveUtils.getBellNotificationFontSize(
      screenWidth,
    );
    final rightAvatarRadius = AdaptiveUtils.getRightAvatarRadius(screenWidth);
    final rightAvatarFontSize = AdaptiveUtils.getRightAvatarFontSize(
      screenWidth,
    );

    final showTitleAndSubtitle = !widget.showLogo && !widget.showLeftAvatar;

    final blurAmount = widget.scrollOffset > 20 ? 20.0 : 0.0;
    final bgOpacity = widget.scrollOffset > 20 ? 0.7 : 0.0;

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
            color: cs.surface.withValues(alpha: bgOpacity),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 0,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          if (widget.showLogo || widget.showLeftAvatar)
                            SizedBox(
                              height: 45,
                              width: 230,
                              child: Image.asset(
                                AppLogo.assetFor(context),
                                fit: BoxFit.contain,
                              ),
                            )
                          else if (widget.showLeading)
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                height: avatarSize,
                                width: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.surface,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: cs.shadow.withValues(alpha: 0.15),
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
                                  children: <Widget>[
                                    Text(
                                      widget.title,
                                      style: AppUtils.subtitleBase.copyWith(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.subtitle,
                                      style:
                                          AppUtils.headlineSmallBase.copyWith(
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: cs.onSurface,
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
                    if ((widget.icons != null && widget.icons!.isNotEmpty) ||
                        widget.showRightAvatar)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (widget.icons != null)
                            ...widget.icons!.asMap().entries.map((entry) {
                              final index = entry.key;
                              final icon = entry.value;
                              final isBell = icon == CupertinoIcons.bell;

                              return Padding(
                                padding: EdgeInsets.only(left: iconPaddingLeft),
                                child: GestureDetector(
                                  onTap: widget.onIconTaps != null &&
                                          index < widget.onIconTaps!.length
                                      ? widget.onIconTaps![index]
                                      : null,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: <Widget>[
                                      Container(
                                        height: buttonSize,
                                        width: buttonSize,
                                        decoration: BoxDecoration(
                                          color: cs.surface,
                                          shape: BoxShape.circle,
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: cs.shadow.withValues(
                                                alpha: 0.1,
                                              ),
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
                                      if (isBell && unreadCount > 0)
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
                                              _badgeText(unreadCount),
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
                                  'AV',
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
