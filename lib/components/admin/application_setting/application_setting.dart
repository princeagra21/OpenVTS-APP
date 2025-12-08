import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
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
            ApplicationHeader(),
            const SizedBox(height: 24),
            // You can add more boxes here if needed
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
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    String demoStatus = demoEnabled ? "ON" : "OFF";
    String signupStatus = signupAllowed ? "ALLOWED" : "DISABLED";

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -----------------------------------------
              // BUTTONS (RESET AND SAVE)
              // -----------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Reset to defaults
                      setState(() {
                        demoEnabled = false;
                        geocodingPrecision = "2 Digits";
                        backupRetention = "3 Months";
                        freeCredits = 100;
                        signupAllowed = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: hp + 2,
                        vertical: hp - 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      Icons.refresh_outlined,
                      color: Colors.white,
                      size: AdaptiveUtils.getIconSize(width),
                    ),
                    label: Text(
                      "Reset",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: hp + 2,
                        vertical: hp - 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      Icons.save_outlined,
                      color: Colors.white,
                      size: AdaptiveUtils.getIconSize(width),
                    ),
                    label: Text(
                      "Save",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // -----------------------------------------
              // LEFT TEXTS
              // -----------------------------------------
              Text(
                "Application Settings",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Configure system-wide settings for your application.",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  fontWeight: FontWeight.w200,
                  color: Colors.black.withOpacity(0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================== Current Configuration ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Configuration",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Demo: $demoStatus • Geocoding: $geocodingPrecision • Signup: $signupStatus",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Demo Login ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: AdaptiveUtils.getTitleFontSize(width) + 5,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Demo Login",
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: demoEnabled,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.black,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.black.withOpacity(0.3),
                        onChanged: (v) => setState(() => demoEnabled = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  demoEnabled ? "Demo login is enabled" : "Demo login is disabled",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Reverse Geocoding ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: AdaptiveUtils.getTitleFontSize(width) + 5,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Reverse Geocoding",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("2 Digits\nCity/Region"),
                      selected: geocodingPrecision == "2 Digits",
                      onSelected: (bool selected) {
                        setState(() => geocodingPrecision = "2 Digits");
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: Text("3 Digits\nStreet Level"),
                      selected: geocodingPrecision == "3 Digits",
                      onSelected: (bool selected) {
                        setState(() => geocodingPrecision = "3 Digits");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Database Backup ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.backup_rounded,
                      size: AdaptiveUtils.getTitleFontSize(width) + 5,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Database Backup",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: backupRetention,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    underline: const SizedBox(),
                    style: GoogleFonts.inter(color: Colors.black, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => backupRetention = newValue);
                      }
                    },
                    items: <String>["1 Month", "3 Months", "6 Months", "12 Months"].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Backups will be retained for the selected period",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Signup Configuration ====================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_add_rounded,
                      size: AdaptiveUtils.getTitleFontSize(width) + 5,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Signup Configuration",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Allow New Signups",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: signupAllowed,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.black,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.black.withOpacity(0.3),
                        onChanged: (v) => setState(() => signupAllowed = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  signupAllowed ? "New users can register" : "New user registration is disabled",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Free Signup Credits",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                  ),
                  controller: TextEditingController(text: freeCredits.toString()),
                  onChanged: (value) {
                    setState(() => freeCredits = int.tryParse(value) ?? freeCredits);
                  },
                  decoration: _inputDecoration(hint: "Number of free credits awarded to new users upon signup"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: Colors.black.withOpacity(0.6),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
    );
  }
}