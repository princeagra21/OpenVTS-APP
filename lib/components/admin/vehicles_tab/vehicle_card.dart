import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleCard extends StatelessWidget {
  final String name;
  final String type;
  final bool isActive;
  final String imei;
  final String vin;
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
    required this.imei,
    required this.vin,
    required this.model,
    required this.lastSeenDate,
    required this.lastSeenTime,
    required this.timezone,
    required this.primaryExpiry,
    required this.secondaryExpiry,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.7),
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
                      color: isActive ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActive ? "Active" : "Inactive",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.red,
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
              Icon(Icons.directions_car_filled, size: 16, color: Colors.black.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                "Vehicle Information",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow("Type", type),
          _infoRow("IMEI", imei),
          _infoRow("VIN / Chassis No.", vin),
          _infoRow("Device Model", model),
          const SizedBox(height: 12),
          // Activity Section
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: Colors.black.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                "Activity",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow("Last Seen", lastSeenDate),
          _infoRow("Time", "$lastSeenTime ($timezone)"),
          const SizedBox(height: 12),
          // Licence Section
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 16, color: Colors.black.withOpacity(0.6)),
              const SizedBox(width: 8),
              Text(
                "Licence Status",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow("Primary", primaryExpiry),
          _infoRow("Secondary", secondaryExpiry),
        ],
      ),
    );
  }
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}