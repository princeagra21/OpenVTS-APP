import 'dart:ui';

import 'package:flutter/material.dart';

Widget glassMapControlButton({
  required BuildContext context,
  required Widget child,
  required VoidCallback onPressed,
  double width = 44,
  double height = 44,
  double borderRadiusValue = 9,
  Color? backgroundColor,
  Color? borderColorOverride,
  bool showShadow = true,
  bool showBorder = true,
  double blurSigma = 2.5,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final radius = BorderRadius.circular(borderRadiusValue);

  final fillColor = backgroundColor ??
      (isDark
          ? Colors.black.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.025));

  final borderColor = borderColorOverride ??
      (isDark
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.65));

  final shadowColor = Colors.black.withValues(alpha: 0.10);
  final foregroundColor = isDark ? Colors.white : Colors.black;

  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: radius,
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : const [],
    ),
    child: ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: Colors.black.withValues(alpha: 0.04),
            highlightColor: Colors.black.withValues(alpha: 0.03),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: radius,
                border: showBorder
                    ? Border.all(
                        color: borderColor,
                        width: 1,
                      )
                    : null,
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: foregroundColor,
                    size: 22,
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
