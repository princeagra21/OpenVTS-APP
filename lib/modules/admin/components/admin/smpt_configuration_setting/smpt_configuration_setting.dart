// screens/settings/smtp_config_settings_screen.dart
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
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
            const SmtpConfigHeader(),
            const SizedBox(height: 24),
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
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

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
          // TOP BUTTONS (Save & Test)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(horizontal: hp + 2, vertical: hp - 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.save_outlined, color: colorScheme.onPrimary, size: AdaptiveUtils.getIconSize(width)),
                  label: Text(
                    "Save Configuration",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(horizontal: hp + 2, vertical: hp - 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.email_outlined, color: colorScheme.onPrimary, size: AdaptiveUtils.getIconSize(width)),
                  label: Text(
                    "Send Test Email",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TITLE
          Text(
            "SMTP Configuration",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width),
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure your email server settings",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 24),

          // Enable SMTP Service
          _buildSection(
            context: context,
            icon: Icons.email_rounded,
            title: "Enable SMTP Service",
            subtitle: "SMTP service is active and will send emails",
            trailing: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: smtpEnabled,
                activeColor: colorScheme.onPrimary,
                activeTrackColor: colorScheme.primary,
                inactiveThumbColor: colorScheme.onPrimary,
                inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                onChanged: (v) => setState(() => smtpEnabled = v),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Configure Your SMTP Server
          _buildSection(
            context: context,
            icon: Icons.settings_rounded,
            title: "Configure Your SMTP Server",
            subtitle: "Enter your custom SMTP server details below to send system emails and notifications.",
          ),

          const SizedBox(height: 24),

          // SMTP Server Configuration Fields
          Container(
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
                _buildInputField(context, label: "SMTP HOST", hint: "e.g., smtp.gmail.com"),
                const SizedBox(height: 16),
                _buildInputField(context, label: "SMTP PORT", hint: "Common: 587, 465, 25"),
                const SizedBox(height: 8),
                Text("Common: 587, 465, 25", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5, color: colorScheme.onSurface.withOpacity(0.8))),
                const SizedBox(height: 24),

                // TLS/SSL Switch
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Use TLS/SSL Encryption",
                        style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.87)),
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: tlsEnabled,
                          activeColor: colorScheme.onPrimary,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.onPrimary,
                          inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                          onChanged: (v) => setState(() => tlsEnabled = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildInputField(context, label: "USERNAME / EMAIL", hint: "SMTP authentication username (usually your email address)"),
                const SizedBox(height: 16),
                _buildInputField(context, label: "PASSWORD / APP PASSWORD", hint: "For Gmail/Google Workspace, use an App Password", obscureText: true),
                const SizedBox(height: 8),
                Text("For Gmail/Google Workspace, use an App Password", style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5, color: colorScheme.onSurface.withOpacity(0.8))),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sender Information
          _buildSection(
            context: context,
            icon: Icons.person_rounded,
            title: "Sender Information",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(context, label: "FROM EMAIL ADDRESS", hint: "This email address will appear as the sender for all system emails"),
                const SizedBox(height: 16),
                _buildInputField(context, label: "FROM NAME", hint: "Display name that will appear alongside the email address", initialValue: "FleetStack"),
                const SizedBox(height: 16),
                _buildInputField(context, label: "REPLY-TO EMAIL (Optional)", hint: "Email address where replies should be sent (if different from sender)"),
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
    Widget? trailing,
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
              Icon(icon, size: AdaptiveUtils.getTitleFontSize(width) + 5, color: colorScheme.primary.withOpacity(0.87)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width) + 2, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.87)),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(subtitle, style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5, color: colorScheme.onSurface.withOpacity(0.8))),
          ],
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, {required String label, required String hint, String? initialValue, bool obscureText = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: AdaptiveUtils.getTitleFontSize(width), fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue ?? '',
          obscureText: obscureText,
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontSize: AdaptiveUtils.getTitleFontSize(width),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: AdaptiveUtils.getTitleFontSize(width),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
