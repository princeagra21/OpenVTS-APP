part of 'vehicle_details_screen.dart';

extension _VehicleDetailsConfigTab on _VehicleDetailsScreenState {
  Widget _buildVehicleConfigTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fs = 14 * scale;
    final fsSection = 18 * scale;
    final fsAction = 14 * scale;
    final fsActionIcon = 16 * scale;

    if (_loadingConfig) {
      return const AppShimmer(width: double.infinity, height: 320, radius: 12);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
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
                  color: cs.onSurface,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: (_savingConfig || _loadingConfig)
                        ? null
                        : () => setState(_applyConfigSnapshot),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh_outlined,
                      color: cs.onSurface,
                      size: fsActionIcon,
                    ),
                    label: Text(
                      'Reset',
                      style: AppFonts.roboto(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: fsAction,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (_savingConfig || _loadingConfig)
                        ? null
                        : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: SizedBox(
                      width: fsActionIcon,
                      height: fsActionIcon,
                      child: _savingConfig
                          ? AppShimmer(
                              width: fsActionIcon,
                              height: fsActionIcon,
                              radius: fsActionIcon / 2,
                            )
                          : Icon(
                              Icons.save_outlined,
                              color: cs.onPrimary,
                              size: fsActionIcon,
                            ),
                    ),
                    label: Text(
                      'Save',
                      style: AppFonts.roboto(
                        color: cs.onPrimary,
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
          _buildConfigSection(
            context: context,
            icon: Icons.speed,
            title: 'Speed Multiplier',
            subtitle: 'Speed ×',
            child: _numberField(controller: _speedController, unit: '×'),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.route_outlined,
            title: 'Distance Multiplier',
            subtitle: 'Distance ×',
            child: _numberField(controller: _distanceController, unit: '×'),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.av_timer_outlined,
            title: 'Set Odometer',
            subtitle: 'Odometer',
            child: _numberField(
              controller: _odometerController,
              unit: 'km',
              step: 1,
            ),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.timer_outlined,
            title: 'Set Engine Hours',
            subtitle: 'Engine Hours',
            child: _numberField(
              controller: _engineHoursController,
              unit: 'h',
              step: 1,
            ),
            scale: scale,
          ),
          const SizedBox(height: 24),
          _buildConfigSection(
            context: context,
            icon: Icons.power_settings_new_outlined,
            title: 'Ignition Source',
            subtitle: 'Ignition Wire / Motion-Based',
            child: _ignitionSourceBox(),
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fs = 12 * scale;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppFonts.roboto(fontSize: fs, color: colorScheme.onSurface),
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
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        suffixText: unit,
        suffixStyle: AppFonts.roboto(
          fontSize: fs,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.87),
        ),
      ),
    );
  }

  void _increment(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value += step;
    controller.text = step < 1
        ? value.toStringAsFixed(2)
        : value.toStringAsFixed(0);
    setState(() {});
  }

  void _decrement(TextEditingController controller, [double step = 0.01]) {
    double value = double.tryParse(controller.text) ?? 0;
    value -= step;
    if (value < 0) value = 0;
    controller.text = step < 1
        ? value.toStringAsFixed(2)
        : value.toStringAsFixed(0);
    setState(() {});
  }

  Widget _configBox({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String unit,
    double step = 0.01,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double fs = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.roboto(
              fontSize: fs + 2,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppFonts.roboto(
              fontSize: fs - 2,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          _numberField(controller: controller, unit: unit, step: step),
        ],
      ),
    );
  }

  Widget _ignitionSourceBox() {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double chipFs = 11 * scale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _savingConfig
                  ? null
                  : () => setState(() => _ignitionSource = 'Ignition Wire'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _ignitionSource == 'Ignition Wire'
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.power_settings_new_outlined,
                      size: 16,
                      color: _ignitionSource == 'Ignition Wire'
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ignition Wire',
                      style: AppFonts.roboto(
                        fontSize: chipFs,
                        color: _ignitionSource == 'Ignition Wire'
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: _savingConfig
                  ? null
                  : () => setState(() => _ignitionSource = 'Motion-Based'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _ignitionSource == 'Motion-Based'
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.motion_photos_on_outlined,
                      size: 16,
                      color: _ignitionSource == 'Motion-Based'
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Motion-Based',
                      style: AppFonts.roboto(
                        fontSize: chipFs,
                        color: _ignitionSource == 'Motion-Based'
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? child,
    required double scale,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double titleFs = 18 * scale;
    final double subtitleFs = 12 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
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
                        fontSize: titleFs,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppFonts.roboto(
                          fontSize: subtitleFs,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }
}
