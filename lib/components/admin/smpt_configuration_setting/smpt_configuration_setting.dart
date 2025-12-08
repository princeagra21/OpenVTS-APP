import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmtpConfigSettingsScreen extends StatelessWidget {
  const SmtpConfigSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "SMTP Configuration",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmtpConfigHeader(),
            const SizedBox(height: 24),
            // You can add more boxes here if needed
          ],
        ),
      ),
    );
  }
}

class SmtpConfigHeader extends StatefulWidget {
  const SmtpConfigHeader({super.key});

  @override
  State<SmtpConfigHeader> createState() => _SmtpConfigHeaderState();
}

class _SmtpConfigHeaderState extends State<SmtpConfigHeader> {
  bool smtpEnabled = true;
  bool tlsEnabled = true;

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
    // BUTTONS (SAVE AND TEST) - RIGHT SIDE TOP
    // -----------------------------------------
    Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              "Save Configuration",
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
              Icons.email_outlined,
              color: Colors.white,
              size: AdaptiveUtils.getIconSize(width),
            ),
            label: Text(
              "Send Test Email",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),

    const SizedBox(height: 24),

    // -----------------------------------------
    // LEFT TEXTS
    // -----------------------------------------
    Text(
      "SMTP Configuration",
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getTitleFontSize(width),
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      "Configure your email server settings",
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
        fontWeight: FontWeight.w800,
        color: Colors.black.withOpacity(0.9),
      ),
    ),
  ],
),


          const SizedBox(height: 24),

          // ==================== Enable SMTP Service Container ====================
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
                          Icons.email_rounded,
                          size: AdaptiveUtils.getTitleFontSize(width) + 5,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Enable SMTP Service",
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
                        value: smtpEnabled,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.black,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.black.withOpacity(0.3),
                        onChanged: (v) => setState(() => smtpEnabled = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "SMTP service is active and will send emails",
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

          // ==================== Configure Your SMTP Server ====================
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
                Row(
                  children: [
                    const Icon(
                      Icons.settings_rounded,
                      size: 22,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Configure Your SMTP Server",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter your custom SMTP server details below to send system emails and notifications.",
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

          // ==================== SMTP Server Configuration ====================
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
                // SMTP HOST
                Text(
                  "SMTP HOST",
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
                  controller: TextEditingController(),
                  decoration: _inputDecoration(hint: "e.g., smtp.gmail.com"),
                ),
                const SizedBox(height: 12),

                // SMTP PORT
                Text(
                  "SMTP PORT",
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
                  controller: TextEditingController(),
                  decoration: _inputDecoration(hint: "Common: 587, 465, 25"),
                ),
                const SizedBox(height: 8),
                Text(
                  "Common: 587, 465, 25",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),

                // USE TLS/SSL ENCRYPTION
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Use TLS/SSL Encryption",
                            style: GoogleFonts.inter(
                              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: tlsEnabled,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.black,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.black.withOpacity(0.3),
                              onChanged: (v) => setState(() => tlsEnabled = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Secure connection enabled (Recommended for ports 465 and 587)",
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

                // USERNAME / EMAIL
                Text(
                  "USERNAME / EMAIL",
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
                  controller: TextEditingController(),
                  decoration: _inputDecoration(
                    hint: "SMTP authentication username (usually your email address)",
                  ),
                ),
                const SizedBox(height: 12),

                // PASSWORD / APP PASSWORD
                Text(
                  "PASSWORD / APP PASSWORD",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  obscureText: true,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                  ),
                  controller: TextEditingController(),
                  decoration: _inputDecoration(
                    hint: "For Gmail/Google Workspace, use an App Password",
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "For Gmail/Google Workspace, use an App Password",
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

          // ==================== Sender Information ====================
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
                      Icons.person_rounded,
                      size: AdaptiveUtils.getTitleFontSize(width) + 5,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Sender Information",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // FROM EMAIL ADDRESS
                Text(
                  "FROM EMAIL ADDRESS",
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
                  controller: TextEditingController(),
                  decoration: _inputDecoration(
                    hint: "This email address will appear as the sender for all system emails",
                  ),
                ),
                const SizedBox(height: 12),

                // FROM NAME
                Text(
                  "FROM NAME",
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
                  controller: TextEditingController(text: "FleetStack"),
                  decoration: _inputDecoration(
                    hint: "Display name that will appear alongside the email address",
                  ),
                ),
                const SizedBox(height: 12),

                // REPLY-TO EMAIL (OPTIONAL)
                Text(
                  "REPLY-TO EMAIL (Optional)",
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
                  controller: TextEditingController(),
                  decoration: _inputDecoration(
                    hint: "Email address where replies should be sent (if different from sender)",
                  ),
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