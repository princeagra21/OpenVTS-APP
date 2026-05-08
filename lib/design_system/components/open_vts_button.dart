import 'package:flutter/material.dart';

import '../theme/open_vts_theme.dart';

enum OpenVtsButtonVariant { primary, secondary, ghost, danger }

enum OpenVtsButtonSize { small, medium, large }

class OpenVtsButton extends StatelessWidget {
  const OpenVtsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = OpenVtsButtonVariant.primary,
    this.size = OpenVtsButtonSize.medium,
    this.leading,
    this.trailing,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final OpenVtsButtonVariant variant;
  final OpenVtsButtonSize size;
  final IconData? leading;
  final IconData? trailing;
  final bool expand;

  double get _height {
    switch (size) {
      case OpenVtsButtonSize.small:
        return 40;
      case OpenVtsButtonSize.medium:
        return 48;
      case OpenVtsButtonSize.large:
        return 56;
    }
  }

  TextStyle _textStyle(BuildContext context) {
    final base =
        Theme.of(context).textTheme.labelLarge ?? OpenVtsTypography.labelLarge;
    return base.copyWith(fontWeight: FontWeight.w600);
  }

  Color _foregroundColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (variant) {
      case OpenVtsButtonVariant.primary:
        return cs.onPrimary;
      case OpenVtsButtonVariant.secondary:
        return cs.onSurface;
      case OpenVtsButtonVariant.ghost:
        return cs.primary;
      case OpenVtsButtonVariant.danger:
        return OpenVtsColors.white;
    }
  }

  ButtonStyle _style(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (variant) {
      case OpenVtsButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: Size(0, _height),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: OpenVtsRadius.radiusMd,
          ),
          textStyle: _textStyle(context),
        );
      case OpenVtsButtonVariant.secondary:
        return OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: OpenVtsBorders.subtle,
          minimumSize: Size(0, _height),
          shape: const RoundedRectangleBorder(
            borderRadius: OpenVtsRadius.radiusMd,
          ),
          textStyle: _textStyle(context),
        );
      case OpenVtsButtonVariant.ghost:
        return TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: Size(0, _height),
          shape: const RoundedRectangleBorder(
            borderRadius: OpenVtsRadius.radiusMd,
          ),
          textStyle: _textStyle(context),
        );
      case OpenVtsButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: OpenVtsColors.danger,
          foregroundColor: OpenVtsColors.white,
          minimumSize: Size(0, _height),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: OpenVtsRadius.radiusMd,
          ),
          textStyle: _textStyle(context),
        );
    }
  }

  Widget _child(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor(context)),
        ),
      );
    }

    final rowChildren = <Widget>[];
    if (leading != null) {
      rowChildren.add(Icon(leading, size: OpenVtsIconSizes.md));
      rowChildren.add(const SizedBox(width: OpenVtsSpacing.sm));
    }

    rowChildren.add(
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
    );

    if (trailing != null) {
      rowChildren.add(const SizedBox(width: OpenVtsSpacing.sm));
      rowChildren.add(Icon(trailing, size: OpenVtsIconSizes.md));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: rowChildren,
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      OpenVtsButtonVariant.primary ||
      OpenVtsButtonVariant.danger => ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: _style(context),
        child: _child(context),
      ),
      OpenVtsButtonVariant.secondary => OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: _style(context),
        child: _child(context),
      ),
      OpenVtsButtonVariant.ghost => TextButton(
        onPressed: loading ? null : onPressed,
        style: _style(context),
        child: _child(context),
      ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
