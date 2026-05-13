import 'package:flutter/material.dart';

import 'open_vts_colors.dart';
import 'open_vts_radius.dart';

class OpenVtsBorders {
  const OpenVtsBorders._();

  static const BorderSide subtle = BorderSide(
    color: OpenVtsColors.border,
    width: 1,
  );

  static const BorderSide divider = BorderSide(
    color: OpenVtsColors.divider,
    width: 1,
  );

  static const BorderSide focus = BorderSide(
    color: OpenVtsColors.brandInk,
    width: 1.5,
  );

  static const BorderSide danger = BorderSide(
    color: OpenVtsColors.danger,
    width: 1.2,
  );

  static Border borderAll({Color? color, double width = 1}) {
    return Border.all(color: color ?? OpenVtsColors.border, width: width);
  }

  static OutlineInputBorder input({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: OpenVtsRadius.radiusMd,
      borderSide: BorderSide(
        color: color ?? OpenVtsColors.border,
        width: width,
      ),
    );
  }
}
