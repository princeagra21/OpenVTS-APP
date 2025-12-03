import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsTab extends StatelessWidget {
  const VehicleDetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsContainer(colorScheme),
        const SizedBox(height: 24),

        _buildIdentifiersContainer(context, colorScheme),
        const SizedBox(height: 24),

        _buildMetaContainer(colorScheme),
        const SizedBox(height: 24),

        _buildSignalFixSection(colorScheme),
        const SizedBox(height: 24),

        _buildPowerBatterySection(colorScheme),
        const SizedBox(height: 24),

        _buildSubscriptionSection(colorScheme),
        const SizedBox(height: 24),
        _buildPeopleSection(colorScheme),
SizedBox(height: 24),

_buildRecentEventsContainer(colorScheme),

const SizedBox(height: 24),
DeleteVehicleBox(
  onDelete: () {
    // Add your delete vehicle logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vehicle deleted")),
    );
  },
),

      ],
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================
  Widget _buildSectionHeader(IconData icon, String title, ColorScheme scheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VEHICLE STATS
  // ============================================================
  Widget _buildStatsContainer(ColorScheme scheme) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.speed, "VEHICLE STATS", scheme),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("SPEED", "62 km/h"),
              _buildStatItem("IGNITION", "ON"),
              _buildStatItem("ENGINE HOURS", "1820.5 h"),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem("ODOMETER", "148,520.7 km", fullWidth: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ============================================================
  // IDENTIFIERS
  // ============================================================
  Widget _buildIdentifiersContainer(
      BuildContext context, ColorScheme scheme) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.badge, "IDENTIFIERS", scheme),
          const SizedBox(height: 16),
          _identifier(context, "VIN", "MA1TA2C43J5K78901"),
          const SizedBox(height: 12),
          _identifier(context, "IMEI", "358920108765431"),
          const SizedBox(height: 12),
          _identifier(context, "Timezone", "+05:30", showCopy: false),
        ],
      ),
    );
  }

  Widget _identifier(BuildContext ctx, String label, String value,
      {bool showCopy = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text("$label copied"),
                      duration: const Duration(seconds: 1)),
                );
              },
            )
        ],
      ),
    );
  }

  // ============================================================
  // META
  // ============================================================
  Widget _buildMetaContainer(ColorScheme scheme) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.list_alt, "VEHICLE META", scheme),
          const SizedBox(height: 16),
          _metaRow("Fuel Type", "Diesel", "Axle Count", "2 Axles"),
          const SizedBox(height: 12),
          _metaRow("GPS Module", "vv2.1", "Custom Color", "Matte Black"),
        ],
      ),
    );
  }

  Widget _metaRow(
      String l1, String v1, String l2, String v2) {
    return Row(
      children: [
        Expanded(child: _metaItem(l1, v1)),
        const SizedBox(width: 12),
        Expanded(child: _metaItem(l2, v2)),
      ],
    );
  }

  Widget _metaItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ============================================================
  // SIGNAL & FIX
  // ============================================================
  Widget _buildSignalFixSection(ColorScheme scheme) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.gps_fixed, "SIGNAL & FIX", scheme),
          const SizedBox(height: 16),
          _statRow("Satellites", "9"),
          const SizedBox(height: 8),
          _statRow("HDOP", "0.8"),
          const SizedBox(height: 8),
          _statRow("Fix", "3D"),
          const SizedBox(height: 16),

          // Indicator
          _hdopIndicator(0.8),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600])),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _hdopIndicator(double hdop) {
    double percent = (2 - hdop) / 2;
    percent = percent.clamp(0, 1);

    return LinearProgressIndicator(
      value: percent,
      minHeight: 8,
      backgroundColor: Colors.grey[300],
      color: Colors.black.withOpacity(0.7),
    );
  }

  // ============================================================
  // POWER & BATTERY
  // ============================================================
  Widget _buildPowerBatterySection(ColorScheme scheme) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.battery_6_bar, "POWER & BATTERY", scheme),
          const SizedBox(height: 16),

          _statRow("Battery (V)", "12.6"),
          const SizedBox(height: 8),

          _statRow("External (V)", "13.8"),
          const SizedBox(height: 16),

          _powerIndicator(12.6),
        ],
      ),
    );
  }

  Widget _powerIndicator(double voltage) {
    double percent = (voltage - 10) / 4; // maps 10–14V to 0–100%
    percent = percent.clamp(0, 1);

    return LinearProgressIndicator(
      value: percent,
      minHeight: 8,
      backgroundColor: Colors.grey[300],
      color: Colors.black.withOpacity(0.7),
    );
  }

  // ============================================================
  // SUBSCRIPTION
  // ============================================================
  Widget _buildSubscriptionSection(ColorScheme scheme) {
    return _card(
      scheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.calendar_month, "SUBSCRIPTION", scheme),
          const SizedBox(height: 16),

          _subRow("Primary", "2026-08-31", "271 days remaining"),
          const SizedBox(height: 12),

          _subRow("Secondary", "2026-12-31", "393 days remaining"),
          const SizedBox(height: 16),

          _subscriptionIndicator(271),
        ],
      ),
    );
  }

  Widget _subRow(String label, String date, String daysLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w500)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(daysLeft,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey[600])),
            ],
          )
        ],
      ),
    );
  }

  Widget _subscriptionIndicator(int daysLeft) {
    double percent = (daysLeft / 365).clamp(0, 1);

    return LinearProgressIndicator(
      value: percent,
      minHeight: 8,
      backgroundColor: Colors.grey[300],
      color: Colors.black.withOpacity(0.7),
    );
  }

  // ============================================================
  // CARD WRAPPER
  // ============================================================
  Widget _card(ColorScheme scheme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: child,
    );
  }

  Widget _buildPeopleSection(ColorScheme colorScheme) {
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
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.people, color: Colors.black.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              "PEOPLE",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Primary User
        _buildPersonBlock(
          title: "Primary User",
          name: "Akash Kumar",
          email: "akash.kumar@example.com",
          phone: "+91 9810012345",
          username: "@akash.k",
        ),

        const SizedBox(height: 20),

        // Added By
        _buildPersonBlock(
          title: "Added By",
          name: "Vinod Singh",
          email: "vinod.singh@example.com",
          phone: "+91 9899011122",
          username: "@vinod.s",
        ),
      ],
    ),
  );
}

Widget _buildPersonBlock({
  required String title,
  required String name,
  required String email,
  required String phone,
  required String username,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),

        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          email,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "$phone • $username",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    ),
  );
}


Widget _buildRecentEventsContainer(ColorScheme colorScheme) {
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
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.history, size: 18, color: Colors.black.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(
              "RECENT EVENTS",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildEventItem("Location ping", "47d ago"),
        const Divider(height: 20),

        _buildEventItem("Ignition ON", "~"),
        const Divider(height: 20),

        _buildEventItem("Speed updated", ""),
      ],
    ),
  );
}


Widget _buildEventItem(String title, String time) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Title
      Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Time
      Text(
        time,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}

}





class DeleteVehicleBox extends StatelessWidget {
  const DeleteVehicleBox({super.key, required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final Color redColor = Colors.red;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: redColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Danger Zone",
            style: GoogleFonts.inter(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: redColor,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "This action cannot be undone. It will permanently delete this vehicle and remove all associated data.",
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: redColor,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: redColor, width: 2),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 2,
                    vertical: padding,
                  ),
                ),
                child: Text(
                  "Delete Vehicle",
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: redColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
