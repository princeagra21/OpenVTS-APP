import 'package:flutter/material.dart';

class AppLogo {
  // light theme -> visible dark logo asset, dark theme -> visible light logo asset
  static const String light = 'assets/images/logo.png';
  static const String dark = 'assets/images/logo-file-dark.png';

  static String assetFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
