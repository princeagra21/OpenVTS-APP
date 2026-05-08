import 'package:flutter/material.dart';

import 'open_vts_colors.dart';

class OpenVtsShadows {
  const OpenVtsShadows._();

  static const List<BoxShadow> none = <BoxShadow>[];

  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: OpenVtsColors.overlaySoft,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> medium = <BoxShadow>[
    BoxShadow(
      color: OpenVtsColors.overlaySoft,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> strong = <BoxShadow>[
    BoxShadow(
      color: OpenVtsColors.overlayStrong,
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}
