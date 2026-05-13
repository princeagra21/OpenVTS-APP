import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_card.dart';

class LocalizationDateTimeSection extends StatelessWidget {
  const LocalizationDateTimeSection({
    super.key,
    required this.dateFormats,
    required this.dateFormat,
    required this.timeFormat,
    required this.timezones,
    required this.timezone,
    required this.selectedTheme,
    required this.onDateFormatChanged,
    required this.onTimeFormatChanged,
    required this.onTimezoneChanged,
    required this.onThemeChanged,
  });

  final List<String> dateFormats;
  final String dateFormat;
  final String timeFormat;
  final List<String> timezones;
  final String timezone;
  final String selectedTheme;
  final ValueChanged<String> onDateFormatChanged;
  final ValueChanged<String> onTimeFormatChanged;
  final ValueChanged<String> onTimezoneChanged;
  final ValueChanged<String> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateFormatCard(
          dateFormats: dateFormats,
          dateFormat: dateFormat,
          onChanged: onDateFormatChanged,
        ),
        const SizedBox(height: 24),
        _TimeFormatCard(timeFormat: timeFormat, onChanged: onTimeFormatChanged),
        const SizedBox(height: 24),
        _TimezoneCard(
          timezones: timezones,
          timezone: timezone,
          onChanged: onTimezoneChanged,
        ),
        const SizedBox(height: 24),
        _ThemeModeCard(selectedTheme: selectedTheme, onChanged: onThemeChanged),
      ],
    );
  }
}

class _DateFormatCard extends StatelessWidget {
  const _DateFormatCard({
    required this.dateFormats,
    required this.dateFormat,
    required this.onChanged,
  });

  final List<String> dateFormats;
  final String dateFormat;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.calendar_month_outlined,
            title: 'Date Format',
            subtitle: 'Display style',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _dropdownValueOrNull(dateFormats, dateFormat),
            hint: Text(
              dateFormats.isEmpty
                  ? 'No date format options'
                  : 'Select date format',
              style: AppFonts.roboto(),
            ),
            decoration: _dropdownDecoration(context),
            items: dateFormats
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: dateFormats.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      onChanged(value);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _TimeFormatCard extends StatelessWidget {
  const _TimeFormatCard({required this.timeFormat, required this.onChanged});

  final String timeFormat;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.schedule_outlined,
            title: 'Time Format',
            subtitle: timeFormat == '24-hour'
                ? '24-hour clock'
                : '12-hour clock',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleTile(
                    icon: Icons.schedule,
                    label: '24-hour',
                    selected: timeFormat == '24-hour',
                    onTap: () => onChanged('24-hour'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleTile(
                    icon: Icons.schedule,
                    label: '12-hour',
                    selected: timeFormat == '12-hour',
                    onTap: () => onChanged('12-hour'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimezoneCard extends StatelessWidget {
  const _TimezoneCard({
    required this.timezones,
    required this.timezone,
    required this.onChanged,
  });

  final List<String> timezones;
  final String timezone;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.public_outlined,
            title: 'Timezone',
            subtitle: 'UTC offset',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _dropdownValueOrNull(timezones, timezone),
            hint: Text(
              timezones.isEmpty ? 'No timezone options' : 'Select timezone',
              style: AppFonts.roboto(),
            ),
            decoration: _dropdownDecoration(context),
            items: timezones
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: timezones.isEmpty
                ? null
                : (value) {
                    if (value != null) {
                      onChanged(value);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({required this.selectedTheme, required this.onChanged});

  final String selectedTheme;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Light / Dark / System',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ToggleTile(
                    icon: Icons.light_mode_outlined,
                    label: 'Light',
                    selected: selectedTheme == 'light',
                    onTap: () => onChanged('light'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                    selected: selectedTheme == 'dark',
                    onTap: () => onChanged('dark'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleTile(
                    icon: Icons.settings_outlined,
                    label: 'System',
                    selected: selectedTheme == 'system',
                    onTap: () => onChanged('system'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.roboto(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dropdownDecoration(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return InputDecoration(
    filled: true,
    fillColor: Colors.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colorScheme.primary, width: 2),
    ),
  );
}

String? _dropdownValueOrNull(List<String> options, String current) {
  if (current.trim().isEmpty) {
    return null;
  }

  for (final option in options) {
    if (option.toLowerCase() == current.toLowerCase()) {
      return option;
    }
  }

  return null;
}
