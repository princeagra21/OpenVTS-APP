import 'package:flutter/material.dart';
import 'package:open_vts/shared/widgets/fs_error_view.dart';

class FailureWidget extends StatelessWidget {
  const FailureWidget({
    super.key,
    this.error,
    this.message,
    this.onRetry,
  });

  final Object? error;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FSErrorView(
      error: error ?? message ?? 'Something went wrong.',
      onRetry: onRetry,
    );
  }
}
