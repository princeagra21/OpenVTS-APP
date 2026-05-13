import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin_tools/domain/entities/server_status.dart';

class ServerHealthSummary extends StatelessWidget {
  const ServerHealthSummary({super.key, required this.state, required this.onRefresh});

  final ServerStatusState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Server Health",
                    style: AppFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "System Status Overview",
                    style: AppFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: AppShimmer(width: 12, height: 12, radius: 6),
                    ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: hp + 2,
                    vertical: hp - 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: SizedBox(
                  width: AdaptiveUtils.getIconSize(width),
                  height: AdaptiveUtils.getIconSize(width),
                  child: state.isLoading
                      ? AppShimmer(
                          width: AdaptiveUtils.getIconSize(width),
                          height: AdaptiveUtils.getIconSize(width),
                          radius: AdaptiveUtils.getIconSize(width) / 2,
                        )
                      : Icon(
                          Icons.refresh,
                          color: colorScheme.onPrimary,
                          size: AdaptiveUtils.getIconSize(width),
                        ),
                ),
                label: Text(
                  "Refresh",
                  style: AppFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (state.status != null) ...[
            const SizedBox(height: 24),
            _buildStatusContent(state.status!, width, colorScheme),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: AppFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusContent(
    ServerStatusModel status,
    double width,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHealthIndicator(status.overallHealth, width),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricTile(
              'CPU',
              status.metrics.cpuUsage,
              width,
              colorScheme,
            ),
            _buildMetricTile(
              'Memory',
              status.metrics.memoryUsage,
              width,
              colorScheme,
            ),
            for (final entry in status.metrics.diskUsage.entries)
              _buildMetricTile(
                'Disk ${entry.key}',
                entry.value,
                width,
                colorScheme,
              ),
          ],
        ),
        if (status.services.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Services',
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ...status.services.values.map(
            (service) => _buildServiceRow(service, width, colorScheme),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile(
    String label,
    double value,
    double width,
    ColorScheme colorScheme,
  ) {
    final color = value >= 90
        ? Colors.red
        : value >= 75
        ? Colors.orange
        : Colors.green;

    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (value / 100).clamp(0, 1).toDouble(),
            color: color,
            backgroundColor: color.withOpacity(0.16),
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: AppFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width) - 6,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(
    ServiceStatus service,
    double width,
    ColorScheme colorScheme,
  ) {
    final color = switch (service.status) {
      'healthy' => Colors.green,
      'warning' => Colors.orange,
      'error' => Colors.red,
      _ => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.roboto(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 6,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            service.status.toUpperCase(),
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String health, double width) {
    final color = switch (health) {
      'healthy' => Colors.green,
      'warning' => Colors.orange,
      'error' => Colors.red,
      _ => Colors.grey,
    };

    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          health.toUpperCase(),
          style: AppFonts.roboto(
            fontSize: AdaptiveUtils.getTitleFontSize(width) - 4,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
