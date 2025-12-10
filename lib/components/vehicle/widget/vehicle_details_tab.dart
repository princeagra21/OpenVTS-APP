// components/vehicle/vehicle_details_tab.dart
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleDetailsTab extends StatelessWidget {
  const VehicleDetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsContainer(context, colorScheme, width),
        const SizedBox(height: 20),
        _buildIdentifiersContainer(context, colorScheme, width),
        const SizedBox(height: 20),
        _buildMetaContainer(colorScheme, width),
        const SizedBox(height: 20),
        _buildSignalFixSection(colorScheme, width),
        const SizedBox(height: 20),
        _buildPowerBatterySection(colorScheme, width),
        const SizedBox(height: 20),
        _buildSubscriptionSection(colorScheme, width),
        const SizedBox(height: 20),
        _buildPeopleSection(colorScheme, width),
        const SizedBox(height: 20),
        _buildRecentEventsContainer(colorScheme, width),
        const SizedBox(height: 24),
        DeleteVehicleBox(onDelete: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehicle deleted")),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  // SECTION HEADER (smaller)
  Widget _buildSectionHeader(IconData icon, String title, ColorScheme scheme, double width) {
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getTitleFontSize(width) - 3,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _card(ColorScheme scheme, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  // VEHICLE STATS
    Widget _buildStatsContainer(BuildContext context, ColorScheme scheme, double width) {
      return _card(scheme, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.speed, "VEHICLE STATS", scheme, width),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("SPEED", "62 km/h", width, context),
              _buildStatItem("IGNITION", "ON", width, context),
              _buildStatItem("ENGINE HOURS", "1820.5 h", width, context),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatItem("ODOMETER", "148,520.7 km", width, context, fullWidth: true),
        ],
      ));
    }

  Widget _buildStatItem(String label, String value, double width, BuildContext context, {bool fullWidth = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4, color: colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        ],
      ),
    );
  }

  // IDENTIFIERS
  Widget _buildIdentifiersContainer(BuildContext context, ColorScheme scheme, double width) {
    return _card(scheme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.badge, "IDENTIFIERS", scheme, width),
        const SizedBox(height: 12),
        _identifier(context, "VIN", "MA1TA2C43J5K78901", width),
        const SizedBox(height: 8),
        _identifier(context, "IMEI", "358920108765431", width),
        const SizedBox(height: 8),
        _identifier(context, "Timezone", "+05:30", width, showCopy: false),
      ],
    ));
  }

  Widget _identifier(BuildContext ctx, String label, String value, double width, {bool showCopy = true}) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4, color: colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: Icon(Icons.copy, size: 16, color: colorScheme.primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("$label copied")));
              },
            ),
        ],
      ),
    );
  }

  // META
  Widget _buildMetaContainer(ColorScheme scheme, double width) {
    return _card(scheme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.list_alt, "VEHICLE META", scheme, width),
        const SizedBox(height: 12),
        _metaRow("Fuel Type", "Diesel", "Axle Count", "2 Axles", width, scheme),
        const SizedBox(height: 8),
        _metaRow("GPS Module", "vv2.1", "Custom Color", "Matte Black", width, scheme),
      ],
    ));
  }

  Widget _metaRow(String l1, String v1, String l2, String v2, double width, ColorScheme scheme) {
    return Row(children: [
      Expanded(child: _metaItem(l1, v1, width, scheme)),
      const SizedBox(width: 12),
      Expanded(child: _metaItem(l2, v2, width, scheme)),
    ]);
  }

  Widget _metaItem(String label, String value, double width, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: scheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4, color: scheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4, fontWeight: FontWeight.bold, color: scheme.onSurface)),
        ],
      ),
    );
  }

  // SIGNAL & FIX
  Widget _buildSignalFixSection(ColorScheme scheme, double width) {
    return _card(scheme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.gps_fixed, "SIGNAL & FIX", scheme, width),
        const SizedBox(height: 12),
        _statRow("Satellites", "9", width, scheme),
        const SizedBox(height: 6),
        _statRow("HDOP", "0.8", width, scheme),
        const SizedBox(height: 6),
        _statRow("Fix", "3D", width, scheme),
        const SizedBox(height: 12),
        _hdopIndicator(0.8, scheme),
      ],
    ));
  }

  Widget _statRow(String label, String value, double width, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4, color: scheme.onSurface.withOpacity(0.6))),
        Text(value, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4, fontWeight: FontWeight.bold, color: scheme.onSurface)),
      ],
    );
  }

  Widget _hdopIndicator(double hdop, ColorScheme scheme) {
    double percent = (2 - hdop) / 2;
    percent = percent.clamp(0, 1);
    return LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: scheme.surfaceVariant, color: scheme.primary);
  }

  // POWER & BATTERY
  Widget _buildPowerBatterySection(ColorScheme scheme, double width) {
    return _card(scheme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.battery_6_bar, "POWER & BATTERY", scheme, width),
        const SizedBox(height: 12),
        _statRow("Battery (V)", "12.6", width, scheme),
        const SizedBox(height: 6),
        _statRow("External (V)", "13.8", width, scheme),
        const SizedBox(height: 12),
        _powerIndicator(12.6, scheme),
      ],
    ));
  }

  Widget _powerIndicator(double voltage, ColorScheme scheme) {
    double percent = (voltage - 10) / 4;
    percent = percent.clamp(0, 1);
    return LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: scheme.surfaceVariant, color: scheme.primary);
  }

  // SUBSCRIPTION
  Widget _buildSubscriptionSection(ColorScheme scheme, double width) {
    return _card(scheme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.calendar_month, "SUBSCRIPTION", scheme, width),
        const SizedBox(height: 12),
        _subRow("Primary", "2026-08-31", "271 days remaining", width, scheme),
        const SizedBox(height: 8),
        _subRow("Secondary", "2026-12-31", "393 days remaining", width, scheme),
        const SizedBox(height: 12),
        _subscriptionIndicator(271, scheme),
      ],
    ));
  }

  Widget _subRow(String label, String date, String daysLeft, double width, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(color: scheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5, fontWeight: FontWeight.w600)),
              Text(daysLeft, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 5, color: scheme.onSurface.withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subscriptionIndicator(int daysLeft, ColorScheme scheme) {
    double percent = (daysLeft / 365).clamp(0, 1);
    return LinearProgressIndicator(value: percent, minHeight: 6, backgroundColor: scheme.surfaceVariant, color: scheme.primary);
  }

  // PEOPLE
  Widget _buildPeopleSection(ColorScheme scheme, double width) {
    return _card(scheme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.people, "PEOPLE", scheme, width),
        const SizedBox(height: 12),
        _buildPersonBlock("Primary User", "Akash Kumar", "akash.kumar@example.com", "+91 9810012345", "@akash.k", width, scheme),
        const SizedBox(height: 16),
        _buildPersonBlock("Added By", "Vinod Singh", "vinod.singh@example.com", "+91 9899011122", "@vinod.s", width, scheme),
      ],
    ));
  }

  Widget _buildPersonBlock(String title, String name, String email, String phone, String username, double width, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(color: scheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4, color: scheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 6),
          Text(name, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(email, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 3, color: scheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 2),
          Text("$phone • $username", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 3, color: scheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }

  // RECENT EVENTS
  Widget _buildRecentEventsContainer(ColorScheme scheme, double width) {
    return _card(scheme, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.history, "RECENT EVENTS", scheme, width),
        const SizedBox(height: 12),
        _buildEventItem("Location ping", "47d ago", width, scheme),
        const Divider(height: 16),
        _buildEventItem("Ignition ON", "~", width, scheme),
        const Divider(height: 16),
        _buildEventItem("Speed updated", "", width, scheme),
      ],
    ));
  }

  Widget _buildEventItem(String title, String time, double width, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 4, color: scheme.onSurface)),
        Text(time, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) - 4, color: scheme.onSurface.withOpacity(0.6))),
      ],
    );
  }
}

class DeleteVehicleBox extends StatelessWidget {
  const DeleteVehicleBox({super.key, required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width);
    final double fontSize = AdaptiveUtils.getTitleFontSize(width);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: colorScheme.error, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Danger Zone", style: GoogleFonts.inter(fontSize: fontSize + 1, fontWeight: FontWeight.bold, color: colorScheme.error)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "This action cannot be undone. It will permanently delete this vehicle and remove all associated data.",
                  style: GoogleFonts.inter(fontSize: fontSize - 2, color: colorScheme.error),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: padding * 1.8, vertical: padding * 0.8),
                ),
                child: Text("Delete Vehicle", style: GoogleFonts.inter(fontSize: fontSize - 2, color: colorScheme.error, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}