import 'package:flutter/material.dart';

class AppLogo {
  static const String light = 'assets/images/logos/open_vts_logo_light.jpg';
  static const String dark = 'assets/images/logos/open_vts_logo_dark.png';

  static String assetFor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
