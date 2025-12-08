// components/appbars/custom_appbar.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_utils.dart';
import '../../utils/adaptive_utils.dart'; // New import for adaptive sizes

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<IconData>? icons; // make icons optional
  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;

  CustomAppBar({
    super.key,
    required this.title,
    required String subtitle,
    this.icons, // optional now
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
  }) : subtitle = subtitle.length > 18
            ? '${subtitle.substring(0, 15)}...'
            : subtitle;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
   // final double fsAvatarFontSize = AdaptiveUtils.getFsAvatarFontSize(screenWidth);
    final double bellNotificationFontSize = AdaptiveUtils.getBellNotificationFontSize(screenWidth);
    final double rightAvatarRadius = AdaptiveUtils.getRightAvatarRadius(screenWidth);
    final double rightAvatarFontSize = AdaptiveUtils.getRightAvatarFontSize(screenWidth);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF5F5F7),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        color: const Color(0xFFF5F5F7),
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
                      showLeftAvatar
    ? Container(
        height: avatarSize,
        width: avatarSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          // Remove gradient since logo will cover it
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Image.asset(
            'assets/image/logo.png',
            fit: BoxFit.cover,
          ),
        ),
      )
    : GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          height: avatarSize,
          width: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Icon(
            Icons.arrow_back,
            size: iconSize,
            color: Colors.black,
          ),
        ),
      ),

                      SizedBox(width: leftSectionSpacing),
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
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: AppUtils.headlineSmallBase.copyWith(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black,
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
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    icon,
                                    size: iconSize,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (isBell)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        "3",
                                        style: TextStyle(
                                          color: Colors.white,
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
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: Text(
                              "AV",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: rightAvatarFontSize,
                                color: isDark ? Colors.white : Colors.black87,
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
