import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../components/appbars/custom_appbar.dart';
import 'dart:ui';

class AppLayout extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<IconData>? actionIcons;
  final List<VoidCallback>? onActionTaps; // NEW: Tap handlers for action icons
  final ValueChanged<String>? onSearchSubmitted;
  final ValueChanged<String>? onSearchChanged;
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

  const AppLayout({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionIcons,
    this.onActionTaps, // NEW
    this.onSearchSubmitted,
    this.onSearchChanged,
    required this.child,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.horizontalPadding = 20.0,
    this.showAppBar = true,
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
    final cs = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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

          if (widget.onActionTaps != null &&
              i < widget.onActionTaps!.length) {
            final original = widget.onActionTaps![i];
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
          if (widget.onActionTaps == null || i >= widget.onActionTaps!.length) {
            effectiveTaps[i] = () => context.push('/superadmin/notifications');
          }
        }
      }
    }

    final bool hasCustomTopBar = widget.customTopBar != null;
    final double topBarHeight =
        widget.customTopBarHeight ?? (AppUtils.appBarHeightCustom + 5);

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
                            : (hasCustomTopBar ? (topBarHeight + 24) : 16)),
                  ),
                  widget.child,
                  SizedBox(height: 68 + 16 + bottomPadding),
                ],
              ),
            ),
          ),

          /// CUSTOM APP BAR with animated opacity and ignore pointer when searching
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
                  child: CustomAppBar(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    icons: widget.actionIcons ?? [],
                    onIconTaps:
                        effectiveTaps, // Use effective taps with search handling
                    notificationPathPrefix: '/superadmin/notifications',
                    showLeftAvatar: widget.showLeftAvatar,
                    showRightAvatar: widget.showRightAvatar,
                    leftAvatarText: widget.leftAvatarText,
                    scrollOffset: _scrollOffset, // Pass the dynamic offset
                  ),
                ),
              ),
            ),

          if (hasCustomTopBar)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Padding(
                padding: widget.customTopBarPadding,
                child: widget.customTopBar!,
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
                      border: Border.all(
                        color: cs.primary.withOpacity(0.3),
                      ), // Replaced 'brand' with cs.primary
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
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              fillColor: cs.surface.withOpacity(0.75),
                              hintStyle: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                              isDense: true, // optional – reduces padding
                              contentPadding:
                                  EdgeInsets.zero, // optional – tight layout
                            ),
                            style: TextStyle(color: cs.onSurface),
                            onSubmitted: (q) {
                              debugPrint("Searching: $q");
                              widget.onSearchSubmitted?.call(q);
                              _closeSearch();
                            },
                            onChanged: (q) => widget.onSearchChanged?.call(q),
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

      /// FIXED BOTTOM BAR (intentionally disabled)
      // bottomNavigationBar: const CustomBottomBar(),
    );
  }
}
