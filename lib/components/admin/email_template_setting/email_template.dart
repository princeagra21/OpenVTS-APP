import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailTemplateSettingsScreen extends StatelessWidget {
  const EmailTemplateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Email Template",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmailTemplateHeader(),
            const SizedBox(height: 24),
            // You can add more boxes here if needed
          ],
        ),
      ),
    );
  }
}

class EmailTemplateHeader extends StatefulWidget {
  const EmailTemplateHeader({super.key});

  @override
  State<EmailTemplateHeader> createState() => _EmailTemplateHeaderState();
}

class _EmailTemplateHeaderState extends State<EmailTemplateHeader> {
  String selectedLanguage = "en-US";

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
                "Email Template Settings",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Configure and customize email templates for various system notifications.",
                style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(color: Colors.black, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedLanguage = newValue);
                      }
                    },
                    items: <String>["es", "ar", "hi", "en", "en-US"].map<DropdownMenuItem<String>>((String value) {
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

          // ==================== Invoice Notification ====================
          _buildTemplateSection(
            context,
            title: "Invoice Notification",
            icon: Icons.receipt_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== OTP Verification ====================
          _buildTemplateSection(
            context,
            title: "OTP Verification",
            icon: Icons.security_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== Password Reset ====================
          _buildTemplateSection(
            context,
            title: "Password Reset",
            icon: Icons.lock_reset_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== User Creation (Welcome) ====================
          _buildTemplateSection(
            context,
            title: "User Creation (Welcome)",
            icon: Icons.person_add_rounded,
          ),

          const SizedBox(height: 24),

          // ==================== Verify Email ====================
          _buildTemplateSection(
            context,
            title: "Verify Email",
            icon: Icons.email_rounded,
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
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "SUBJECT",
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
            decoration: _inputDecoration(hint: "Enter email subject"),
          ),
          const SizedBox(height: 24),
          Text(
            "BODY",
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
            maxLines: 10,
            decoration: _inputDecoration(hint: "Enter email body (supports HTML)"),
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