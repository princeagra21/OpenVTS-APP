import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';
import 'open_vts_button.dart';
import 'open_vts_bottom_sheet.dart';
import 'open_vts_dialog.dart';

class OpenVtsModalAction<T> {
  const OpenVtsModalAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool isDestructive;
}

class OpenVtsModal {
  const OpenVtsModal._();

  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return OpenVtsDialog(
          title: title,
          message: message,
          icon: icon,
          actions: [
            OpenVtsDialogAction(
              label: cancelLabel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              variant: OpenVtsButtonVariant.secondary,
            ),
            OpenVtsDialogAction(
              label: confirmLabel,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              variant: isDestructive
                  ? OpenVtsButtonVariant.danger
                  : OpenVtsButtonVariant.primary,
            ),
          ],
        );
      },
    );

    return result == true;
  }

  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    required List<OpenVtsModalAction<T>> actions,
    String? title,
    String cancelLabel = 'Cancel',
  }) {
    return showBottomSheet<T>(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions.map((action) {
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: OpenVtsSpacing.sm,
              ),
              leading: action.icon == null
                  ? null
                  : Icon(
                      action.icon,
                      color: action.isDestructive ? OpenVtsColors.danger : null,
                    ),
              title: Text(
                action.label,
                style: OpenVtsTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: action.isDestructive ? OpenVtsColors.danger : null,
                ),
              ),
              onTap: () => Navigator.of(context).pop(action.value),
            );
          }),
          const SizedBox(height: OpenVtsSpacing.sm),
          OpenVtsButton(
            label: cancelLabel,
            variant: OpenVtsButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      enableDrag: enableDrag,
      backgroundColor: OpenVtsColors.transparent,
      builder: (_) => OpenVtsBottomSheet(title: title, child: child),
    );
  }

  static Future<T?> showFormSheet<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showBottomSheet<T>(
      context: context,
      title: title,
      isScrollControlled: isScrollControlled,
      child: Builder(
        builder: (sheetContext) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(child: child),
          );
        },
      ),
    );
  }
}
