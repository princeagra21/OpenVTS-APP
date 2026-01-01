// components/admin/vehicles_tab/vehicles_tab.dart
import 'package:fleet_stack/modules/superadmin/components/admin/vehicles_tab/vehicle_card.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehiclesTab extends StatelessWidget {
  VehiclesTab({super.key});

  final List<Map<String, dynamic>> vehiclesData = [
    {
      "name": "Atlas T-900",
      "type": "Truck",
      "isActive": false,
      "imei": "862045317896420",
      "vin": "MAT448123C5200456",
      "model": "GT06",
      "lastSeenDate": "2025-10-16",
      "lastSeenTime": "06:41",
      "timezone": "+5:30",
      "primaryExpiry": "2026-04-30",
      "secondaryExpiry": "2027-04-30",
    },
    {
      "name": "CargoJet V8",
      "type": "Truck",
      "isActive": false,
      "imei": "865431200987654",
      "vin": "MBHZZZ8P7GT201245",
      "model": "GT06",
      "lastSeenDate": "2025-10-16",
      "lastSeenTime": "13:40",
      "timezone": "+5:30",
      "primaryExpiry": "2026-03-31",
      "secondaryExpiry": "2027-03-31",
    },
    {
      "name": "CargoMax K2",
      "type": "Truck",
      "isActive": false,
      "imei": "355488120563742",
      "vin": "MBHZZZ8P7GT200112",
      "model": "GT06",
      "lastSeenDate": "2025-10-16",
      "lastSeenTime": "07:52",
      "timezone": "+5:30",
      "primaryExpiry": "2026-11-30",
      "secondaryExpiry": "2027-11-30",
    },
    // ... more vehicles
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildOverviewCard(context, colorScheme),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: vehiclesData.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: VehicleCard(
                name: v["name"],
                type: v["type"],
                isActive: v["isActive"],
                imei: v["imei"],
                vin: v["vin"],
                model: v["model"],
                lastSeenDate: v["lastSeenDate"],
                lastSeenTime: v["lastSeenTime"],
                timezone: v["timezone"],
                primaryExpiry: v["primaryExpiry"],
                secondaryExpiry: v["secondaryExpiry"],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, ColorScheme colorScheme) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double valueFontSize = titleFontSize * 2;
    final double subtitleFontSize = titleFontSize - 2;
    final double changeFontSize = subtitleFontSize - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Vehicles",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                "1,200",
                style: GoogleFonts.inter(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "currently tracked",
            style: GoogleFonts.inter(
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 20),
          // STATUS ROWS
          _buildStatusRow(
            label: "Moving",
            value: "432",
            change: "▲ 3.8%",
            color: Colors.green,
            labelFontSize: titleFontSize,
            valueFontSize: valueFontSize - 12,
            changeFontSize: changeFontSize,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            label: "Idle",
            value: "215",
            change: "▼ 1.2%",
            color: Colors.orange,
            labelFontSize: titleFontSize,
            valueFontSize: valueFontSize - 12,
            changeFontSize: changeFontSize,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            label: "Stopped",
            value: "190",
            change: "▼ 0.6%",
            color: Colors.red,
            labelFontSize: titleFontSize,
            valueFontSize: valueFontSize - 12,
            changeFontSize: changeFontSize,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required String change,
    required Color color,
    required double labelFontSize,
    required double valueFontSize,
    required double changeFontSize,
    required ColorScheme colorScheme,
  }) {
    final isNegative = change.contains('▼');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isNegative ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              change,
              style: GoogleFonts.inter(
                fontSize: changeFontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}