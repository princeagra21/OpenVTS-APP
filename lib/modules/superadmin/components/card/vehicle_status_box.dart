import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/superadmin_total_counts.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  SuperadminTotalCounts? _counts;

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

      final res = await _repo!.getTotalCounts(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (counts) {
          if (kDebugMode) {
            debugPrint(
              '[Home] GET /superadmin/dashboard/totalcounts status=2xx '
              'connected=${counts.liveConnected} running=${counts.liveRunning} '
              'stop=${counts.liveStop} inactive=${counts.liveInactive} '
              'noData=${counts.liveNoData}',
            );
          }

          if (!mounted) return;
          setState(() {
            _counts = counts;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (kDebugMode) {
            final status = err is ApiException ? err.statusCode : null;
            debugPrint(
              '[Home] GET /superadmin/dashboard/totalcounts status=${status ?? 'error'}',
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

  List<Map<String, dynamic>> get _statusData {
    final counts = _counts;
    final connectedCount = counts?.liveConnected ?? 0;
    final runningCount = counts?.liveRunning ?? 0;
    final idleCount = counts?.liveIdle ?? 0;
    final stopCount = counts?.liveStop ?? 0;
    final inactiveCount = counts?.liveInactive ?? 0;
    final noDataCount = counts?.liveNoData ?? 0;
    final total = connectedCount + runningCount + idleCount + stopCount + inactiveCount + noDataCount;
    double percent(int count) {
      if (total <= 0) return 0;
      return ((count * 10000) / total).roundToDouble() / 100;
    }

    return [
      {
        'label': 'CONNECTED',
        'count': connectedCount,
        'percent': percent(connectedCount),
      },
      {
        'label': 'RUNNING',
        'count': runningCount,
        'percent': percent(runningCount),
      },
      {'label': 'IDLE', 'count': idleCount, 'percent': percent(idleCount)},
      {'label': 'STOP', 'count': stopCount, 'percent': percent(stopCount)},
      {
        'label': 'INACTIVE (48H)',
        'count': inactiveCount,
        'percent': percent(inactiveCount),
      },
      {
        'label': 'NO DATA',
        'count': noDataCount,
        'percent': percent(noDataCount),
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
    if (key.startsWith('connected')) {
      return {'icon': Icons.wifi_outlined};
    }
    if (key.startsWith('running')) {
      return {'icon': Icons.show_chart_outlined};
    }
    if (key.startsWith('idle')) {
      return {'icon': Icons.pause_circle_outline};
    }
    if (key.startsWith('stop')) {
      return {'icon': Icons.stop_outlined};
    }
    if (key.contains('no data')) {
      return {'icon': Icons.storage_outlined};
    }
    if (key.contains('inactive')) {
      return {'icon': Icons.warning_amber_outlined};
    }
    return {'icon': null};
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final statusData = _statusData;
    final counts = _counts;
    final totalVehicles = counts?.totalVehicles ?? 0;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(
      screenWidth,
    );
    final double deviceLabelFontSize =
        AdaptiveUtils.isVerySmallScreen(screenWidth)
            ? 8.5
            : AdaptiveUtils.isSmallScreen(screenWidth)
                ? 8.5
                : 12.0;
    final double legendFontSize =
        AdaptiveUtils.isVerySmallScreen(screenWidth)
            ? 11.5
            : AdaptiveUtils.isSmallScreen(screenWidth)
                ? 11.5
                : 15.0;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final bool small = screenWidth < 420;
    final double scale = small ? 0.9 : 1.0;
    final double sectionTitleFs = 18 * scale;
    final double mainRowFs = 14 * scale;
    final double secondaryFs = 12 * scale;
    final double metaFs = 11 * scale;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.08),
          width: 1,
        ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loading
                        ? AppShimmer(
                            width: screenWidth * 0.34,
                            height: titleFontSize + 6,
                            radius: 8,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Vehicle Status',
                                style: AppUtils.headlineSmallBase.copyWith(
                                  fontSize: sectionTitleFs,
                                  height: 24 / 18,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                    SizedBox(height: spacing / 2),
                    _loading
                        ? AppShimmer(
                            width: screenWidth * 0.30,
                            height: descriptionFontSize + 4,
                            radius: 8,
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _loading
                      ? AppShimmer(
                          width: screenWidth * 0.12,
                          height: titleFontSize + 6,
                          radius: 8,
                        )
                      : Text(
                          _formatCount(totalVehicles),
                          style: AppUtils.headlineSmallBase.copyWith(
                            fontSize: mainRowFs,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                  SizedBox(height: spacing / 2),
                  Text(
                    'DEVICES',
                    style: AppUtils.bodySmallBase.copyWith(
                      fontSize: metaFs,
                      height: 14 / 11,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing + 6),
          if (_loading)
            Column(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing + 4,
                      vertical: spacing + 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppShimmer(
                              width: 40,
                              height: 40,
                              radius: 12,
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppShimmer(
                                    width: screenWidth * 0.28,
                                    height: mainRowFs + 6,
                                    radius: 6,
                                  ),
                                  SizedBox(height: spacing / 2),
                                  AppShimmer(
                                    width: screenWidth * 0.22,
                                    height: secondaryFs + 4,
                                    radius: 6,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: spacing),
                            AppShimmer(
                              width: screenWidth * 0.12,
                              height: mainRowFs + 6,
                              radius: 6,
                            ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        AppShimmer(
                          width: double.infinity,
                          height: 6,
                          radius: 999,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Column(
              children: statusData.map((data) {
                final label = data['label'] as String;
                final count = data['count'] as int;
                final percent = data['percent'] as double;
                final meta = getStatusMeta(label);
                final icon = meta['icon'] as IconData?;

                final title = label == 'INACTIVE (48H)'
                    ? 'Inactive \u00b7 48H'
                    : label[0] + label.substring(1).toLowerCase();

                return Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing + 4,
                      vertical: spacing + 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      colorScheme.onSurface.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                icon,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppUtils.bodySmallBase.copyWith(
                                      fontSize: mainRowFs,
                                      height: 20 / 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: spacing / 2),
                                  Text(
                                    '${percent.toStringAsFixed(0)}% of devices',
                                    style: AppUtils.bodySmallBase.copyWith(
                                      fontSize: secondaryFs,
                                      height: 16 / 12,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: spacing),
                            Text(
                              _formatCount(count),
                              style: AppUtils.bodySmallBase.copyWith(
                                fontSize: mainRowFs,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: (percent / 100).clamp(0.0, 1.0),
                            backgroundColor:
                                colorScheme.onSurface.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
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
