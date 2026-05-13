import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_loading_view.dart';

class FSLoading extends StatelessWidget {
  const FSLoading({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) => OpenVtsLoadingView(message: message);
}
