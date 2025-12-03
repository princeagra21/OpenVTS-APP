import 'package:fleet_stack/components/admin/vehicles_tab/vehicle_card.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
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
    // Continue adding all other vehicles...
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        _buildOverviewCard(context),
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.all(4),
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

  Widget _buildOverviewCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withOpacity(0.7),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                "1,200",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "currently tracked",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          // STATUS ROWS
          _buildStatusRow("Moving", "432", "▲ 3.8%", Colors.green),
          const SizedBox(height: 16),
          _buildStatusRow("Idle", "215", "▼ 1.2%", Colors.orange),
          const SizedBox(height: 16),
          _buildStatusRow("Stopped", "190", "▼ 0.6%", Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    String change,
    Color color,
  ) {
    final isNegative = change.contains("▼");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
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
                fontSize: 13,
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