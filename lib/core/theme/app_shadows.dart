import 'package:flutter/material.dart';

abstract class AppShadows {
  static const List<BoxShadow> none = <BoxShadow>[];
  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      blurRadius: 16,
      offset: Offset(0, 8),
      color: Color(0x14000000),
    ),
  ];
}
