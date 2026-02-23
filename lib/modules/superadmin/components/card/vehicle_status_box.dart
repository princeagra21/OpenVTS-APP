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
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class VehicleStatusBox extends StatefulWidget {
  const VehicleStatusBox({super.key});

  @override
  State<VehicleStatusBox> createState() => _VehicleStatusBoxState();
}

class _VehicleStatusBoxState extends State<VehicleStatusBox> {
  int? touchedIndex;

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

  Color _lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final int red = (color.red + (255 - color.red) * amount).round();
    final int green = (color.green + (255 - color.green) * amount).round();
    final int blue = (color.blue + (255 - color.blue) * amount).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final int red = (color.red * (1 - amount)).round();
    final int green = (color.green * (1 - amount)).round();
    final int blue = (color.blue * (1 - amount)).round();
    return Color.fromARGB(color.alpha, red, green, blue);
  }

  List<Color> getColors(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final modeBrightness = Theme.of(context).brightness;
    final primaryBrightness = ThemeData.estimateBrightnessForColor(primary);

    if (modeBrightness == primaryBrightness) {
      if (primaryBrightness == Brightness.dark) {
        final shifted = _lighten(primary, 0.4);
        return [
          shifted,
          _darken(shifted, 0.2),
          _darken(shifted, 0.4),
          _darken(shifted, 0.6),
        ];
      } else {
        final shifted = _darken(primary, 0.4);
        return [
          shifted,
          _lighten(shifted, 0.2),
          _lighten(shifted, 0.4),
          _lighten(shifted, 0.6),
        ];
      }
    } else {
      return [
        primary,
        _darken(primary, 0.3),
        _darken(primary, 0.5),
        _darken(primary, 0.7),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final statusData = _statusData;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double legendFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double chartHeight = AdaptiveUtils.isVerySmallScreen(screenWidth)
        ? 180
        : AdaptiveUtils.isSmallScreen(screenWidth)
        ? 200
        : 220;

    final double baseRadius = AdaptiveUtils.getButtonSize(screenWidth) + 34;
    final double touchedRadius = baseRadius + 20;
    final double centerRadius = AdaptiveUtils.getIconSize(screenWidth) + 14;

    final double touchedFontSize = titleFontSize;
    final double normalFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    final colors = getColors(context);
    final showSkeleton = _loading;

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
            children: [
              CircleAvatar(
                radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.2,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(Icons.directions_car, color: colorScheme.primary),
              ),
              SizedBox(width: padding),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Vehicle Status",
                      style: GoogleFonts.inter(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_loading)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: AppShimmer(width: 12, height: 12, radius: 6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: padding + 4),
          if (showSkeleton)
            SizedBox(
              height: chartHeight,
              child: Center(
                child: AppShimmer(
                  width: chartHeight * 0.8,
                  height: chartHeight * 0.8,
                  radius: chartHeight,
                ),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = null;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!
                            .touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: centerRadius,
                  sections: statusData.asMap().entries.map((entry) {
                    final i = entry.key;
                    final data = entry.value;
                    final isTouched = i == touchedIndex;

                    final sectionColor = colors[i];
                    final textColor =
                        ThemeData.estimateBrightnessForColor(sectionColor) ==
                            Brightness.light
                        ? Colors.black
                        : Colors.white;

                    return PieChartSectionData(
                      color: sectionColor,
                      value: (data['percent'] as double),
                      title: isTouched ? '${data["percent"]}%' : '',
                      radius: isTouched ? touchedRadius : baseRadius,
                      titleStyle: GoogleFonts.inter(
                        fontSize: isTouched ? touchedFontSize : normalFontSize,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          SizedBox(height: padding + 4),
          if (showSkeleton)
            Wrap(
              spacing: padding,
              runSpacing: AdaptiveUtils.getLeftSectionSpacing(screenWidth),
              children: List<Widget>.generate(
                4,
                (_) => AppShimmer(
                  width: screenWidth * 0.3,
                  height: legendFontSize + 10,
                  radius: 8,
                ),
              ),
            )
          else
            Wrap(
              spacing: padding,
              runSpacing: AdaptiveUtils.getLeftSectionSpacing(screenWidth),
              children: statusData.asMap().entries.map((entry) {
                final i = entry.key;
                final data = entry.value;
                final count = (data['count'] as int);
                final percent = (data['percent'] as double);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[i],
                      ),
                    ),
                    SizedBox(width: padding / 2),
                    Text(
                      data["label"] as String,
                      style: GoogleFonts.inter(
                        fontSize: legendFontSize,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(count),
                      style: GoogleFonts.inter(
                        fontSize: legendFontSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($percent%)',
                      style: GoogleFonts.inter(
                        fontSize: legendFontSize,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
