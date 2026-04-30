// screens/settings/branding_settings_screen.dart
import 'package:fleet_stack/modules/admin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandingSettingsScreen extends StatelessWidget {
  const BrandingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "White Label",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandingSettingsBox(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BrandingSettingsBox extends StatelessWidget {
  const _BrandingSettingsBox();

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
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Save Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "White Label",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Branding Settings",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: hp + 2, vertical: hp - 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.save_outlined, color: colorScheme.onPrimary, size: AdaptiveUtils.getIconSize(width)),
                label: Text(
                  "Save Changes",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: hp * 2),

          // Base URL Configuration
          _buildSection(
            context: context,
            icon: Icons.language,
            title: "Base URL Configuration",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Base URL", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: "app.fleetstack.com",
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outline)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                  ),
                  style: GoogleFonts.inter(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  "Enter your custom domain without http:// or https://",
                  style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.54)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Server Information
          _buildSection(
            context: context,
            icon: Icons.storage,
            title: "Server Information",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Server IP:",
                      style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 6, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.87)),
                    ),
                    const SizedBox(width: 6),
                    SmallTab(label: "192.168.1.100", selected: false, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Use this IP address for DNS configuration",
                  style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.54)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),
          Divider(color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 13),

          // Favicon & Logos
          _buildSection(
            context: context,
            icon: Icons.image,
            title: "Favicon & Logos",
            child: Column(
              children: [
                _buildSingleUploadContainer(context: context, width: width, title: "Favicon", smallTabLabel: "16×16 or 32×32 px"),
                const SizedBox(height: 16),
                _buildSingleUploadContainer(context: context, width: width, title: "Dark Logo", smallTabLabel: "For light backgrounds"),
                const SizedBox(height: 16),
                _buildSingleUploadContainer(context: context, width: width, title: "Light Logo", smallTabLabel: "For dark backgrounds"),
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
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSingleUploadContainer({
    required BuildContext context,
    required double width,
    required String title,
    required String smallTabLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double boxHeight = width < 500 ? 85 : 110;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(width: 12),
              SmallTab(label: smallTabLabel, selected: false, onTap: () {}),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: boxHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 26, color: colorScheme.onSurface.withOpacity(0.54)),
                        const SizedBox(height: 4),
                        Text(
                          "Click to upload\nICO, PNG (max 2MB)",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 6, color: colorScheme.onSurface.withOpacity(0.54)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: boxHeight,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: colorScheme.surfaceVariant),
                      child: Center(
                        child: Text("Preview", style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.54))),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 14, color: colorScheme.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
