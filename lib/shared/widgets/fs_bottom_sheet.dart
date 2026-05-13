import 'package:flutter/material.dart';
Future<T?> showFSBottomSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(context: context, isScrollControlled: true, builder: (_) => child);
