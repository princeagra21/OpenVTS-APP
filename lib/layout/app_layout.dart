import 'package:fleet_stack/utils/app_utils.dart';
import 'package:flutter/material.dart';
import '../components/appbars/custom_appbar.dart';
import '../components/bottom_bar/custom_bottom_bar.dart';

class AppLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<IconData>? actionIcons; // optional
  final Widget child;

  /// NEW CONTROLS
  final bool showLeftAvatar;   // FS avatar
  final bool showRightAvatar;  // AV avatar
  final String leftAvatarText;

  /// NEW OPTIONS
  final double horizontalPadding; // default 20
  final bool showAppBar;          // default true

  const AppLayout({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionIcons,
    required this.child,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.horizontalPadding = 20.0, // default horizontal padding
    this.showAppBar = true,        // default show app bar
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: topPadding + (showAppBar ? AppUtils.appBarHeightCustom + 32 : 16)),
                child,
                SizedBox(height: 68 + 16 + bottomPadding),
              ],
            ),
          ),

          /// ---- CUSTOM APP BAR WITH AVATAR CONTROLS ----
          if (showAppBar)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: CustomAppBar(
                  title: title,
                  subtitle: subtitle,
                  icons: actionIcons ?? [],
                  showLeftAvatar: showLeftAvatar,
                  showRightAvatar: showRightAvatar,
                  leftAvatarText: leftAvatarText,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(),
    );
  }
}
