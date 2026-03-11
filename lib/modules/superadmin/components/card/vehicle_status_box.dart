import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/vehicle_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class VehicleStatusBox extends StatefulWidget {
  const VehicleStatusBox({super.key});

  @override
  State<VehicleStatusBox> createState() => _VehicleStatusBoxState();
}

class _VehicleStatusBoxState extends State<VehicleStatusBox> {
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  ApiClient? _api;
  SuperadminRepository? _repo;

  int _runningCount = 0;
  int _stopCount = 0;
  int _notWorkingCount = 0;
  int _noDataCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVehicleStatus();
  }

  @override
  void dispose() {
    _token?.cancel('VehicleStatusBox disposed');
    super.dispose();
  }

  Future<void> _loadVehicleStatus() async {
    _token?.cancel('Reload vehicle status');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getVehicles(limit: 1000, cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (vehicles) {
          var running = 0;
          var stop = 0;
          var notWorking = 0;
          var noData = 0;

          for (final vehicle in vehicles) {
            switch (_bucketFor(vehicle)) {
              case 'Running':
                running += 1;
              case 'Stop':
                stop += 1;
              case 'Not Working (48h)':
                notWorking += 1;
              case 'No Data':
                noData += 1;
            }
          }

          if (kDebugMode) {
            debugPrint(
              '[Home] GET /superadmin/vehicles status=2xx '
              'running=$running stop=$stop notWorking=$notWorking noData=$noData',
            );
          }

          if (!mounted) return;
          setState(() {
            _runningCount = running;
            _stopCount = stop;
            _notWorkingCount = notWorking;
            _noDataCount = noData;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint(
              '[Home] GET /superadmin/vehicles status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load vehicle status.")),
          );
        },
      );
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Home] GET /superadmin/vehicles status=error');
      }
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load vehicle status.")),
      );
    }
  }

  String _bucketFor(VehicleListItem vehicle) {
    final status = vehicle.status.trim().toLowerCase();
    final lastSeen = DateTime.tryParse(vehicle.updatedAt);
    final now = DateTime.now().toUtc();
    final isOlderThan48h =
        lastSeen != null && now.difference(lastSeen.toUtc()).inHours >= 48;

    if (status.contains('no data') || status.contains('nodata')) {
      return 'No Data';
    }
    if (status.contains('not working') ||
        status.contains('offline') ||
        status.contains('inactive') ||
        status.contains('disconnected')) {
      return 'Not Working (48h)';
    }
    if (status.contains('stop') ||
        status.contains('stopped') ||
        status.contains('idle') ||
        status.contains('parked')) {
      return 'Stop';
    }
    if (status.contains('running') ||
        status.contains('moving') ||
        status.contains('active') ||
        status.contains('online')) {
      return 'Running';
    }
    if (isOlderThan48h) return 'Not Working (48h)';
    if (lastSeen == null) return 'No Data';
    return 'Stop';
  }

  List<Map<String, dynamic>> get _statusData {
    final total = _runningCount + _stopCount + _notWorkingCount + _noDataCount;
    double percent(int count) {
      if (total <= 0) return 0;
      return ((count * 10000) / total).roundToDouble() / 100;
    }

    return [
      {
        'label': 'Running',
        'count': _runningCount,
        'percent': percent(_runningCount),
      },
      {'label': 'Stop', 'count': _stopCount, 'percent': percent(_stopCount)},
      {
        'label': 'Not Working (48h)',
        'count': _notWorkingCount,
        'percent': percent(_notWorkingCount),
      },
      {
        'label': 'No Data',
        'count': _noDataCount,
        'percent': percent(_noDataCount),
      },
    ];
  }

  String _formatCount(int value) {
    final text = value.toString();
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Map<String, dynamic> getStatusMeta(String label) {
    final key = label.toLowerCase();
    if (key.startsWith('running')) {
      return {'color': Colors.green, 'icon': Icons.check};
    }
    if (key.startsWith('stop')) {
      return {
        'color': Colors.yellow[700]!,
        'icon': Icons.warning_amber_rounded,
      };
    }
    if (key.contains('not work')) {
      return {'color': Colors.redAccent, 'icon': Icons.error_outline};
    }
    return {'color': Colors.grey[400]!, 'icon': null};
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final statusData = _statusData;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    );
    final double legendFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.2,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(Icons.directions_car, color: colorScheme.primary),
              ),
              SizedBox(width: padding),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _loading
                      ? AppShimmer(
                          width: screenWidth * 0.34,
                          height: titleFontSize + 6,
                          radius: 8,
                        )
                      : Text(
                          'Vehicle Status',
                          style: GoogleFonts.inter(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                  SizedBox(height: spacing / 2),
                  _loading
                      ? AppShimmer(
                          width: screenWidth * 0.30,
                          height: descriptionFontSize + 4,
                          radius: 8,
                        )
                      : Text(
                          'Live distribution',
                          style: GoogleFonts.inter(
                            fontSize: descriptionFontSize,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing + 6),
          Column(
            children: statusData.map((data) {
              final label = data['label'] as String;
              final count = data['count'] as int;
              final percent = data['percent'] as double;
              final meta = getStatusMeta(label);
              final dotColor = meta['color'] as Color;
              final innerIcon = meta['icon'] as IconData?;
              const bulletSize = 18.0;
              const innerIconSize = 12.0;

              final countText = _formatCount(count);
              final percentText = '(${percent.toStringAsFixed(1)}%)';

              return Padding(
                padding: EdgeInsets.symmetric(vertical: spacing / 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: bulletSize,
                      height: bulletSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                      child: innerIcon != null
                          ? Center(
                              child: Icon(
                                innerIcon,
                                size: innerIconSize,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _loading
                          ? AppShimmer(
                              width: screenWidth * 0.32,
                              height: legendFontSize + 4,
                              radius: 7,
                            )
                          : Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: legendFontSize,
                                color: colorScheme.onSurface.withOpacity(0.87),
                              ),
                            ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_loading)
                          AppShimmer(
                            width: screenWidth * 0.16,
                            height: legendFontSize + 6,
                            radius: 7,
                          )
                        else
                          Text(
                            countText,
                            style: GoogleFonts.inter(
                              fontSize: legendFontSize,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        if (_loading) ...[
                          const SizedBox(height: 4),
                          AppShimmer(
                            width: screenWidth * 0.13,
                            height: legendFontSize + 4,
                            radius: 7,
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            percentText,
                            style: GoogleFonts.inter(
                              fontSize: legendFontSize,
                              fontWeight: FontWeight.w600,
                              color: dotColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          SizedBox(height: padding),
        ],
      ),
    );
  }
}
