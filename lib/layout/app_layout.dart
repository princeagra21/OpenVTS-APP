import 'package:fleet_stack/utils/app_utils.dart';
import 'package:flutter/material.dart';
import '../components/appbars/custom_appbar.dart';
import '../components/bottom_bar/custom_bottom_bar.dart';

class AppLayout extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<IconData>? actionIcons;
  final List<VoidCallback>? onActionTaps; // NEW: Tap handlers for action icons
  final Widget child;

  /// NEW CONTROLS
  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;

  /// NEW OPTIONS
  final double horizontalPadding;
  final bool showAppBar;

  const AppLayout({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionIcons,
    this.onActionTaps, // NEW
    required this.child,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.horizontalPadding = 20.0,
    this.showAppBar = true,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          /// MAIN SCROLL VIEW WITH NOTIFICATION LISTENER
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.axis == Axis.vertical) {
                setState(() {
                  _scrollOffset = scrollInfo.metrics.pixels;
                });
              }
              return true;
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height: topPadding +
                        (widget.showAppBar
                            ? AppUtils.appBarHeightCustom + 32
                            : 16),
                  ),
                  widget.child,
                  SizedBox(height: 68 + 16 + bottomPadding),
                ],
              ),
            ),
          ),

          /// CUSTOM APP BAR
          if (widget.showAppBar)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: CustomAppBar(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  icons: widget.actionIcons ?? [],
                  onIconTaps: widget.onActionTaps, // NEW: Pass tap handlers
                  showLeftAvatar: widget.showLeftAvatar,
                  showRightAvatar: widget.showRightAvatar,
                  leftAvatarText: widget.leftAvatarText,
                  scrollOffset: _scrollOffset, // Pass the dynamic offset
                ),
              ),
            ),
        ],
      ),

      /// FIXED BOTTOM BAR
      bottomNavigationBar: const CustomBottomBar(),
    );
  }
}