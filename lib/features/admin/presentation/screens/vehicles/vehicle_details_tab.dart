part of 'vehicle_details_screen.dart';

extension _VehicleDetailsTab on _VehicleDetailsScreenState {
  Widget _buildVehicleDetailsTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final scale = (width / 420).clamp(0.9, 1.0);
    final fsMain = 14 * scale;
    final fsSecondary = 12 * scale;
    final fsMeta = 11 * scale;
    final cardPadding = hp + 4;

    final details = _details;
    final name = _safe(details?.nameModel);
    final plate = _safe(details?.plate);
    final type = _safe(details?.vehicleTypeName);
    final imei = _safe(details?.imei);
    final sim = _safe(details?.simNumber);
    final vin = _safe(details?.vin);
    final primaryExpiry = _formatDateOnly(details?.primaryExpiry);
    final secondaryExpiry = _formatDateOnly(details?.secondaryExpiry);
    final speedVariation = _safe(details?.speedVariation);
    final distanceVariation = _safe(details?.distanceVariation);
    final odometer = _safe(details?.deviceOdometer);
    final engineHours = _safe(details?.engineHours);
    final deviceStatus = _safe(details?.deviceStatus);
    final planName = _safe(details?.planName);
    final planPrice = _safe(details?.planPrice);
    final planCurrencyRaw = details?.planCurrency;
    final planCurrencyUpper = _safe(planCurrencyRaw).toUpperCase();
    final planCurrency = planCurrencyUpper == 'INR' ? 'INR' : 'INR';
    final planDuration = _safe(details?.planDuration);
    final amountText = planPrice == '—'
        ? planCurrency
        : planCurrency == '—'
        ? planPrice
        : '$planCurrency $planPrice';

    if (_loading) {
      return _buildVehicleDetailsShimmer(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onSurface.withOpacity(0.08)),
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
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
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
                        Container(
                          width: 40 * (fsMain / 14),
                          height: 40 * (fsMain / 14),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? cs.surfaceContainerHighest
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.onSurface.withOpacity(0.12),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.directions_bus_outlined,
                            size: 18 * (fsMain / 14),
                            color: cs.onSurface.withOpacity(0.7),
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
                                  color: cs.onSurface,
                                ),
                                softWrap: true,
                              ),
                              SizedBox(height: spacing * 0.4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing + 4,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? cs.surfaceContainerHighest
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  plate,
                                  style: AppFonts.roboto(
                                    fontSize: fsMeta,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                  softWrap: true,
                                ),
                              ),
                              SizedBox(height: spacing * 0.4),
                              Text(
                                type.isEmpty ? '—' : type,
                                style: AppFonts.roboto(
                                  fontSize: fsSecondary,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                                softWrap: true,
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
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Device Info',
                              icon: Icons.memory,
                              lines: ['SIM: $sim', 'IMEI: $imei'],
                              lineGap: spacing * 0.6,
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'VIN',
                              icon: Icons.confirmation_number_outlined,
                              lines: [vin],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Primary Expiry',
                              icon: Icons.event_outlined,
                              lines: [primaryExpiry],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Secondary Expiry',
                              icon: Icons.event_outlined,
                              lines: [secondaryExpiry],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing * 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Device Metrics',
                          style: AppUtils.headlineSmallBase.copyWith(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) + 2,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? cs.surfaceContainerHighest
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            deviceStatus.isEmpty ? '—' : deviceStatus,
                            style: AppFonts.roboto(
                              fontSize: fsMeta,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
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
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Speed Variation',
                              icon: Icons.speed,
                              lines: [speedVariation],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Distance Variation',
                              icon: Icons.route_outlined,
                              lines: [distanceVariation],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Odometer',
                              icon: Icons.av_timer_outlined,
                              lines: [odometer],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
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
              ),
              SizedBox(height: spacing * 2),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing + 2),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
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
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) + 2,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        SizedBox(height: spacing * 0.6),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Plan Name',
                              icon: Icons.workspace_premium_outlined,
                              lines: [planName],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Amount',
                              icon: Icons.payments_outlined,
                              lines: [amountText],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                            _infoCard(
                              context,
                              width: cardWidth,
                              title: 'Duration (Days)',
                              icon: Icons.calendar_month_outlined,
                              lines: [planDuration],
                              fsMeta: fsMeta,
                              fsMain: fsMain,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
