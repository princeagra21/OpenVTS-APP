import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(w);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(w);
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final largeFs = titleFs + 2;
    final labelFs = titleFs - 2;

    
    // SAMPLE DATA (replace with API)
    final Map<String, dynamic> vehicle = {
      "model": "Ashok Leyland 4000XL #17",
      "imei": "851592881761640",
      "vin": "NNKSPXM81C77Z088X",
      "motion": "RUNNING",
      "duration": "2h 47m",
      "speed": "83 km/h",
      "userInitials": "KI",
      "userName": "Kabir Iyer",
      "lastUpdate": "23 Dec 02:05 PM",
      "fuel": "64%",
      "odometer": "14,157 km",
      "sim": "Airtel - +91-98XXXXXX",
      "device": "Ruijie R300",
      "geofence": ["Warehouse A", "Delhi Yard"],
      "ignition": true,
      "gps": true,
      "lock": false,
      "active": "No",
      "expiry": "18 Nov 2026",
    };

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Vehicle Details",
                    style: GoogleFonts.inter(
                      fontSize: titleFs,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              SizedBox(height: spacing * 1.5),

              /// VEHICLE NAME
              Center(
                child: Column(
                  children: [
                    Text(
                      vehicle["model"],
                      style: GoogleFonts.inter(
                        fontSize: largeFs,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing / 2),
                    Text(
                      "IMEI: ${vehicle["imei"]} · VIN: ${vehicle["vin"]}",
                      style: GoogleFonts.inter(
                        fontSize: labelFs,
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: spacing * 2),

              /// STATUS GRID (2 x 2)
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                children: [
                  _infoBox(
                    context,
                    title: "Status",
                    value: vehicle["motion"],
                    subtitle: "[${vehicle["duration"]}]",
                    icon: CupertinoIcons.arrow_right,
                    color: Colors.green,
                  ),
                  _infoBox(
                    context,
                    title: "Speed",
                    value: vehicle["speed"],
                    icon: CupertinoIcons.speedometer,
                  ),
                  _infoBox(
                    context,
                    title: "Primary User",
                    value: "${vehicle["userInitials"]} ${vehicle["userName"]}",
                    icon: CupertinoIcons.person_fill,
                  ),
                  _infoBox(
                    context,
                    title: "Last Update",
                    value: vehicle["lastUpdate"],
                    icon: CupertinoIcons.time,
                  ),
                ],
              ),

              SizedBox(height: spacing * 2),

              /// DEVICE & SIM
              _sectionContainer(
                context,
                title: "Device & SIM",
                children: [
                  _row("Fuel Level", vehicle["fuel"]),
                  _row("Odometer", vehicle["odometer"]),
                  _row("SIM", vehicle["sim"]),
                  _row("Device Model", vehicle["device"]),
                  _row(
                    "Geo Fences",
                    (vehicle["geofence"] as List<dynamic>).join(", "),
                  ),
                ],
              ),

              SizedBox(height: spacing * 2),

              /// SECURITY
              _sectionContainer(
                context,
                title: "Security",
                children: [
                  _securityRow("Ignition", vehicle["ignition"]),
                  _securityRow("GPS", vehicle["gps"]),
                  _securityRow("Lock", vehicle["lock"]),
                ],
              ),

              SizedBox(height: spacing * 2),

              /// ACTIVE + EXPIRY
              _sectionContainer(
                context,
                title: "Subscription",
                children: [
                  _row("Active", vehicle["active"]),
                  _row("Expiry", vehicle["expiry"]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ───────────────── INFO BOX ─────────────────
  Widget _infoBox(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleFs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    final labelFs = titleFs - 2;
    final smallFs = titleFs - 4;
    final mediumPadding = AdaptiveUtils.getHorizontalPadding(MediaQuery.of(context).size.width) * 0.8;
    final iconSize = titleFs + 6;

    return Container(
      padding: EdgeInsets.all(mediumPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? cs.primary, size: iconSize),
          const SizedBox(height: 10,),
          Text(title,
              style: GoogleFonts.inter(
                fontSize: smallFs + 2,
                color: cs.onSurface.withOpacity(0.6),
              )),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: labelFs + 4,
              fontWeight: FontWeight.bold,
              color: color ?? cs.onSurface,
            ),
          ),

          SizedBox(height: 5,),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: smallFs + 2,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }

  /// ───────────────── SECTION CONTAINER ─────────────────
  Widget _sectionContainer(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleFs = AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width);
    final labelFs = titleFs - 2;
    final smallPadding = AdaptiveUtils.getHorizontalPadding(MediaQuery.of(context).size.width) * 0.5;
    final largePadding = AdaptiveUtils.getHorizontalPadding(MediaQuery.of(context).size.width);

    return Container(
      padding: EdgeInsets.all(largePadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
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
          Text(title,
              style: GoogleFonts.inter(
                fontSize: labelFs,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(height: smallPadding * 2),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    final w = MediaQueryData.fromView(WidgetsBinding.instance.window).size.width;
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final smallFs = titleFs - 4;
    final smallPadding = AdaptiveUtils.getHorizontalPadding(w) * 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize: smallFs,
                color: Colors.grey.shade600,
              )),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: smallFs,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _securityRow(String label, bool enabled) {
    final w = MediaQueryData.fromView(WidgetsBinding.instance.window).size.width;
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final labelFs = titleFs - 2;
    final smallPadding = AdaptiveUtils.getHorizontalPadding(w) * 0.5;
    final iconSize = titleFs + 6;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: smallPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize: labelFs,
              )),
          Icon(
            enabled ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
            color: enabled ? Colors.green : Colors.red,
            size: iconSize,
          ),
        ],
      ),
    );
  }
}