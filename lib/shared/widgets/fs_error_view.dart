import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_error_state.dart';
import 'package:open_vts/core/error/error_handler.dart';

class FSErrorView extends StatelessWidget {
  const FSErrorView({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsErrorState(message: ErrorHandler.message(error), onRetry: onRetry);
  }
}
