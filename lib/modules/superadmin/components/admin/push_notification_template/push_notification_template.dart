import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class PushNotificationTemplateSettingsScreen extends StatelessWidget {
  const PushNotificationTemplateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Notification",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PushNotificationTemplateHeader(),
            const SizedBox(height: 24),
            // You can add more boxes here if needed
          ],
        ),
      ),
    );
  }
}

class PushNotificationTemplateHeader extends StatefulWidget {
  const PushNotificationTemplateHeader({super.key});

  @override
  State<PushNotificationTemplateHeader> createState() => _PushNotificationTemplateHeaderState();
}

class _PushNotificationTemplateHeaderState extends State<PushNotificationTemplateHeader> {
  String selectedLanguage = "en";

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

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
              // SAVE BUTTON
              // -----------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                      "Save Changes",
                      style: GoogleFonts.roboto(
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
                "Push Notification Template Settings",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Configure and customize push notification templates for various system events.",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  fontWeight: FontWeight.w200,
                  color: Colors.black.withOpacity(0.9),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================== Language Selection ====================
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
                Text(
                  "Select Language",
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: selectedLanguage,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    underline: const SizedBox(),
                    style: GoogleFonts.roboto(color: Colors.black, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedLanguage = newValue);
                      }
                    },
                    items: <String>["ar", "en", "es", "hi"].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==================== Vehicle Battery Low ====================
          _buildTemplateSection(
            context,
            title: "Vehicle Battery Low",
            icon: Icons.battery_alert_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== Vehicle Ignition On ====================
          _buildTemplateSection(
            context,
            title: "Vehicle Ignition On",
            icon: Icons.power_settings_new_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== Vehicle Overheating ====================
          _buildTemplateSection(
            context,
            title: "Vehicle Overheating",
            icon: Icons.thermostat_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== Vehicle Speeding ====================
          _buildTemplateSection(
            context,
            title: "Vehicle Speeding",
            icon: Icons.speed_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== Vehicle Stopped ====================
          _buildTemplateSection(
            context,
            title: "Vehicle Stopped",
            icon: Icons.stop_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final double width = MediaQuery.of(context).size.width;

    return Container(
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
                icon,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "MESSAGE",
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(width),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontSize: AdaptiveUtils.getTitleFontSize(width),
            ),
            controller: TextEditingController(),
            maxLines: 5,
            decoration: _inputDecoration(hint: "Enter push notification message"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(
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