import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';

class VehicleDetailsConfigTab extends StatelessWidget {
  const VehicleDetailsConfigTab({
    super.key,
    required this.loadingConfig,
    required this.savingConfig,
    required this.speedController,
    required this.distanceController,
    required this.odometerController,
    required this.engineHoursController,
    required this.ignitionSource,
    required this.onReset,
    required this.onSave,
    required this.onIgnitionSourceChanged,
  });

  final bool loadingConfig;
  final bool savingConfig;
  final TextEditingController speedController;
  final TextEditingController distanceController;
  final TextEditingController odometerController;
  final TextEditingController engineHoursController;
  final String ignitionSource;
  final VoidCallback onReset;
  final Future<void> Function() onSave;
  final ValueChanged<String> onIgnitionSourceChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsSection = 18 * scale;
    final fsAction = 14 * scale;
    final fsActionIcon = 16 * scale;

    if (loadingConfig) {
      return const AppShimmer(width: double.infinity, height: 320, radius: 12);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle Config',
                style: AppFonts.roboto(
                  fontSize: fsSection,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: (savingConfig || loadingConfig) ? null : onReset,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh_outlined,
                      color: colorScheme.onSurface,
                      size: fsActionIcon,
                    ),
                    label: Text(
                      'Reset',
                      style: AppFonts.roboto(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: fsAction,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (savingConfig || loadingConfig)
                        ? null
                        : () => onSave(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: SizedBox(
                      width: fsActionIcon,
                      height: fsActionIcon,
                      child: savingConfig
                          ? AppShimmer(
                              width: fsActionIcon,
                              height: fsActionIcon,
                              radius: fsActionIcon / 2,
                            )
                          : Icon(
                              Icons.save_outlined,
                              color: colorScheme.onPrimary,
                              size: fsActionIcon,
                            ),
                    ),
                    label: Text(
                      'Save',
                      style: AppFonts.roboto(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: fsAction,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ConfigSection(
            icon: Icons.speed,
            title: 'Speed Multiplier',
            subtitle: 'Speed ×',
            scale: scale,
            child: _NumberField(controller: speedController, unit: '×'),
          ),
          const SizedBox(height: 24),
          _ConfigSection(
            icon: Icons.route_outlined,
            title: 'Distance Multiplier',
            subtitle: 'Distance ×',
            scale: scale,
            child: _NumberField(controller: distanceController, unit: '×'),
          ),
          const SizedBox(height: 24),
          _ConfigSection(
            icon: Icons.av_timer_outlined,
            title: 'Set Odometer',
            subtitle: 'Odometer',
            scale: scale,
            child: _NumberField(controller: odometerController, unit: 'km'),
          ),
          const SizedBox(height: 24),
          _ConfigSection(
            icon: Icons.timer_outlined,
            title: 'Set Engine Hours',
            subtitle: 'Engine Hours',
            scale: scale,
            child: _NumberField(controller: engineHoursController, unit: 'h'),
          ),
          const SizedBox(height: 24),
          _ConfigSection(
            icon: Icons.power_settings_new_outlined,
            title: 'Ignition Source',
            subtitle: 'Ignition Wire / Motion-Based',
            scale: scale,
            child: _IgnitionSourceBox(
              ignitionSource: ignitionSource,
              savingConfig: savingConfig,
              onChanged: onIgnitionSourceChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({
    required this.icon,
    required this.title,
    this.subtitle,
    this.child,
    required this.scale,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleFontSize = 18 * scale;
    final subtitleFontSize = 12 * scale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withValues(alpha: 0.87),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppFonts.roboto(
                          fontSize: subtitleFontSize,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.unit,
  });

  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final fontSize = 12 * scale;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppFonts.roboto(fontSize: fontSize, color: colorScheme.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: AdaptiveUtils.isVerySmallScreen(width) ? 10 : 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        suffixText: unit,
        suffixStyle: AppFonts.roboto(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.87),
        ),
      ),
    );
  }
}

class _IgnitionSourceBox extends StatelessWidget {
  const _IgnitionSourceBox({
    required this.ignitionSource,
    required this.savingConfig,
    required this.onChanged,
  });

  final String ignitionSource;
  final bool savingConfig;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final chipFontSize = 11 * scale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _IgnitionChip(
              label: 'Ignition Wire',
              icon: Icons.power_settings_new_outlined,
              selected: ignitionSource == 'Ignition Wire',
              chipFontSize: chipFontSize,
              onTap: savingConfig ? null : () => onChanged('Ignition Wire'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _IgnitionChip(
              label: 'Motion-Based',
              icon: Icons.motion_photos_on_outlined,
              selected: ignitionSource == 'Motion-Based',
              chipFontSize: chipFontSize,
              onTap: savingConfig ? null : () => onChanged('Motion-Based'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IgnitionChip extends StatelessWidget {
  const _IgnitionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.chipFontSize,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final double chipFontSize;
  final VoidCallback? onTap;

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
                fontSize: chipFontSize,
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
