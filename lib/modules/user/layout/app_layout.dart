import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/bottom_bar/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

import 'package:go_router/go_router.dart';

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
  final Widget? customTopBar;
  final EdgeInsets customTopBarPadding;
  final double? customTopBarHeight;

  /// If true, instructs the CustomAppBar to not automatically show its leading/back button.
  /// Requires CustomAppBar to accept a `showLeading` boolean (defaulting to true in CustomAppBar).
  final bool disableAppBarLeading;

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
    this.disableAppBarLeading = true,
    this.customTopBar,
    this.customTopBarPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.customTopBarHeight,
  });

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  double _scrollOffset = 0.0;
  bool _isSearching = false;
  late TextEditingController _searchController;

  IconData _iconForTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.contains('map')) return Icons.map_outlined;
    if (t.contains('vehicle')) return Icons.directions_car_outlined;
    if (t.contains('driver')) return Icons.badge_outlined;
    if (t.contains('support') || t.contains('ticket')) {
      return Icons.support_agent_outlined;
    }
    if (t.contains('transaction')) return Icons.receipt_long_outlined;
    if (t.contains('payment')) return Icons.credit_card_outlined;
    if (t.contains('notification')) return Icons.notifications_outlined;
    if (t.contains('setting')) return Icons.settings_outlined;
    if (t.contains('profile')) return Icons.person_outline;
    if (t.contains('report')) return Icons.assessment_outlined;
    if (t.contains('route')) return Icons.route_outlined;
    if (t.contains('landmark') || t.contains('geofence')) {
      return Icons.location_on_outlined;
    }
    if (t.contains('admin')) return Icons.admin_panel_settings_outlined;
    if (t.contains('sub user') || t.contains('user')) {
      return Icons.group_outlined;
    }
    if (t.contains('log')) return Icons.list_alt_outlined;
    return Icons.apps_outlined;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
    });
    // Optionally clear the search text: _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double iconSize = AdaptiveUtils.getIconSize(screenWidth);
    final double avatarSize = AdaptiveUtils.getAvatarSize(screenWidth);

    // Prepare effective tap handlers, overriding or adding for search icon
    List<VoidCallback>? effectiveTaps = widget.onActionTaps != null
        ? List.from(widget.onActionTaps!)
        : null;

    if (widget.actionIcons != null) {
      for (int i = 0; i < widget.actionIcons!.length; i++) {
        if (widget.actionIcons![i] == CupertinoIcons.search) {
          VoidCallback searchTap = () {
            setState(() {
              _isSearching = true;
            });
          };

          if (effectiveTaps == null) {
            effectiveTaps = List.generate(
              widget.actionIcons!.length,
              (_) => () {},
            );
          }

          if (widget.onActionTaps != null && i < widget.onActionTaps!.length) {
            VoidCallback original = widget.onActionTaps![i];
            effectiveTaps[i] = () {
              searchTap();
              original();
            }; // Chain original if provided
          } else {
            effectiveTaps[i] = searchTap;
          }
        } else if (widget.actionIcons![i] == CupertinoIcons.bell) {
          effectiveTaps ??= List.generate(
            widget.actionIcons!.length,
            (_) => () {},
          );
          if (!(widget.onActionTaps != null &&
              i < widget.onActionTaps!.length)) {
            effectiveTaps[i] = () => context.push('/user/notifications');
          }
        }
      }
    }

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
              padding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(
                    height:
                        topPadding +
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

          /// HOME-STYLE APP BAR (matches Admin/Superadmin screen appbar)
          if (widget.showAppBar)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                ignoring: _isSearching,
                child: AnimatedOpacity(
                  opacity: _isSearching ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: UserHomeAppBar(
                    title: widget.subtitle.trim().isNotEmpty
                        ? widget.subtitle
                        : widget.title,
                    leadingIcon: _iconForTitle(
                      widget.subtitle.trim().isNotEmpty
                          ? widget.subtitle
                          : widget.title,
                    ),
                    onClose: () => context.go('/user/home'),
                  ),
                ),
              ),
            ),

          if (widget.customTopBar != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Padding(
                padding: widget.customTopBarPadding,
                child: widget.customTopBar!,
              ),
            ),

          /// NEW: Top overlay controls (when showAppBar == false)
          if (!widget.showAppBar)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                ignoring: _isSearching,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.horizontalPadding,
                      vertical: 0,
                    ),
                    child: Row(
                      children: [
                        // Back button (left) - only show when route can be popped
                        if (ModalRoute.of(context)?.canPop == true ||
                            Navigator.of(context).canPop())
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

                        const Spacer(),

                        // Action icons (right) — use the same effectiveTaps logic
                        if (widget.actionIcons != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.actionIcons!.asMap().entries.map((
                              entry,
                            ) {
                              final int index = entry.key;
                              final IconData icon = entry.value;
                              final VoidCallback? tapHandler =
                                  (effectiveTaps != null &&
                                      index < effectiveTaps.length)
                                  ? effectiveTaps[index]
                                  : (widget.onActionTaps != null &&
                                            index < widget.onActionTaps!.length
                                        ? widget.onActionTaps![index]
                                        : null);

                              return Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: GestureDetector(
                                  onTap: tapHandler,
                                  child: Container(
                                    height: avatarSize,
                                    width: avatarSize,
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
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ---------------- SEARCH BAR ----------------
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            top: _isSearching ? topPadding + 10 : -120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 55,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cs.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: "Search location",
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                            style: TextStyle(color: cs.onSurface),
                            onSubmitted: (q) {
                              debugPrint("Searching: $q");
                              _closeSearch();
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeSearch,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      /// FIXED BOTTOM BAR (removed for user module)
      bottomNavigationBar: null,
    );
  }
}
