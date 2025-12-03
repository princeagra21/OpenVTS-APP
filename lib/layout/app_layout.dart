import 'package:fleet_stack/utils/app_utils.dart';
import 'package:flutter/material.dart';
import '../components/appbars/custom_appbar.dart';
import '../components/bottom_bar/custom_bottom_bar.dart';

class AppLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<IconData>? actionIcons; // make optional
  final Widget child;

  /// NEW CONTROLS
  final bool showLeftAvatar;   // FS avatar
  final bool showRightAvatar;  // AV avatar
  final String leftAvatarText;

  const AppLayout({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionIcons, // optional now
    required this.child,

    /// defaults
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: topPadding + AppUtils.appBarHeightCustom + 32),
                child,
                SizedBox(height: 68 + 16 + bottomPadding),
              ],
            ),
          ),

          /// ---- CUSTOM APP BAR WITH AVATAR CONTROLS ----
          Positioned(
            left: 0, right: 0, top: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: CustomAppBar(
                title: title,
                subtitle: subtitle,
                icons: actionIcons ?? [], // pass empty list if null

                /// NEW AVATAR SETTINGS
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
