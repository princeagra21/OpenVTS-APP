import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/features/shell/open_vts_app_bar.dart';
import 'package:open_vts/features/shell/open_vts_bottom_nav.dart';
import 'package:open_vts/features/shell/role_nav_config.dart';

class OpenVtsAppShell extends StatefulWidget {
  const OpenVtsAppShell({
    super.key,
    required this.role,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.leftAvatarText,
    this.actionIcons,
    this.onActionTaps,
    this.onSearchSubmitted,
    this.onSearchChanged,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    this.horizontalPadding = 20,
    this.showAppBar = true,
    this.showBottomBar = true,
    this.disableAppBarLeading = true,
    this.customTopBar,
    this.customTopBarPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.customTopBarHeight,
  });

  final OpenVtsRole role;

  final String title;
  final String subtitle;
  final List<IconData>? actionIcons;
  final List<VoidCallback>? onActionTaps;
  final ValueChanged<String>? onSearchSubmitted;
  final ValueChanged<String>? onSearchChanged;
  final Widget child;

  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;

  final double horizontalPadding;
  final bool showAppBar;
  final bool showBottomBar;
  final bool disableAppBarLeading;

  final Widget? customTopBar;
  final EdgeInsets customTopBarPadding;
  final double? customTopBarHeight;

  @override
  State<OpenVtsAppShell> createState() => _OpenVtsAppShellState();
}

class _OpenVtsAppShellState extends State<OpenVtsAppShell> {
  double _scrollOffset = 0;
  bool _isSearching = false;
  late final TextEditingController _searchController;

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

  void _closeSearch() {
    setState(() {
      _isSearching = false;
    });
  }

  List<VoidCallback>? _effectiveActionTaps(
    BuildContext context,
    OpenVtsRoleNavConfig config,
  ) {
    List<VoidCallback>? taps = widget.onActionTaps != null
        ? List<VoidCallback>.from(widget.onActionTaps!)
        : null;

    final icons = widget.actionIcons;
    if (icons == null || icons.isEmpty) {
      return taps;
    }

    for (int i = 0; i < icons.length; i++) {
      final icon = icons[i];
      if (icon == CupertinoIcons.search) {
        void searchTap() {
          setState(() {
            _isSearching = true;
          });
        }

        taps ??= List<VoidCallback>.generate(icons.length, (_) => () {});

        if (widget.onActionTaps != null && i < widget.onActionTaps!.length) {
          final original = widget.onActionTaps![i];
          taps[i] = () {
            searchTap();
            original();
          };
        } else {
          taps[i] = searchTap;
        }
      } else if (icon == CupertinoIcons.bell) {
        taps ??= List<VoidCallback>.generate(icons.length, (_) => () {});
        if (widget.onActionTaps == null || i >= widget.onActionTaps!.length) {
          taps[i] = () => context.push(config.notificationsRoute);
        }
      }
    }

    return taps;
  }

  @override
  Widget build(BuildContext context) {
    final config = OpenVtsRoleNavConfigs.of(widget.role);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final hasCustomTopBar = widget.customTopBar != null;
    final topBarHeight =
        widget.customTopBarHeight ?? (AppUtils.appBarHeightCustom + 5);

    final actionTaps = _effectiveActionTaps(context, config);
    final appBarVariant = config.useHomeStyleAppBar
        ? OpenVtsAppBarVariant.home
        : OpenVtsAppBarVariant.standard;

    final appBarPrimaryTitle = appBarVariant == OpenVtsAppBarVariant.home
        ? (widget.subtitle.trim().isNotEmpty ? widget.subtitle : widget.title)
        : widget.title;

    final appBarLeadingIcon = appBarVariant == OpenVtsAppBarVariant.home
        ? _iconForTitle(appBarPrimaryTitle)
        : null;

    return Scaffold(
      backgroundColor: isDark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: <Widget>[
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
                children: <Widget>[
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
          if (widget.showAppBar)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                ignoring: _isSearching,
                child: AnimatedOpacity(
                  opacity: _isSearching ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: OpenVtsAppBar(
                    variant: appBarVariant,
                    title: appBarPrimaryTitle,
                    subtitle: widget.subtitle,
                    icons: appBarVariant == OpenVtsAppBarVariant.home
                        ? const <IconData>[]
                        : (widget.actionIcons ?? const <IconData>[]),
                    onIconTaps: appBarVariant == OpenVtsAppBarVariant.home
                        ? null
                        : actionTaps,
                    notificationPathPrefix: config.notificationsRoute,
                    showLeftAvatar: widget.showLeftAvatar,
                    showRightAvatar: widget.showRightAvatar,
                    leftAvatarText: widget.leftAvatarText,
                    scrollOffset: _scrollOffset,
                    showLeading: !widget.disableAppBarLeading,
                    leadingIcon: appBarLeadingIcon,
                    onClose: appBarVariant == OpenVtsAppBarVariant.home
                        ? () => context.go(config.homeRoute)
                        : null,
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
          if (!widget.showAppBar && widget.role == OpenVtsRole.user)
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
                    ),
                    child: Row(
                      children: <Widget>[
                        if (ModalRoute.of(context)?.canPop == true ||
                            Navigator.of(context).canPop())
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Container(
                              height: AdaptiveUtils.getAvatarSize(
                                MediaQuery.of(context).size.width,
                              ),
                              width: AdaptiveUtils.getAvatarSize(
                                MediaQuery.of(context).size.width,
                              ),
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
                                size: AdaptiveUtils.getIconSize(
                                  MediaQuery.of(context).size.width,
                                ),
                                color: cs.primary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (widget.actionIcons != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: widget.actionIcons!.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final icon = entry.value;
                              final tapHandler =
                                  (actionTaps != null &&
                                      index < actionTaps.length)
                                  ? actionTaps[index]
                                  : null;

                              final size = AdaptiveUtils.getAvatarSize(
                                MediaQuery.of(context).size.width,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: GestureDetector(
                                  onTap: tapHandler,
                                  child: Container(
                                    height: size,
                                    width: size,
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
                                      size: AdaptiveUtils.getIconSize(
                                        MediaQuery.of(context).size.width,
                                      ),
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
                      color: cs.surface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.search,
                          color: cs.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: 'Search location',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              fillColor: cs.surface.withValues(alpha: 0.75),
                              hintStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(color: cs.onSurface),
                            onSubmitted: (query) {
                              AppLogger.debug('Searching: $query');
                              widget.onSearchSubmitted?.call(query);
                              _closeSearch();
                            },
                            onChanged: (query) {
                              widget.onSearchChanged?.call(query);
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: _closeSearch,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: cs.primary.withValues(alpha: 0.7),
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
      bottomNavigationBar: widget.showBottomBar
          ? OpenVtsBottomNav(role: widget.role, forceVisible: true)
          : null,
    );
  }
}
