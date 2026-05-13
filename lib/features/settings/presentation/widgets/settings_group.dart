import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';
import 'package:open_vts/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:open_vts/features/settings/presentation/widgets/settings_section_icon.dart';
import 'package:open_vts/features/settings/presentation/widgets/settings_tile.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final String title;
  final String subtitle;
  final List<SettingsSectionModel> sections;
  final SettingsSectionId selectedSection;
  final ValueChanged<SettingsSectionId> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double scale = (screenWidth / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSubtitle = 12 * scale;
    final double fsTab = 13 * scale;
    final double fsTabIcon = 14 * scale;

    return SettingsSectionCard(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.roboto(
              fontSize: fsSubtitle,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: sections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SettingsTile(
                      label: section.label,
                      selected: selectedSection == section.id,
                      icon: SettingsSectionIcon.resolve(section.iconKey),
                      fontSize: fsTab,
                      iconSize: fsTabIcon,
                      onTap: () => onSectionSelected(section.id),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
