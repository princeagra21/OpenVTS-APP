import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

enum _OpenVtsFeedbackTone { success, error, info, warning }

class OpenVtsFeedback {
  const OpenVtsFeedback._();

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      tone: _OpenVtsFeedbackTone.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      tone: _OpenVtsFeedbackTone.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      tone: _OpenVtsFeedbackTone.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      tone: _OpenVtsFeedbackTone.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void sessionExpired(BuildContext context) {
    _show(
      context,
      message: 'Your session has expired. Please log in again.',
      tone: _OpenVtsFeedbackTone.warning,
      duration: const Duration(seconds: 5),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required _OpenVtsFeedbackTone tone,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    final text = message.trim();
    if (text.isEmpty) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final config = _configFor(tone, colorScheme);
    final hasAction = actionLabel != null && onAction != null;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: hasAction
            ? config.background
            : OpenVtsColors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(
          OpenVtsSpacing.lg,
          0,
          OpenVtsSpacing.lg,
          OpenVtsSpacing.lg,
        ),
        content: hasAction
            ? Text(
                text,
                style: OpenVtsTypography.bodyMedium.copyWith(
                  color: config.textColor,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: OpenVtsSpacing.md,
                  vertical: OpenVtsSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: config.background,
                  borderRadius: OpenVtsRadius.radiusMd,
                  border: Border.all(color: config.border),
                  boxShadow: OpenVtsShadows.subtle,
                ),
                child: Row(
                  children: [
                    Icon(
                      config.icon,
                      size: OpenVtsIconSizes.md,
                      color: config.iconColor,
                    ),
                    const SizedBox(width: OpenVtsSpacing.sm),
                    Expanded(
                      child: Text(
                        text,
                        style: OpenVtsTypography.bodyMedium.copyWith(
                          color: config.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        action: hasAction
            ? SnackBarAction(
                label: actionLabel,
                textColor: config.iconColor,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static _OpenVtsFeedbackConfig _configFor(
    _OpenVtsFeedbackTone tone,
    ColorScheme colorScheme,
  ) {
    switch (tone) {
      case _OpenVtsFeedbackTone.success:
        return _OpenVtsFeedbackConfig(
          icon: Icons.check_circle_outline,
          background: OpenVtsColors.success.withValues(alpha: 0.12),
          border: OpenVtsColors.success.withValues(alpha: 0.35),
          iconColor: OpenVtsColors.success,
          textColor: colorScheme.onSurface,
        );
      case _OpenVtsFeedbackTone.error:
        return _OpenVtsFeedbackConfig(
          icon: Icons.error_outline,
          background: OpenVtsColors.danger.withValues(alpha: 0.12),
          border: OpenVtsColors.danger.withValues(alpha: 0.35),
          iconColor: OpenVtsColors.danger,
          textColor: colorScheme.onSurface,
        );
      case _OpenVtsFeedbackTone.warning:
        return _OpenVtsFeedbackConfig(
          icon: Icons.warning_amber_rounded,
          background: OpenVtsColors.warning.withValues(alpha: 0.14),
          border: OpenVtsColors.warning.withValues(alpha: 0.35),
          iconColor: OpenVtsColors.warning,
          textColor: colorScheme.onSurface,
        );
      case _OpenVtsFeedbackTone.info:
        return _OpenVtsFeedbackConfig(
          icon: Icons.info_outline,
          background: colorScheme.primary.withValues(alpha: 0.12),
          border: colorScheme.primary.withValues(alpha: 0.3),
          iconColor: colorScheme.primary,
          textColor: colorScheme.onSurface,
        );
    }
  }
}

class _OpenVtsFeedbackConfig {
  const _OpenVtsFeedbackConfig({
    required this.icon,
    required this.background,
    required this.border,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final Color background;
  final Color border;
  final Color iconColor;
  final Color textColor;
}
