import 'package:flutter/material.dart';

class CustomBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;
  final double elevation;
  final Color? color;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CustomBox({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.radius = 12.0,
    this.elevation = 1,
    this.color,
    this.border,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    // Only wrap with IntrinsicHeight if height is null (auto-sizing needed)
    if (height == null) {
      content = IntrinsicHeight(child: content);
    }

    final box = Material(
      color: color ?? colorScheme.surfaceContainerHighest.withOpacity(0.7),
      elevation: elevation,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: border,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );

    return margin != null ? Padding(padding: margin!, child: box) : box;
  }
}