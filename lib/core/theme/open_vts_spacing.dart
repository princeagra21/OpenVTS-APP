import 'package:flutter/widgets.dart';

class OpenVtsSpacing {
  const OpenVtsSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double sectionGap = xxl;
  static const double cardPadding = lg;
  static const double fieldGap = md;
  static const double buttonHeight = 48;

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
