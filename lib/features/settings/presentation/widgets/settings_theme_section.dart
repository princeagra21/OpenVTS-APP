import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/presentation/widgets/settings_section_card.dart';

class SettingsThemeSection extends StatelessWidget {
  const SettingsThemeSection({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(child: child);
  }
}
