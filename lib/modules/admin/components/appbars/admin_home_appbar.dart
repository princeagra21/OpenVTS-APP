import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHomeAppBar extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onClose;
  final double borderRadius;

  const AdminHomeAppBar({
    super.key,
    required this.title,
    required this.leadingIcon,
    this.onClose,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double iconContainerSize = 32 * scale;
    final double iconSize = 15 * scale;
    final textStyle = AppUtils.headlineSmallBase.copyWith(
      fontSize: 16 * scale,
      height: 20 / 16,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: AppUtils.appBarHeightCustom + 5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: cs.surface,
            border: Border.all(
              color: cs.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: iconContainerSize,
                width: iconContainerSize,
                decoration: BoxDecoration(
                  color: cs.onSurface,
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                alignment: Alignment.center,
                child: Icon(
                  leadingIcon,
                  color: cs.surface,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              IconButton(
                onPressed: onClose ??
                    () {
                      final router = GoRouter.of(context);
                      if (router.canPop()) {
                        context.pop();
                      } else {
                        context.go('/admin/home');
                      }
                    },
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
  }
}
