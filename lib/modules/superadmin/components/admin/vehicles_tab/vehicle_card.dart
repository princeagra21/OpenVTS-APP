// components/admin/vehicles_tab/vehicle_card.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleCard extends StatelessWidget {
  final String name;
  final String type;
  final bool isActive;
  final String plate;
  final String imei;
  final String vin;
  final String simNumber;
  final String model;
  final String lastSeenDate;
  final String lastSeenTime;
  final String timezone;
  final String primaryExpiry;
  final String secondaryExpiry;

  const VehicleCard({
    super.key,
    required this.name,
    required this.type,
    required this.isActive,
    required this.plate,
    required this.imei,
    required this.vin,
    required this.simNumber,
    required this.model,
    required this.lastSeenDate,
    required this.lastSeenTime,
    required this.timezone,
    required this.primaryExpiry,
    required this.secondaryExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subtitleFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 2;
    final double labelFontSize = subtitleFontSize - 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isActive ? colorScheme.primary : colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActive ? "Active" : "Inactive",
                    style: GoogleFonts.inter(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: isActive ? colorScheme.primary : colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle Information Section
          Row(
            children: [
              Icon(
                Icons.directions_car_filled,
                size: 16,
                color: colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                "Vehicle Information",
                style: GoogleFonts.inter(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow("Plate Number", plate, labelFontSize, colorScheme),
          _infoRow("SIM Number", simNumber, labelFontSize, colorScheme),
          _infoRow("Type", type, labelFontSize, colorScheme),
          _infoRow("IMEI", imei, labelFontSize, colorScheme),
          _infoRow("VIN / Chassis No.", vin, labelFontSize, colorScheme),
          _infoRow("Device Model", model, labelFontSize, colorScheme),
          const SizedBox(height: 12),

          // Activity Section
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                "Activity",
                style: GoogleFonts.inter(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow("Last Seen", lastSeenDate, labelFontSize, colorScheme),
          _infoRow(
            "Time",
            "$lastSeenTime ($timezone)",
            labelFontSize,
            colorScheme,
          ),
          const SizedBox(height: 12),

          // Licence Section
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 16,
                color: colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                "Licence Status",
                style: GoogleFonts.inter(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow("Primary", primaryExpiry, labelFontSize, colorScheme),
          _infoRow("Secondary", secondaryExpiry, labelFontSize, colorScheme),
        ],
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
    double fontSize,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
