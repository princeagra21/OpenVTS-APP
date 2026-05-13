import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/utils/app_utils.dart';

class OpenVtsPageTitleBar extends StatelessWidget {
  const OpenVtsPageTitleBar({
    super.key,
    required this.title,
    required this.leadingIcon,
    this.onClose,
    this.fallbackRoute,
    this.borderRadius = 16,
    this.contentPadding = const EdgeInsetsDirectional.symmetric(
        horizontal: AppUtils.spacingMedium),
    this.popIfPossible = true,
    this.applySafeAreaTop = true,
  });

  static const double _baseIconContainerSize = 32;
  static const double _baseIconSize = 15;
  static const double _baseIconRadius = 12;
  static const double _baseHeightOffset = 5;

  final String title;
  final IconData leadingIcon;
  final VoidCallback? onClose;
  final String? fallbackRoute;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final bool popIfPossible;
  final bool applySafeAreaTop;

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }

    final router = GoRouter.of(context);
    if (popIfPossible && router.canPop()) {
      context.pop();
      return;
    }

    final route = fallbackRoute?.trim();
    if (route != null && route.isNotEmpty) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double iconContainerSize = _baseIconContainerSize * scale;
    final double iconSize = _baseIconSize * scale;

    final textStyle = AppUtils.headlineSmallBase.copyWith(
      fontSize: 16 * scale,
      height: 20 / 16,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );

    final bar = SizedBox(
      width: double.infinity,
      height: AppUtils.appBarHeightCustom + _baseHeightOffset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: cs.surface,
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: contentPadding,
          child: Row(
            children: [
              Container(
                height: iconContainerSize,
                width: iconContainerSize,
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  borderRadius: BorderRadius.circular(_baseIconRadius * scale),
                ),
                alignment: Alignment.center,
                child: Icon(
                  leadingIcon,
                  color: cs.surface,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: AppUtils.spacingAppMedium),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              IconButton(
                onPressed: () => _handleClose(context),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: iconContainerSize,
                  minHeight: iconContainerSize,
                ),
                icon: Container(
                  height: iconContainerSize,
                  width: iconContainerSize,
                  decoration: BoxDecoration(
                    color: cs.onSurface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    color: cs.surface,
                    size: iconSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!applySafeAreaTop) {
      return bar;
    }

    return SafeArea(bottom: false, child: bar);
  }
}
