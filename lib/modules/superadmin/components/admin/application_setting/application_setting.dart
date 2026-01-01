// screens/settings/application_settings_screen.dart
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplicationSettingsScreen extends StatelessWidget {
  const ApplicationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Settings",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ApplicationHeader(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class ApplicationHeader extends StatefulWidget {
  const ApplicationHeader({super.key});

  @override
  State<ApplicationHeader> createState() => _ApplicationHeaderState();
}

class _ApplicationHeaderState extends State<ApplicationHeader> {
  bool demoEnabled = false;
  String geocodingPrecision = "2 Digits";
  String backupRetention = "3 Months";
  int freeCredits = 100;
  bool signupAllowed = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    String demoStatus = demoEnabled ? "ON" : "OFF";
    String signupStatus = signupAllowed ? "ALLOWED" : "DISABLED";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP BUTTONS (Reset & Save)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  demoEnabled = false;
                  geocodingPrecision = "2 Digits";
                  backupRetention = "3 Months";
                  freeCredits = 100;
                  signupAllowed = true;
                }),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: Icon(Icons.refresh_outlined, color: colorScheme.onPrimary),
                label: Text("Reset", style: GoogleFonts.inter(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: Icon(Icons.save_outlined, color: colorScheme.onPrimary),
                label: Text("Save", style: GoogleFonts.inter(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // TITLE
          Text(
            "Application Settings",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure system-wide settings for your application.",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width),
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 24),

          // CURRENT CONFIGURATION
          _buildSection(
            context: context,
            icon: Icons.settings_rounded,
            title: "Current Configuration",
            child: Text(
              "Demo: $demoStatus • Geocoding: $geocodingPrecision • Signup: $signupStatus",
              style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3, color: colorScheme.onSurface.withOpacity(0.87)),
            ),
          ),

          const SizedBox(height: 24),

          // DEMO LOGIN
          _buildToggleSection(
            context: context,
            icon: Icons.login_rounded,
            title: "Demo Login",
            subtitle: demoEnabled ? "Demo login is enabled" : "Demo login is disabled",
            value: demoEnabled,
            onChanged: (v) => setState(() => demoEnabled = v),
          ),

          const SizedBox(height: 24),

          // REVERSE GEOCODING
          _buildSection(
            context: context,
            icon: Icons.location_on_rounded,
            title: "Reverse Geocoding",
            child: Row(
              children: [
                ChoiceChip(
                  label: Text("2 Digits\nCity/Region"),
                  selected: geocodingPrecision == "2 Digits",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: geocodingPrecision == "2 Digits" ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                  onSelected: (_) => setState(() => geocodingPrecision = "2 Digits"),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text("3 Digits\nStreet Level"),
                  selected: geocodingPrecision == "3 Digits",
                  selectedColor: colorScheme.primary,
                  labelStyle: GoogleFonts.inter(
                    color: geocodingPrecision == "3 Digits" ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                  onSelected: (_) => setState(() => geocodingPrecision = "3 Digits"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DATABASE BACKUP
          _buildSection(
            context: context,
            icon: Icons.backup_rounded,
            title: "Database Backup",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: backupRetention,
                  decoration: _dropdownDecoration(context),
                  items: ["1 Month", "3 Months", "6 Months", "12 Months"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => v != null ? setState(() => backupRetention = v) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  "Backups will be retained for the selected period",
                  style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.8)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // SIGNUP CONFIGURATION
          _buildSection(
            context: context,
            icon: Icons.person_add_rounded,
            title: "Signup Configuration",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Allow New Signups",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.87)),
                    ),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: signupAllowed,
                        activeColor: colorScheme.onPrimary,
                        activeTrackColor: colorScheme.primary,
                        inactiveThumbColor: colorScheme.onPrimary,
                        inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                        onChanged: (v) => setState(() => signupAllowed = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  signupAllowed ? "New users can register" : "New user registration is disabled",
                  style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.8)),
                ),
                const SizedBox(height: 24),
                Text("Free Signup Credits", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87))),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: freeCredits.toString())
                    ..selection = TextSelection.fromPosition(TextPosition(offset: freeCredits.toString().length)),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => freeCredits = int.tryParse(v) ?? freeCredits),
                  style: GoogleFonts.inter(color: colorScheme.onSurface),
                  decoration: _inputDecoration(context, hint: "Number of free credits awarded to new users upon signup"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AdaptiveUtils.getTitleFontSize(width) + 5, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) + 2, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.87)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(subtitle, style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.8))),
          ],
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildToggleSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AdaptiveUtils.getTitleFontSize(width) + 5, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) + 2, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.87)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(subtitle, style: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.8)))),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: value,
                  activeColor: colorScheme.onPrimary,
                  activeTrackColor: colorScheme.primary,
                  inactiveThumbColor: colorScheme.onPrimary,
                  inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: colorScheme.onSurface.withOpacity(0.6)),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
    );
  }
}