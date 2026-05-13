import 'package:flutter/animation.dart';

class OpenVtsMotion {
  const OpenVtsMotion._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve emphasize = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
}
