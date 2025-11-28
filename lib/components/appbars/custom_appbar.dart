// components/appbars/custom_appbar.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_utils.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final List<IconData> icons;
final bool showLeftAvatar;
final bool showRightAvatar;

  CustomAppBar({
  super.key,
  required this.title,
  required String subtitle,
  required this.icons,
  this.showLeftAvatar = true,   // FS avatar default true
  this.showRightAvatar = false, // AV avatar default false
}) : subtitle = subtitle.length > 18
          ? '${subtitle.substring(0, 15)}...'
          : subtitle;
  /// 🔥 FIX: Remove big gap between AppBar & body by enforcing smaller height
  @override
  Size get preferredSize => const Size.fromHeight(56); // compact height

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isSmallScreen = screenWidth < 420;
    final bool isVerySmallScreen = screenWidth < 360;

    // Adaptive compact sizing
    final double horizontalPadding =
        isVerySmallScreen ? 8 : isSmallScreen ? 12 : 16;

    final double iconSize = isVerySmallScreen ? 16 : isSmallScreen ? 18 : 20;
    final double avatarSize =
        isVerySmallScreen ? 26 : isSmallScreen ? 30 : 32;

    final double buttonSize =
        isVerySmallScreen ? 28 : isSmallScreen ? 32 : 36;

    final double titleFontSize =
        isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13;

    final double subtitleFontSize =
        isVerySmallScreen ? 14 : isSmallScreen ? 16 : 18;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF5F5F7),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        color: const Color(0xFFF5F5F7),

        /// 🔥 FIX: SafeArea bottom removed to eliminate white gap
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 6, // 🔥 compact height
            ),
            child: Row(
              children: [
             // LEFT SIDE
Expanded(
  child: Row(
    children: [

      /// FS AVATAR or BACK BUTTON
      showLeftAvatar
          ? Container(
              height: avatarSize,
              width: avatarSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.black],
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: Colors.black,
                child: Text(
                  "FS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isVerySmallScreen
                        ? 9
                        : isSmallScreen
                            ? 11
                            : 12,
                  ),
                ),
              ),
            )
          : GestureDetector(
              onTap: () => context.pop(), // go_router BACK
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

      SizedBox(
        width: isVerySmallScreen ? 6 : isSmallScreen ? 8 : 10,
      ),

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
                                  color:
                                      isDark ? Colors.white : Colors.black,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...icons.map((icon) {
                      final isBell = icon == CupertinoIcons.bell;

                      return Padding(
                        padding: EdgeInsets.only(
                            left: isVerySmallScreen ? 6 : isSmallScreen ? 8 : 12),
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
                                      fontSize:
                                          isVerySmallScreen ? 9 : 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                     // Optional avatar
              // RIGHT SIDE AVATAR (ONLY IF true)
if (showRightAvatar)
  Padding(
    padding: EdgeInsets.only(
      left: isVerySmallScreen ? 8 : isSmallScreen ? 10 : 14,
    ),
    child: CircleAvatar(
      radius: isVerySmallScreen ? 12 : isSmallScreen ? 14 : 16,
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
      child: Text(
        "AV",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isVerySmallScreen ? 9 : isSmallScreen ? 11 : 13,
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
