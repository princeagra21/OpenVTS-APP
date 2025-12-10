import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_utils.dart';
import '../../utils/adaptive_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<IconData>? icons;
  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;
  final bool showLogo; // New property for controlling logo display

  CustomAppBar({
    super.key,
    required this.title,
    required String subtitle,
    this.icons,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.showLogo = false, // Default value for the new property
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

    // Determines if the title/subtitle should be shown
    final bool showTitleAndSubtitle = !showLogo && !showLeftAvatar;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: cs.background,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: cs.background,
              statusBarIconBrightness: Brightness.dark,
            ),
      child: Container(
        color: Colors.transparent,
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
                      // --- LOGO (New requirement: Replaces avatar/back button when needed) ---
                      if (showLogo)
                        // Logo container with fixed dimensions (45x230)
                        SizedBox(
                          height: 45,
                          width: 230,
                          child: Image.asset(
                            'assets/image/logo.jpeg', // Assuming logo is at this path
                            fit: BoxFit.contain, // Use contain to respect aspect ratio within bounds
                          ),
                        )
                      // --- LEFT AVATAR (Requirement: Image only, no title/subtitle) ---
                      else if (showLeftAvatar)
                        Container(
                          height: avatarSize,
                          width: avatarSize,
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/image/logo.png', // Assuming this is the avatar image path
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      // --- BACK BUTTON (Default when no logo/avatar is shown) ---
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
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),

                      // --- TITLE AND SUBTITLE (Only show if neither logo nor left avatar is active) ---
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

                // RIGHT SIDE (remains unchanged)
                if ((icons != null && icons!.isNotEmpty) || showRightAvatar)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icons != null)
                        ...icons!.map((icon) {
                          final isBell = icon == CupertinoIcons.bell;

                          return Padding(
                            padding: EdgeInsets.only(left: iconPaddingLeft),
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
                                    color: Theme.of(context).colorScheme.primary,
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
    );
  }
}