import 'package:flutter/material.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';

class VehicleDetailsInfoTab extends StatelessWidget {
  const VehicleDetailsInfoTab({
    super.key,
    required this.details,
    required this.loading,
    required this.horizontalPadding,
    required this.spacing,
    required this.width,
    required this.safe,
  });

  final UserVehicleDetails? details;
  final bool loading;
  final double horizontalPadding;
  final double spacing;
  final double width;
  final String Function(String?) safe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final cardPadding = horizontalPadding + 4;

    final name = safe(details?.name);
    final plate = safe(details?.plateNumber);
    final type = safe(details?.vehicleTypeName);
    final imei = safe(details?.imei);
    final sim = safe(details?.simNumber);
    final vin = safe(details?.vin);

    final device = details?.device;
    final speedVariation = safe(device?['speedVariation']?.toString());
    final distanceVariation = safe(device?['distanceVariation']?.toString());
    final odometer = safe(device?['odometer']?.toString());
    final engineHours = safe(device?['engineHours']?.toString());
    final deviceStatus = safe(device?['status']?.toString());

    final plan = details?.plan;
    final planName = safe(plan?['name']?.toString());
    final planPrice = safe(plan?['price']?.toString());
    final planCurrency = safe(plan?['currency']?.toString());
    final amountText = planPrice == '—'
        ? planCurrency
        : planCurrency == '—'
            ? planPrice
            : '$planCurrency $planPrice';

    if (loading) {
      return _buildVehicleDetailsShimmer(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MainIdentityCard(
                spacing: spacing,
                fsMain: fsMain,
                fsSecondary: fsSecondary,
                fsMeta: fsMeta,
                name: name,
                plate: plate,
                type: type,
                sim: sim,
                imei: imei,
                vin: vin,
              ),
              SizedBox(height: spacing * 2),
              _DeviceMetricsCard(
                spacing: spacing,
                fsMain: fsMain,
                fsMeta: fsMeta,
                width: width,
                status: deviceStatus,
                speedVariation: speedVariation,
                distanceVariation: distanceVariation,
                odometer: odometer,
                engineHours: engineHours,
              ),
              SizedBox(height: spacing * 2),
              _PlanDetailsCard(
                spacing: spacing,
                fsMain: fsMain,
                fsMeta: fsMeta,
                width: width,
                planName: planName,
                amountText: amountText,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDetailsShimmer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing + 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppShimmer(width: double.infinity, height: 160, radius: 16),
          SizedBox(height: 16),
          AppShimmer(width: double.infinity, height: 140, radius: 16),
          SizedBox(height: 16),
          AppShimmer(width: double.infinity, height: 140, radius: 16),
        ],
      ),
    );
  }
}

class _MainIdentityCard extends StatelessWidget {
  const _MainIdentityCard({
    required this.spacing,
    required this.fsMain,
    required this.fsSecondary,
    required this.fsMeta,
    required this.name,
    required this.plate,
    required this.type,
    required this.sim,
    required this.imei,
    required this.vin,
  });

  final double spacing;
  final double fsMain;
  final double fsSecondary;
  final double fsMeta;
  final String name;
  final String plate;
  final String type;
  final String sim;
  final String imei;
  final String vin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing + 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Container(
                width: 40 * (fsMain / 14),
                height: 40 * (fsMain / 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.directions_car_outlined,
                  size: 18 * (fsMain / 14),
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(width: spacing * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppFonts.roboto(
                        fontSize: fsMain,
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    SizedBox(height: spacing * 0.4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing + 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        plate,
                        style: AppFonts.roboto(
                          fontSize: fsMeta,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    SizedBox(height: spacing * 0.4),
                    Text(
                      type.isEmpty ? '—' : type,
                      style: AppFonts.roboto(
                        fontSize: fsSecondary,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = spacing;
              final cardWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _InfoCard(
                    width: cardWidth,
                    title: 'SIM',
                    icon: Icons.memory,
                    lines: [sim],
                    lineGap: spacing * 0.6,
                    fsMeta: fsMeta - 1,
                    fsMain: fsMain - 1,
                  ),
                  _InfoCard(
                    width: cardWidth,
                    title: 'IMEI',
                    icon: Icons.memory,
                    lines: [imei],
                    fsMeta: fsMeta - 1,
                    fsMain: fsMain - 1,
                  ),
                  _InfoCard(
                    width: cardWidth,
                    title: 'VIN',
                    icon: Icons.confirmation_number_outlined,
                    lines: [vin],
                    fsMeta: fsMeta - 1,
                    fsMain: fsMain - 1,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeviceMetricsCard extends StatelessWidget {
  const _DeviceMetricsCard({
    required this.spacing,
    required this.fsMain,
    required this.fsMeta,
    required this.width,
    required this.status,
    required this.speedVariation,
    required this.distanceVariation,
    required this.odometer,
    required this.engineHours,
  });

  final double spacing;
  final double fsMain;
  final double fsMeta;
  final double width;
  final String status;
  final String speedVariation;
  final String distanceVariation;
  final String odometer;
  final String engineHours;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing + 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Device Metrics',
                style: AppUtils.headlineSmallBase.copyWith(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status.isEmpty ? '—' : status,
                  style: AppFonts.roboto(
                    fontSize: fsMeta,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.6),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = spacing;
              final cardWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _InfoCard(
                    width: cardWidth,
                    title: 'Speed Variation',
                    icon: Icons.speed,
                    lines: [speedVariation],
                    fsMeta: fsMeta,
                    fsMain: fsMain,
                  ),
                  _InfoCard(
                    width: cardWidth,
                    title: 'Distance Variation',
                    icon: Icons.route_outlined,
                    lines: [distanceVariation],
                    fsMeta: fsMeta,
                    fsMain: fsMain,
                  ),
                  _InfoCard(
                    width: cardWidth,
                    title: 'Odometer',
                    icon: Icons.av_timer_outlined,
                    lines: [odometer],
                    fsMeta: fsMeta,
                    fsMain: fsMain,
                  ),
                  _InfoCard(
                    width: cardWidth,
                    title: 'Engine Hours',
                    icon: Icons.timer_outlined,
                    lines: [engineHours],
                    fsMeta: fsMeta,
                    fsMain: fsMain,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlanDetailsCard extends StatelessWidget {
  const _PlanDetailsCard({
    required this.spacing,
    required this.fsMain,
    required this.fsMeta,
    required this.width,
    required this.planName,
    required this.amountText,
  });

  final double spacing;
  final double fsMain;
  final double fsMeta;
  final double width;
  final String planName;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing + 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = spacing;
          final cardWidth = (constraints.maxWidth - gap) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan Details',
                style: AppUtils.headlineSmallBase.copyWith(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: spacing * 0.6),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _InfoCard(
                    width: cardWidth,
                    title: 'Plan Name',
                    icon: Icons.workspace_premium_outlined,
                    lines: [planName],
                    fsMeta: fsMeta,
                    fsMain: fsMain,
                  ),
                  _InfoCard(
                    width: cardWidth,
                    title: 'Amount',
                    icon: Icons.payments_outlined,
                    lines: [amountText],
                    fsMeta: fsMeta,
                    fsMain: fsMain,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.width,
    required this.title,
    required this.icon,
    required this.lines,
    required this.fsMeta,
    required this.fsMain,
    this.lineGap,
  });

  final double width;
  final String title;
  final IconData icon;
  final List<String> lines;
  final double fsMeta;
  final double fsMain;
  final double? lineGap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: fsMain * 0.9, vertical: fsMain * 0.6),
      constraints: const BoxConstraints(minHeight: 90),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: fsMeta - 1,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppFonts.roboto(
                  fontSize: fsMeta,
                  height: 14 / 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: lineGap ?? fsMain * 0.6),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.roboto(
                  fontSize: fsMain,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
