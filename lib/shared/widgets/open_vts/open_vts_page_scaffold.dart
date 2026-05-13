import 'package:flutter/material.dart';

import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'open_vts_section_header.dart';

class OpenVtsPageScaffold extends StatelessWidget {
  const OpenVtsPageScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.actions,
    this.appBar,
    this.backgroundColor,
    this.padding = OpenVtsSpacing.pagePadding,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final resolvedAppBar =
        appBar ??
        (title == null
            ? null
            : AppBar(
                elevation: 0,
                backgroundColor: cs.surface,
                title: OpenVtsSectionHeader(
                  title: title!,
                  subtitle: subtitle,
                  trailing: actions == null || actions!.isEmpty
                      ? null
                      : Row(mainAxisSize: MainAxisSize.min, children: actions!),
                ),
              ));

    return Scaffold(
      backgroundColor: backgroundColor ?? OpenVtsColors.background,
      appBar: resolvedAppBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(padding: padding, child: body),
      ),
    );
  }
}
