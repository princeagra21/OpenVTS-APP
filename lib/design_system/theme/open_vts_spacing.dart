import 'package:flutter/widgets.dart';
import 'package:open_vts/core/theme/open_vts_spacing.dart' as core;

class OpenVtsSpacing {
  const OpenVtsSpacing._();

  static const double xxs = core.OpenVtsSpacing.xxs;
  static const double xs = core.OpenVtsSpacing.xs;
  static const double sm = core.OpenVtsSpacing.sm;
  static const double md = core.OpenVtsSpacing.md;
  static const double lg = core.OpenVtsSpacing.lg;
  static const double xl = core.OpenVtsSpacing.xl;
  static const double xxl = core.OpenVtsSpacing.xxl;
  static const double xxxl = core.OpenVtsSpacing.xxxl;

  static const double sectionGap = core.OpenVtsSpacing.sectionGap;
  static const double cardPadding = core.OpenVtsSpacing.cardPadding;
  static const double fieldGap = core.OpenVtsSpacing.fieldGap;
  static const double buttonHeight = core.OpenVtsSpacing.buttonHeight;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );

  static const EdgeInsets contentPadding = EdgeInsets.all(cardPadding);

  static const EdgeInsets fieldContentPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}
