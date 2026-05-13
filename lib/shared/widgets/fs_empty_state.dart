import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_empty_state.dart';

class FSEmptyState extends StatelessWidget {
  const FSEmptyState({required this.message, this.title = 'No data found', super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => OpenVtsEmptyState(title: title, message: message);
}
