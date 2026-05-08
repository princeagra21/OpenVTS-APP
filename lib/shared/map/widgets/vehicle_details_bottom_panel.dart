import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:flutter/material.dart';

class VehicleDetailsBottomSheet extends StatelessWidget {
  final MapVehiclePoint? vehicle;
  final ScrollController scrollController;
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onClose;
  final VoidCallback onShowPath;
  final VoidCallback onStreetView;
  final VoidCallback onSendCommand;

  const VehicleDetailsBottomSheet({
    super.key,
    required this.vehicle,
    required this.scrollController,
    required this.selectedTabIndex,
    required this.onTabChanged,
    required this.onClose,
    required this.onShowPath,
    required this.onStreetView,
    required this.onSendCommand,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(
          color: cs.outline.withValues(alpha: isDark ? 0.14 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          _VehicleHeader(
            vehicle: vehicle,
            onClose: onClose,
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _VehicleSummaryRow(vehicle: vehicle),
                const SizedBox(height: 12),
                _VehicleDetailsTabBar(
                  selectedTabIndex: selectedTabIndex,
                  onTabChanged: onTabChanged,
                ),
                const SizedBox(height: 12),
                _VehicleDetailsTabContent(
                  vehicle: vehicle,
                  selectedTabIndex: selectedTabIndex,
                ),
                const SizedBox(height: 14),
                _VehicleActionBar(
                  vehicle: vehicle,
                  onShowPath: onShowPath,
                  onStreetView: onStreetView,
                  onSendCommand: onSendCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final MapVehiclePoint? vehicle;
  final VoidCallback onClose;

  const _VehicleHeader({
    required this.vehicle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _vehicleTitle(vehicle);
    final status = _vehicleStatus(vehicle);
    final statusColor = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusBadge(label: status, color: statusColor),
                    _HeaderMeta(icon: Icons.speed_rounded, label: _speedText(vehicle)),
                    _HeaderMeta(icon: Icons.power_settings_new_rounded, label: _ignitionText(vehicle)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }
}

class _VehicleSummaryRow extends StatelessWidget {
  final MapVehiclePoint? vehicle;

  const _VehicleSummaryRow({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final cards = [
          _SummaryData(
            icon: Icons.speed_rounded,
            label: 'Speed',
            value: _speedText(vehicle),
          ),
          _SummaryData(
            icon: Icons.power_settings_new_rounded,
            label: 'Ignition',
            value: _ignitionText(vehicle),
          ),
          _SummaryData(
            icon: Icons.satellite_alt_rounded,
            label: 'Satellites',
            value: _satelliteText(vehicle),
          ),
          _SummaryData(
            icon: Icons.access_time_rounded,
            label: 'Last Updated',
            value: _lastUpdatedText(vehicle),
          ),
        ];

        if (isWide) {
          return Row(
            children: List.generate(cards.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == cards.length - 1 ? 0 : 10),
                  child: _SummaryCard(data: cards[index]),
                ),
              );
            }),
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map(
                (card) => SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: _SummaryCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.58),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
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

class _VehicleDetailsTabBar extends StatelessWidget {
  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

  const _VehicleDetailsTabBar({
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const tabs = [
      'Vehicle Details',
      'Logs',
      'Replay',
      'Events',
      'Sensors',
    ];

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final selected = index == selectedTabIndex;
            return Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onTabChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : cs.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.black
                          : cs.outline.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : cs.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _VehicleDetailsTabContent extends StatelessWidget {
  final MapVehiclePoint? vehicle;
  final int selectedTabIndex;

  const _VehicleDetailsTabContent({
    required this.vehicle,
    required this.selectedTabIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTabIndex != 0) {
      final placeholder = switch (selectedTabIndex) {
        1 => 'No logs available',
        2 => 'Replay feature coming soon',
        3 => 'No events available',
        _ => 'No sensor data available',
      };
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Center(
          child: Text(
            placeholder,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final fields = _vehicleFields(vehicle);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    if (vehicle == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(
          child: Text(
            'No vehicle selected',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (!isWide) {
      return Column(
        children: fields
            .map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _VehicleDetailRow(
                  icon: field.icon,
                  label: field.label,
                  value: field.value,
                ),
              ),
            )
            .toList(),
      );
    }

    final columns = [<Widget>[], <Widget>[], <Widget>[]];
    for (var i = 0; i < fields.length; i++) {
      columns[i % 3].add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _VehicleDetailRow(
          icon: fields[i].icon,
          label: fields[i].label,
          value: fields[i].value,
        ),
      ));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: columns[0])),
        const SizedBox(width: 10),
        Expanded(child: Column(children: columns[1])),
        const SizedBox(width: 10),
        Expanded(child: Column(children: columns[2])),
      ],
    );
  }
}

class _VehicleDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _VehicleDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              value.isEmpty ? '–' : value,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleActionBar extends StatelessWidget {
  final MapVehiclePoint? vehicle;
  final VoidCallback onShowPath;
  final VoidCallback onStreetView;
  final VoidCallback onSendCommand;

  const _VehicleActionBar({
    required this.vehicle,
    required this.onShowPath,
    required this.onStreetView,
    required this.onSendCommand,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lastUpdated = _lastUpdatedText(vehicle);

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FooterButton(
                label: 'Show Path',
                icon: Icons.alt_route_rounded,
                onTap: onShowPath,
              ),
              _FooterButton(
                label: 'StreetView',
                icon: Icons.streetview_rounded,
                onTap: onStreetView,
              ),
              _FooterButton(
                label: 'Send Command',
                icon: Icons.send_rounded,
                onTap: onSendCommand,
              ),
            ],
          ),
          Text(
            'Last Updated: $lastUpdated',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FooterButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryData {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.72)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleField {
  final IconData icon;
  final String label;
  final String value;

  const _VehicleField({
    required this.icon,
    required this.label,
    required this.value,
  });
}

List<_VehicleField> _vehicleFields(MapVehiclePoint? vehicle) {
  final raw = vehicle?.raw ?? const <String, dynamic>{};

  String getField(List<Object?> keys) {
    for (final key in keys) {
      final value = _rawValue(raw, key);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  return [
    _VehicleField(icon: Icons.badge_outlined, label: 'Vehicle Number', value: getField([vehicle?.plateNumber, raw['vehicleNumber'], raw['name'], raw['vehicleName']])),
    _VehicleField(icon: Icons.memory_outlined, label: 'IMEI', value: getField([vehicle?.imei, raw['deviceImei'], raw['imeiNumber']])),
    _VehicleField(icon: Icons.confirmation_number_outlined, label: 'Plate Number', value: getField([vehicle?.plateNumber, raw['plateNumber'], raw['registrationNumber']])),
    _VehicleField(icon: Icons.directions_car_outlined, label: 'VIN Number', value: getField([raw['vin'], raw['vinNumber'], raw['vinNo']])),
    _VehicleField(icon: Icons.ev_station_outlined, label: 'Vehicle Type', value: getField([raw['vehicleType'], raw['type'], raw['vehicle_type']])),
    _VehicleField(icon: Icons.sensors_outlined, label: 'Status', value: getField([vehicle?.status, raw['motion'], raw['state']])),
    _VehicleField(icon: Icons.power_settings_new_rounded, label: 'Ignition', value: _ignitionText(vehicle)),
    _VehicleField(icon: Icons.speed_rounded, label: 'Speed', value: _speedText(vehicle)),
    _VehicleField(icon: Icons.satellite_alt_rounded, label: 'Satellites', value: _satelliteText(vehicle)),
    _VehicleField(icon: Icons.location_on_outlined, label: 'Lat / Long', value: _latLng(vehicle)),
    _VehicleField(icon: Icons.place_outlined, label: 'Address', value: getField([raw['fullAddress'], raw['address'], raw['addressLine']])),
    _VehicleField(icon: Icons.timeline_rounded, label: 'Today Distance', value: getField([raw['todayDistance'], raw['distanceToday'], raw['drivenKm']])),
    _VehicleField(icon: Icons.route_outlined, label: 'Odometer', value: getField([raw['odometer'], raw['odometerKm']])),
    _VehicleField(icon: Icons.schedule_rounded, label: 'Today Engine Hours', value: getField([raw['todayEngineHours'], raw['engineHoursToday']])),
    _VehicleField(icon: Icons.schedule_send_rounded, label: 'Total Engine Hours', value: getField([raw['totalEngineHours'], raw['engineHours']])),
    _VehicleField(icon: Icons.update_rounded, label: 'Last Updated', value: _lastUpdatedText(vehicle)),
  ];
}

String _vehicleTitle(MapVehiclePoint? vehicle) {
  if (vehicle == null) return 'Vehicle Details';
  final title = vehicle.plateNumber.trim();
  if (title.isNotEmpty) return title;
  final imei = vehicle.imei.trim();
  if (imei.isNotEmpty) return imei;
  final id = vehicle.vehicleId.trim();
  if (id.isNotEmpty) return id;
  return 'Vehicle Details';
}

String _vehicleStatus(MapVehiclePoint? vehicle) {
  final value = vehicle?.status.trim() ?? '';
  if (value.isEmpty) return '–';
  return value;
}

Color _statusColor(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.contains('run') || normalized.contains('move')) return Colors.green;
  if (normalized.contains('stop') || normalized.contains('park')) return Colors.redAccent;
  if (normalized.contains('idle')) return Colors.orange;
  if (normalized.contains('inactive') || normalized.contains('offline')) return Colors.grey;
  return Colors.black;
}

String _speedText(MapVehiclePoint? vehicle) {
  final speed = vehicle?.speed;
  if (speed == null) return '–';
  return speed % 1 == 0 ? '${speed.toStringAsFixed(0)} km/h' : '${speed.toStringAsFixed(1)} km/h';
}

String _ignitionText(MapVehiclePoint? vehicle) {
  final ignition = vehicle?.ignition.trim().toLowerCase() ?? '';
  if (ignition.isEmpty) return '–';
  if (ignition == 'true' || ignition == '1' || ignition == 'on' || ignition == 'yes' || ignition == 'active') {
    return 'ON';
  }
  if (ignition == 'false' || ignition == '0' || ignition == 'off' || ignition == 'no' || ignition == 'inactive') {
    return 'OFF';
  }
  return ignition.toUpperCase();
}

String _satelliteText(MapVehiclePoint? vehicle) {
  final raw = vehicle?.raw ?? const <String, dynamic>{};
  final values = [raw['satellites'], raw['satellite'], raw['gpsSatellites']];
  for (final item in values) {
    final text = item?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '–';
}

String _latLng(MapVehiclePoint? vehicle) {
  if (vehicle == null) return '–';
  return '${vehicle.lat.toStringAsFixed(6)}, ${vehicle.lng.toStringAsFixed(6)}';
}

String _lastUpdatedText(MapVehiclePoint? vehicle) {
  final text = vehicle?.updatedAt ?? '';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return '–';
  final local = parsed.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year $hh:$mm';
}

String _rawValue(Map<String, dynamic> raw, Object? key) {
  if (key == null) return '';
  final value = key is String ? raw[key] ?? key : key;
  if (value == null) return '';
  final text = value.toString().trim();
  return text.isEmpty ? '' : text;
}
