import 'package:flutter/material.dart';
import 'package:open_vts/core/models/user_notification_preferences.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/modules/user/screens/notification/push_notification/config.dart';

class PushNotificationVehicleAlertCard extends StatelessWidget {
  const PushNotificationVehicleAlertCard({
    super.key,
    required this.vehicle,
    required this.ignitionEnabled,
    required this.alarmEnabled,
    required this.onIgnitionTap,
    required this.onAlarmTap,
  });

  final UserNotificationVehicle vehicle;
  final bool ignitionEnabled;
  final bool alarmEnabled;
  final VoidCallback onIgnitionTap;
  final VoidCallback onAlarmTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);

    return _VehicleCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehicleIdentityHeader(vehicle: vehicle, fontSize: fontSize),
          const SizedBox(height: 12),
          Container(
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
                  child: _VehicleActionButton(
                    label: 'Ignition',
                    icon: Icons.power_settings_new_outlined,
                    enabled: ignitionEnabled,
                    onTap: onIgnitionTap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VehicleActionButton(
                    label: 'Alarm',
                    icon: Icons.notifications_outlined,
                    enabled: alarmEnabled,
                    onTap: onAlarmTap,
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

class PushNotificationVehicleSpeedFormCard extends StatelessWidget {
  const PushNotificationVehicleSpeedFormCard({
    super.key,
    required this.vehicle,
    required this.enabled,
    required this.controller,
    required this.onToggle,
    required this.onSubmit,
  });

  final UserNotificationVehicle vehicle;
  final bool enabled;
  final TextEditingController controller;
  final VoidCallback onToggle;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);

    return _VehicleCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _VehicleIdentityHeader(vehicle: vehicle, fontSize: fontSize)),
              const SizedBox(width: 8),
              _EnablePill(enabled: enabled, onTap: onToggle),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Speed Limit (kph)',
            style: AppFonts.roboto(
              fontSize: fontSize - 2,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            onSubmitted: onSubmit,
            style: AppFonts.roboto(
              fontSize: fontSize,
              height: 20 / 14,
              color: enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            decoration: InputDecoration(
              hintText: 'Enter speed limit',
              hintStyle: AppFonts.roboto(
                fontSize: fontSize - 1,
                height: 20 / 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.check_circle, color: colorScheme.primary),
                onPressed: enabled ? () => onSubmit(controller.text) : null,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PushNotificationVehicleGeofenceCard extends StatelessWidget {
  const PushNotificationVehicleGeofenceCard({
    super.key,
    required this.vehicle,
    required this.enabled,
    required this.onToggle,
  });

  final UserNotificationVehicle vehicle;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);

    return _VehicleCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehicleIdentityHeader(vehicle: vehicle, fontSize: fontSize),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  PushNotificationConfig.geofenceZoneName,
                  style: AppFonts.roboto(
                    fontSize: fontSize,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _EnablePill(enabled: enabled, onTap: onToggle),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleCardContainer extends StatelessWidget {
  const _VehicleCardContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class _VehicleIdentityHeader extends StatelessWidget {
  const _VehicleIdentityHeader({required this.vehicle, required this.fontSize});

  final UserNotificationVehicle vehicle;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainerHighest
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            vehicle.name.isNotEmpty ? vehicle.name.trim()[0].toUpperCase() : 'V',
            style: AppFonts.roboto(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.name.isEmpty ? 'Vehicle' : vehicle.name,
                style: AppFonts.roboto(
                  fontSize: fontSize,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                vehicle.plateNumber.isEmpty ? '—' : vehicle.plateNumber,
                style: AppFonts.roboto(
                  fontSize: fontSize - 2,
                  height: 16 / 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleActionButton extends StatelessWidget {
  const _VehicleActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: fontSize - 1,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: enabled ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnablePill extends StatelessWidget {
  const _EnablePill({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? colorScheme.primary.withValues(alpha: 0.12) : colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: enabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: enabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              enabled ? 'Enabled' : 'Enable',
              style: AppFonts.roboto(
                fontSize: fontSize - 2,
                height: 16 / 12,
                fontWeight: FontWeight.w600,
                color: enabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

