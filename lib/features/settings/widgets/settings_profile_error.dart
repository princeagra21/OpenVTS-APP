import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_error_state.dart';

class SettingsProfileError extends StatelessWidget {
  const SettingsProfileError({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return OpenVtsErrorState(
      title: 'Profile unavailable',
      message: message,
      retryLabel: 'Reload profile',
      onRetry: onRetry,
    );
  }
}
