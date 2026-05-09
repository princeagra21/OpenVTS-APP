import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/features/admin_tools/server_status/server_status_controller.dart';

class ServerHealthSummary extends StatelessWidget {
  const ServerHealthSummary({super.key, required this.controller});

  final ServerStatusController controller;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final colorScheme = Theme.of(context).colorScheme;
    final state = controller.state;

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
                onPressed: state.isLoading ? null : () => controller.loadStatus(),
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
            _buildHealthIndicator(state.status!.overallHealth, width),
          ],
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