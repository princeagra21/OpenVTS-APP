import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/map_vehicle_point.dart';
import 'package:fleet_stack/core/models/vehicle_details.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:flutter/material.dart';

class VehicleDetailsBottomSheet extends StatefulWidget {
  final MapVehiclePoint vehicle;
  final SuperadminRepository repository;
  final ScrollController scrollController;
  final VoidCallback onClose;

  const VehicleDetailsBottomSheet({
    super.key,
    required this.vehicle,
    required this.repository,
    required this.scrollController,
    required this.onClose,
  });

  @override
  State<VehicleDetailsBottomSheet> createState() =>
      _VehicleDetailsBottomSheetState();
}

class _VehicleDetailsBottomSheetState extends State<VehicleDetailsBottomSheet> {
  CancelToken? _cancelToken;
  bool _loading = true;
  String? _error;
  VehicleDetails? _details;
  String _address = '–';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Vehicle details sheet disposed');
    super.dispose();
  }

  Future<void> _loadDetails() async {
    _cancelToken?.cancel('Reload vehicle details');
    final token = CancelToken();
    _cancelToken = token;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _details = null;
      _address = '–';
    });

    final imei = widget.vehicle.imei.trim();
    if (imei.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load vehicle details';
      });
      return;
    }

    final detailsRes = await widget.repository.getSuperadminVehicleDetailsByImei(
      imei,
      cancelToken: token,
    );
    if (!mounted || _cancelToken != token) return;

    if (detailsRes.isFailure || detailsRes.data == null) {
      setState(() {
        _loading = false;
        _error = 'Unable to load vehicle details';
      });
      return;
    }

    final details = detailsRes.data!;
    final telemetry = details.telemetry;
    final lat = _readDouble(
      telemetry['latitude'] ??
          telemetry['lat'] ??
          telemetry['locationLat'] ??
          telemetry['location_lat'],
    );
    final lng = _readDouble(
      telemetry['longitude'] ??
          telemetry['lng'] ??
          telemetry['lon'] ??
          telemetry['locationLng'] ??
          telemetry['location_lng'],
    );

    var address = '–';
    if (_isValidCoordinate(lat, lng)) {
      final addressRes = await widget.repository.reverseGeocode(
        lat!,
        lng!,
        cancelToken: token,
      );
      if (!mounted || _cancelToken != token) return;
      address = addressRes.data?.trim().isNotEmpty == true
          ? addressRes.data!.trim()
          : 'Address unavailable';
    }

    if (!mounted || _cancelToken != token) return;
    setState(() {
      _details = details;
      _address = address;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? cs.surface : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(
          color: cs.outline.withValues(alpha: isDark ? 0.14 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 0),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(Icons.close, color: cs.onSurface),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (_loading) _LoadingState(vehicle: widget.vehicle),
                  if (!_loading && _error != null)
                    _ErrorState(
                      title: _error!,
                      onRetry: _loadDetails,
                    ),
                  if (!_loading && _error == null && _details != null)
                    _CompactVehicleCard(
                      vehicle: widget.vehicle,
                      details: _details!,
                      address: _address,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final MapVehiclePoint vehicle;

  const _LoadingState({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.2,
              color: cs.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Loading vehicle details...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vehicle.plateNumber.trim().isEmpty
                  ? '–'
                  : vehicle.plateNumber.trim(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.title,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 34, color: cs.error),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactVehicleCard extends StatelessWidget {
  final MapVehiclePoint vehicle;
  final VehicleDetails details;
  final String address;

  const _CompactVehicleCard({
    required this.vehicle,
    required this.details,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _normalizeStatus(
      _firstNonEmpty([
        details.telemetry['status'],
        details.telemetry['motion'],
        details.status,
        vehicle.status,
      ]),
    );
    final statusColor = _statusColor(status);
    final name = _firstNonEmpty([
      details.name,
      vehicle.plateNumber,
      details.imei,
      vehicle.imei,
    ]);
    final imei = _firstNonEmpty([details.imei, vehicle.imei]);
    final speed = _formatSpeed(
      _firstNonEmpty([
        details.telemetry['speedKph'],
        details.telemetry['speed'],
        details.telemetry['currentSpeed'],
        details.speed,
        vehicle.speed,
      ]),
    );
    final lastUpdated = _formatLastUpdated(
      details.telemetry,
      details.lastSeen,
      vehicle.updatedAt,
    );
    final ignition = _formatIgnition(
      _firstNonEmpty([
        details.telemetry['ignition'],
        details.telemetry['isIgnitionOn'],
        details.telemetry['ignitionStatus'],
        details.ignition,
        vehicle.ignition,
      ]),
    );
    final odometer = _formatOdometer(
      _firstNonEmpty([
        details.telemetry['odometer'],
        details.telemetry['mileage'],
        details.odometer,
      ]),
    );
    final satellites = _formatInteger(
      _firstNonEmpty([
        details.telemetry['satellites'],
        details.telemetry['satellite'],
      ]),
    );
    final engineHours = _formatEngineHours(
      _firstNonEmpty([
        details.telemetry['engineHoursToday'],
        details.telemetry['totalengineHours'],
        details.engineHours,
      ]),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? cs.surface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusPill(label: status, color: statusColor),
                          Text(
                            lastUpdated,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.62),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SPEED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: cs.onSurface.withValues(alpha: 0.52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          speed.value,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            speed.suffix,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
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
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      address.trim().isEmpty ? '–' : address,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _LabeledValueRow(label: 'IMEI', value: imei),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricColumn(
                    label: 'ODOMETER',
                    value: odometer,
                  ),
                ),
                Expanded(
                  child: _MetricColumn(
                    label: 'IGNITION',
                    value: ignition,
                  ),
                ),
                Expanded(
                  child: _MetricColumn(
                    label: 'SATELLITES',
                    value: satellites,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LabeledValueRow(label: 'ENGINE HOURS', value: engineHours),
          ],
        ),
      ),
    );
  }
}

class _LabeledValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _LabeledValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            value.trim().isEmpty ? '–' : value,
            textAlign: TextAlign.right,
            softWrap: true,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetricColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.trim().isEmpty ? '–' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

_SpeedDisplay _formatSpeed(Object? value) {
  final speed = _readDouble(value);
  if (speed == null) return const _SpeedDisplay(value: '–', suffix: 'km/h');
  final text = speed == speed.truncateToDouble()
      ? speed.toStringAsFixed(0)
      : speed.toStringAsFixed(1);
  return _SpeedDisplay(value: text, suffix: 'km/h');
}

String _formatOdometer(Object? value) {
  final odometer = _readDouble(value);
  if (odometer == null) return '–';
  return odometer.toStringAsFixed(1);
}

String _formatInteger(Object? value) {
  final number = _readDouble(value);
  if (number == null) return '–';
  return number.truncate().toString();
}

String _formatIgnition(Object? value) {
  final normalized = _normalizeText(value);
  if (normalized.isEmpty) return '–';
  if (_isTruthy(normalized)) return 'On';
  if (_isFalsy(normalized)) return 'Off';
  return normalized;
}

String _formatEngineHours(Object? value) {
  if (value == null) return '–';
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '–';
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return _decimalHoursToText(parsed);
  }
  if (value is num) return _decimalHoursToText(value.toDouble());
  return value.toString();
}

String _decimalHoursToText(double hours) {
  if (hours <= 0) return '0m';
  final totalMinutes = (hours * 60).round();
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h > 0 && m > 0) return '${h}h ${m}m';
  if (h > 0) return '${h}h';
  return '${m}m';
}

String _formatLastUpdated(
  Map<String, dynamic> telemetry,
  String lastSeen,
  String fallback,
) {
  final candidates = [
    telemetry['serverTime'],
    telemetry['deviceTime'],
    telemetry['updatedAt'],
    lastSeen,
    fallback,
  ];

  for (final candidate in candidates) {
    final dt = _parseDateTime(candidate);
    if (dt == null) continue;
    final local = dt.toLocal();
    final age = DateTime.now().difference(local).abs();
    if (age.inMinutes < 2) {
      return 'Just now';
    }
    return _formatReadableDateTime(local);
  }

  return '–';
}

String _formatReadableDateTime(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]}, ${hour.toString().padLeft(2, '0')}:$minute $period';
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is num) {
    final millis = value > 1000000000000 ? value.toInt() : value.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final intValue = int.tryParse(text);
  if (intValue != null) {
    final millis = intValue > 1000000000000 ? intValue : intValue * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return DateTime.tryParse(text);
}

String _normalizeStatus(Object? value) {
  final text = _normalizeText(value);
  if (text.isEmpty) return 'No Data';
  if (_containsAny(text, const ['running', 'moving', 'online_moving', 'active_running'])) {
    return 'Running';
  }
  if (_containsAny(text, const ['stop', 'stopped', 'parked'])) {
    return 'Stop';
  }
  if (_containsAny(text, const ['idle', 'engine_idle'])) {
    return 'Idle';
  }
  if (_containsAny(text, const ['inactive', 'offline', 'disconnected'])) {
    return 'Inactive';
  }
  if (_containsAny(text, const ['no_data', 'nodata', 'unknown', 'missing'])) {
    return 'No Data';
  }
  return text.isEmpty ? 'No Data' : _titleCase(text);
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'running':
      return const Color(0xFF16A34A);
    case 'stop':
      return const Color(0xFFEC4899);
    case 'idle':
      return const Color(0xFFF59E0B);
    case 'inactive':
      return const Color(0xFF6B7280);
    case 'no data':
      return const Color(0xFF374151);
    default:
      return const Color(0xFF374151);
  }
}

bool _isTruthy(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'true' ||
      normalized == '1' ||
      normalized == 'on' ||
      normalized == 'yes' ||
      normalized == 'active';
}

bool _isFalsy(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'false' ||
      normalized == '0' ||
      normalized == 'off' ||
      normalized == 'no' ||
      normalized == 'inactive' ||
      normalized == 'disabled';
}

String _normalizeText(Object? value) {
  if (value == null) return '';
  if (value is String) return value.trim().toLowerCase();
  return value.toString().trim().toLowerCase();
}

bool _containsAny(String value, List<String> expected) {
  if (value.isEmpty) return false;
  return expected.any((item) => value == item || value.contains(item));
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

class _SpeedDisplay {
  final String value;
  final String suffix;

  const _SpeedDisplay({
    required this.value,
    required this.suffix,
  });
}

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

bool _isValidCoordinate(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (!lat.isFinite || !lng.isFinite) return false;
  if (lat == 0 && lng == 0) return false;
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

String _firstNonEmpty(Iterable<Object?> values) {
  for (final value in values) {
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '–';
}
