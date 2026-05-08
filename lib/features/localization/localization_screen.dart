import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_vts/core/repositories/common_repository.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/design_system/components/open_vts_card.dart';
import 'package:open_vts/features/localization/localization_controller.dart';
import 'package:open_vts/features/localization/localization_repository.dart';
import 'package:open_vts/features/localization/localization_role_config.dart';
import 'package:open_vts/features/localization/widgets/localization_date_time_section.dart';
import 'package:open_vts/features/localization/widgets/localization_direction_section.dart';
import 'package:open_vts/features/localization/widgets/localization_language_section.dart';
import 'package:open_vts/features/localization/widgets/localization_preview_card.dart';
import 'package:open_vts/features/localization/widgets/localization_save_bar.dart';
import 'package:open_vts/features/localization/widgets/localization_units_section.dart';
import 'package:open_vts/main.dart' show themeController;

class LocalizationScreen extends StatefulWidget {
  const LocalizationScreen({super.key, required this.config, this.repository});

  final LocalizationRoleConfig config;
  final LocalizationRepository? repository;

  @override
  State<LocalizationScreen> createState() => _LocalizationScreenState();
}

class _LocalizationScreenState extends State<LocalizationScreen> {
  late final LocalizationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LocalizationController(
      config: widget.config,
      repository:
          widget.repository ??
          LocalizationRepository.forRole(widget.config.role),
    );
    _controller.addListener(_onControllerChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _load() async {
    final message = await _controller.loadLocalizationData();
    if (!mounted || message == null) {
      return;
    }
    _showSnack(message);
  }

  Future<void> _save() async {
    final result = await _controller.saveLocalization(showSuccess: true);
    if (!mounted || result.message == null) {
      return;
    }
    _showSnack(result.message!);
  }

  Future<void> _pickLanguage() async {
    if (_controller.loading || _controller.languages.isEmpty) {
      return;
    }

    final picked = await showModalBottomSheet<ReferenceOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final searchController = TextEditingController();
        String query = '';

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = _controller.languages.where((option) {
                  final text = '${option.label} ${option.value}'
                      .toLowerCase()
                      .trim();
                  return text.contains(query.toLowerCase().trim());
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Language',
                              style: AppFonts.roboto(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: Icon(Icons.close, color: colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchController,
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Search language',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (_, index) {
                            final option = filtered[index];
                            return ListTile(
                              title: Text(option.label),
                              onTap: () => Navigator.pop(sheetContext, option),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null) {
      _controller.setSelectedLanguage(picked.value);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(width);

    if (_controller.loading) {
      return _LocalizationLoadingView(horizontalPadding: horizontalPadding);
    }

    final selectedTheme = switch (themeController.themeMode.value) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OpenVtsCard(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizationSaveBar(
                title: widget.config.title,
                onReset: _controller.reset,
                onSave: _save,
                saving: _controller.saving,
                saveDisabled: _controller.saveDisabled,
              ),
              const SizedBox(height: 16),
              LocalizationPreviewCard(
                selectedLanguage: _controller.selectedLanguage,
                textDirection: _controller.textDirection,
                timezone: _controller.timezone,
                units: _controller.units,
                lat: _controller.lat,
                lng: _controller.lng,
                zoom: _controller.zoom,
                formattedDate: _controller.getFormattedDate(),
                formattedTime: _controller.getFormattedTime(),
              ),
              const SizedBox(height: 24),
              LocalizationLanguageSection(
                languages: _controller.languages,
                selectedLanguage: _controller.selectedLanguage,
                onPickLanguage: _pickLanguage,
              ),
              const SizedBox(height: 24),
              LocalizationDirectionSection(
                textDirection: _controller.textDirection,
                onDirectionChanged: (value) {
                  unawaited(_controller.setTextDirection(value));
                },
              ),
              const SizedBox(height: 24),
              LocalizationDateTimeSection(
                dateFormats: _controller.dateFormats,
                dateFormat: _controller.dateFormat,
                timeFormat: _controller.timeFormat,
                timezones: _controller.timezones,
                timezone: _controller.timezone,
                selectedTheme: selectedTheme,
                onDateFormatChanged: _controller.setDateFormat,
                onTimeFormatChanged: _controller.setTimeFormat,
                onTimezoneChanged: _controller.setTimezone,
                onThemeChanged: (value) {
                  unawaited(_controller.setThemeMode(value));
                },
              ),
              const SizedBox(height: 24),
              LocalizationUnitsSection(
                units: _controller.units,
                onUnitsChanged: (value) {
                  unawaited(_controller.setUnits(value));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _MapCoordinatesCard(controller: _controller),
        const SizedBox(height: 24),
        _QuickPresetsCard(
          onPresetTap: _controller.applyPreset,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _MapCoordinatesCard extends StatelessWidget {
  const _MapCoordinatesCard({required this.controller});

  final LocalizationController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Map Focus Coordinates',
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _CoordinateField(
            label: 'Latitude (N/S)',
            controller: controller.latController,
          ),
          const SizedBox(height: 6),
          Text(
            'Range: -90 to 90',
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          _CoordinateField(
            label: 'Longitude (E/W)',
            controller: controller.lngController,
          ),
          const SizedBox(height: 6),
          Text(
            'Range: -180 to 180',
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          _CoordinateField(
            label: 'Zoom Level',
            controller: controller.zoomController,
          ),
          const SizedBox(height: 6),
          Text(
            'Typical: 1 to 20',
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinateField extends StatelessWidget {
  const _CoordinateField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface.withValues(alpha: 0.87),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: AppFonts.roboto(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 2,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
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
          ),
        ),
      ],
    );
  }
}

class _QuickPresetsCard extends StatelessWidget {
  const _QuickPresetsCard({
    required this.onPresetTap,
    required this.colorScheme,
  });

  final void Function(double lat, double lng) onPresetTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const presets = [
      {'name': 'New Delhi', 'lat': 28.6139, 'lng': 77.2090},
      {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
      {'name': 'Bengaluru', 'lat': 12.9716, 'lng': 77.5946},
      {'name': 'Kolkata', 'lat': 22.5726, 'lng': 88.3639},
    ];

    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Location Presets',
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final cellWidth = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: presets.map((preset) {
                  final name = preset['name'] as String;
                  final lat = preset['lat'] as double;
                  final lng = preset['lng'] as double;
                  return SizedBox(
                    width: cellWidth,
                    child: InkWell(
                      onTap: () => onPresetTap(lat, lng),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppFonts.roboto(
                                fontSize:
                                    AdaptiveUtils.getTitleFontSize(width) + 2,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                              style: AppFonts.roboto(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    3,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LocalizationLoadingView extends StatelessWidget {
  const _LocalizationLoadingView({required this.horizontalPadding});

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              AppShimmer(width: 100, height: 36, radius: 8),
              SizedBox(width: 12),
              AppShimmer(width: 92, height: 36, radius: 8),
            ],
          ),
          const SizedBox(height: 16),
          const AppShimmer(width: 240, height: 24, radius: 8),
          const SizedBox(height: 8),
          const AppShimmer(width: double.infinity, height: 16, radius: 8),
          const SizedBox(height: 24),
          const AppShimmer(width: double.infinity, height: 220, radius: 12),
          const SizedBox(height: 24),
          const AppShimmer(width: double.infinity, height: 140, radius: 12),
          const SizedBox(height: 24),
          const AppShimmer(width: double.infinity, height: 140, radius: 12),
        ],
      ),
    );
  }
}
