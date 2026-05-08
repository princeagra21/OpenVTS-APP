import 'package:flutter/material.dart';
import 'package:open_vts/core/repositories/common_repository.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/design_system/components/open_vts_card.dart';

class LocalizationLanguageSection extends StatelessWidget {
  const LocalizationLanguageSection({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onPickLanguage,
  });

  final List<ReferenceOption> languages;
  final String selectedLanguage;
  final VoidCallback onPickLanguage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.translate_outlined,
            title: 'Default Language',
            subtitle: 'Primary language',
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: languages.isEmpty ? null : onPickLanguage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      languages.isEmpty
                          ? 'No language options'
                          : _languageLabel(selectedLanguage, languages),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: AppFonts.roboto(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _languageLabel(String code, List<ReferenceOption> options) {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '—';
    }

    for (final option in options) {
      if (option.value.toLowerCase() == normalized) {
        final label = option.label.trim();
        return label.isEmpty ? option.value : label;
      }
    }

    return code;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainerHighest
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: colorScheme.onSurface, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withValues(alpha: 0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppFonts.roboto(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
