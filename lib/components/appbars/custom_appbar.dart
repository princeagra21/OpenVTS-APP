import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_utils.dart';
import '../../utils/adaptive_utils.dart';
import 'dart:ui';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<IconData>? icons;
  final List<VoidCallback>? onIconTaps; // NEW: Tap handlers for icons
  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;
  final bool showLogo;

  /// NEW: Scroll offset from NotificationListener
  final double scrollOffset;

  CustomAppBar({
    super.key,
    required this.title,
    required String subtitle,
    this.icons,
    this.onIconTaps, // NEW
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.showLogo = false,
    this.scrollOffset = 0, // Default value
  }) : subtitle = subtitle.length > 18
            ? '${subtitle.substring(0, 15)}...'
            : subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    // Blur effect based on scroll
    final double blurAmount = scrollOffset > 20 ? 20 : 0;
    final double bgOpacity = scrollOffset > 20 ? 0.7 : 0.0;

    final double horizontalPadding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final double avatarSize = AdaptiveUtils.getAvatarSize(screenWidth);
    final double buttonSize = AdaptiveUtils.getButtonSize(screenWidth);
    final double titleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double subtitleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double leftSectionSpacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final double iconPaddingLeft = AdaptiveUtils.getIconPaddingLeft(screenWidth);
    final double rightAvatarPaddingLeft = AdaptiveUtils.getRightAvatarPaddingLeft(screenWidth);
    final double bellNotificationFontSize = AdaptiveUtils.getBellNotificationFontSize(screenWidth);
    final double rightAvatarRadius = AdaptiveUtils.getRightAvatarRadius(screenWidth);
    final double rightAvatarFontSize = AdaptiveUtils.getRightAvatarFontSize(screenWidth);

    final bool showTitleAndSubtitle = !showLogo && !showLeftAvatar;

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
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
                child: Row(
                  children: [
                    // LEFT SIDE
                    Expanded(
                      child: Row(
                        children: [
                          if (showLogo)
                            SizedBox(
                              height: 45,
                              width: 230,
                              child: Image.asset(
                                'image/logo.jpeg',
                                fit: BoxFit.contain,
                              ),
                            )
                          else if (showLeftAvatar)
                            SizedBox(
                              height: 45,
                              width: 180,
                              child: Image.asset(
                                'image/logo.jpeg',
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
                                    )
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
                                      title,
                                      style: AppUtils.subtitleBase.copyWith(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: AppUtils.headlineSmallBase.copyWith(
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
                    if ((icons != null && icons!.isNotEmpty) || showRightAvatar)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icons != null)
                            ...icons!.asMap().entries.map((entry) { // NEW: Use asMap for index
                              final int index = entry.key;
                              final IconData icon = entry.value;
                              final isBell = icon == CupertinoIcons.bell;

                              return Padding(
                                padding: EdgeInsets.only(left: iconPaddingLeft),
                                child: GestureDetector( // NEW: Wrap in GestureDetector for tap
                                  onTap: onIconTaps != null && index < onIconTaps!.length
                                      ? onIconTaps![index]
                                      : null, // If no tap handler, do nothing
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
                                      if (isBell)
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: cs.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              "3",
                                              style: TextStyle(
                                                color: cs.onPrimary,
                                                fontSize: bellNotificationFontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),

                          if (showRightAvatar)
                            Padding(
                              padding: EdgeInsets.only(left: rightAvatarPaddingLeft),
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