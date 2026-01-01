import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';

class ApiConfigSettingsScreen extends StatelessWidget {
  const ApiConfigSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "API Configuration",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApiConfigHeader(),

            const SizedBox(height: 24),

            // You can add more boxes here like profile screen
          ],
        ),
      ),
    );
  }
}


class ApiConfigHeader extends StatefulWidget {
  const ApiConfigHeader({super.key});

  @override
  State<ApiConfigHeader> createState() => _ApiConfigHeaderState();
}

class _ApiConfigHeaderState extends State<ApiConfigHeader> {
  bool firebaseEnabled = true;
  bool geoEnabled = true;
  String selectedProvider = "OSM Nominatim(FREE - No key)";
  bool providerActive = true;
  bool ssoEnabled = true;
  bool openAiEnabled = true;
  String selectedModel = "GPT-4 TURBO (Recommended)";
  int maxTokens = 2048;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // -----------------------------------------
              // LEFT TEXTS (MATCH ApiConfig HEADER)
              // -----------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "API Configuration",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Third-Party Integrations",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ],
              ),

              // -----------------------------------------
              // SAVE BUTTON (MATCHES 'SAVE CHANGES')
              // -----------------------------------------
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
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
                  color: colorScheme.onPrimary,
                  size: AdaptiveUtils.getIconSize(width),
                ),
                label: Text(
                  "Save All Changes",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ==================== Firebase Configuration Header ====================
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Icon(
                Icons.fireplace_rounded,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
              const SizedBox(width: 8),
              Text(
                "Firebase Configuration",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: firebaseEnabled,
              activeColor: colorScheme.onPrimary,
              activeTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.onPrimary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
              onChanged: (v) => setState(() => firebaseEnabled = v),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24), // space between the two sections

      // ==================== Setup Instructions ====================
      Container(
         width: double.infinity,
  padding: const EdgeInsets.all(16), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.integration_instructions,
                  size: 22,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
                const SizedBox(width: 8),
                Text(
                  "Setup Instructions",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Go to",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse("https://console.firebase.google.com/");
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                "Firebase Console",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w600, // a bit bolder so it feels clickable
                  color: colorScheme.primary,
                  //decoration: TextDecoration.underline,
                  decorationColor: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "→ Project Settings → General → Your apps → SDK setup and configuration",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 24),

 Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // API KEY
        Text(
          "API KEY",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "fleetstack-project.firebaseapp.com"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // AUTH DOMAIN
        Text(
          "AUTH DOMAIN",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "fleetstack-project.firebaseapp.com"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // PROJECT ID
        Text(
          "PROJECT ID",
           style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "fleetstack-project"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // STORAGE BUCKET
        Text(
          "STORAGE BUCKET",
           style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "fleetstack-project.appspot.com"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // MESSAGING SENDER ID
        Text(
          "MESSAGING SENDER ID",
           style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "123456789012", ),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // APP ID
        Text(
          "APP ID",
           style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "1:123456789012:web:abcdef1234567890"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // MEASUREMENT ID (Optional)
        Text(
          "MEASUREMENT ID (Optional)",
           style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "G-XXXXXXXXXX"),
          decoration: _inputDecoration(context),
        ),
      ],
    ),
  SizedBox(height: 14,),
   Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.onSurface.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check icon chip
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 12),

          // Button Text
          Text(
            "Test Connection",
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ),
    ],
  ),
),
  SizedBox(height: 24,),
  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ==================== Reverse Geocoding Service Header ====================
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Icon(
                Icons.location_on_rounded,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
              const SizedBox(width: 8),
              Text(
                "Reverse Geocoding Service",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: geoEnabled,
              activeColor: colorScheme.onPrimary,
              activeTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.onPrimary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
              onChanged: (v) => setState(() => geoEnabled = v),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24), // space between the two sections

      // ==================== Configure Instructions ====================
      Container(
         width: double.infinity,
  padding: const EdgeInsets.all(16), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.integration_instructions,
                  size: 22,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
                const SizedBox(width: 8),
                Text(
                  "Configure Your Geocoding Provider",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Select a provider, enter credentials, and activate it to start using reverse geocoding services.",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 24),

 Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SELECT PROVIDER
        Text(
          "SELECT PROVIDER",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: selectedProvider,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            underline: const SizedBox(),
            style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => selectedProvider = newValue);
              }
            },
            items: <String>[
              "Google map (Paid - 5\$/100req)",
              "HERE Map(FREE - 250K/Month)",
              "TomTom(FREE - 250o/day)",
              "MapBox(FREE - 100/Month)",
              "Location IQ(FREE - 1000/day)",
              "OSM Nominatim(FREE - No key)",
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Selected: $selectedProvider",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        // ==================== Activate Provider ====================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16), // a bit more breathing room
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Activate Provider",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: providerActive,
                      activeColor: colorScheme.onPrimary,
                      activeTrackColor: colorScheme.primary,
                      inactiveThumbColor: colorScheme.onPrimary,
                      inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                      onChanged: (v) => setState(() => providerActive = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                providerActive
                    ? "This provider is now active and handling all reverse geocoding requests."
                    : "Activate this provider to begin using it for reverse geocoding.",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // ==================== Provider Documentation & Setup ====================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16), // a bit more breathing room
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.integration_instructions,
                    size: 22,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Provider Documentation & Setup",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
  spacing: 8, // space between items
  runSpacing: 6, // space between lines
  children: [
    _buildLink(context, "→ Google Cloud Console", "https://console.cloud.google.com/"),
    _buildLink(context, "→ HERE Developer", "https://developer.here.com/"),
    _buildLink(context, "→ TomTom Developer", "https://developer.tomtom.com/"),
    _buildLink(context, "→ Mapbox Account", "https://account.mapbox.com/"),
    _buildLink(context, "→ LocationIQ", "https://locationiq.com/"),
    _buildLink(context, "→ OSM Nominatim", "https://nominatim.org/"),
  ],
)

            ],
          ),
        ),
        const SizedBox(height: 24),
        // ==================== API Key or User Agent ====================
        if (selectedProvider != "OSM Nominatim(FREE - No key)")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${selectedProvider.split('(')[0].trim()} API KEY",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                controller: TextEditingController(),
                decoration: _inputDecoration(context),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "OpenStreetMap Nominatim - Free Service",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No API key required. Only User-Agent string needed.",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "USER AGENT STRING",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width),
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
                controller: TextEditingController(),
                decoration: _inputDecoration(context),
              ),
              const SizedBox(height: 8),
              Text(
                "Required by OSM usage policy",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
      ],
    ),
  SizedBox(height: 14,),
   Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.onSurface.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check icon chip
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 12),

          // Button Text
          Text(
            "Test Geocoding",
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ),
    ],
  ),
),
  SizedBox(height: 24,),
  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ==================== SSO - Google OAuth 2.0 Header ====================
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Icon(
                Icons.security_rounded,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
              const SizedBox(width: 8),
              Text(
                "SSO - Google OAuth 2.0",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: ssoEnabled,
              activeColor: colorScheme.onPrimary,
              activeTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.onPrimary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
              onChanged: (v) => setState(() => ssoEnabled = v),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24), // space between the two sections

      // ==================== Setup Instructions ====================
      Container(
         width: double.infinity,
  padding: const EdgeInsets.all(16), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.integration_instructions,
                  size: 22,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
                const SizedBox(width: 8),
                Text(
                  "Setup Instructions",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "1. Go to ",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse("https://console.cloud.google.com/");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    "Google Cloud Console",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "2. Create OAuth 2.0 Client ID (Application type: Web application)",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "3. Add authorized redirect URI: https://app.fleetstack.com/auth/google/callback",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "4. Copy Client ID and Client Secret",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 24),

 Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GOOGLE CLIENT ID
        Text(
          "GOOGLE CLIENT ID",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "123456789012-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // GOOGLE CLIENT SECRET
        Text(
          "GOOGLE CLIENT SECRET",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "GOCSPX-xxxxxxxxxxxxxxxxxxxx"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // REDIRECT URL
        Text(
          "REDIRECT URL",
           style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "https://app.fleetstack.com/auth/google/callback"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 8),
        Text(
          "Add this URL to authorized redirect URIs in Google Console",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    ),
  SizedBox(height: 14,),
   Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.onSurface.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check icon chip
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 12),

          // Button Text
          Text(
            "Test SSO Connection",
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ),
    ],
  ),
),
  SizedBox(height: 24,),
  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ==================== OpenAI Integration Header ====================
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
               Icon(
                Icons.auto_awesome_rounded,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
              const SizedBox(width: 8),
              Text(
                "OpenAI Integration",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: openAiEnabled,
              activeColor: colorScheme.onPrimary,
              activeTrackColor: colorScheme.primary,
              inactiveThumbColor: colorScheme.onPrimary,
              inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
              onChanged: (v) => setState(() => openAiEnabled = v),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24), // space between the two sections

      // ==================== Setup Instructions ====================
      Container(
         width: double.infinity,
  padding: const EdgeInsets.all(16), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.integration_instructions,
                  size: 22,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
                const SizedBox(width: 8),
                Text(
                  "Setup Instructions",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "1. Go to ",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse("https://platform.openai.com/api-keys");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    "OpenAI API Keys",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "2. Create new secret key (starts with sk-proj-...)",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "3. Optional: Get Organization ID from Settings",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "4. Set usage limits in Billing",
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 24),

 Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // API KEY
        Text(
          "API KEY",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // ORGANIZATION ID (Optional)
        Text(
          "ORGANIZATION ID (Optional)",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
          controller: TextEditingController(text: "org-xxxxxxxxxxxxxxxx"),
          decoration: _inputDecoration(context),
        ),
        const SizedBox(height: 12),

        // MODEL
        Text(
          "MODEL",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: selectedModel,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            underline: const SizedBox(),
            style: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: AdaptiveUtils.getTitleFontSize(width)),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => selectedModel = newValue);
              }
            },
            items: <String>[
              "GPT-4",
              "GPT-4 TURBO (Recommended)",
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // MAX-TOKEN
        Text(
          "MAX-TOKEN",
          style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: maxTokens.toDouble(),
          min: 1,
          max: 4096,
          divisions: 4095,
          label: maxTokens.toString(),
          activeColor: colorScheme.primary,
          onChanged: (double value) {
            setState(() {
              maxTokens = value.toInt();
            });
          },
        ),
        Text(
          "Range: 1–4096 tokens",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    ),
  SizedBox(height: 14,),
   Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: colorScheme.onSurface.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check icon chip
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: colorScheme.onPrimary,
            ),
          ),

          const SizedBox(width: 12),

          // Button Text
          Text(
            "Test Openai Connection",
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ),
    ],
  ),
),
  SizedBox(height: 24,),
  Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12), // a bit more breathing room
  decoration: BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
    border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ==================== Useful Documentation Header ====================
      Text(
        "Useful Documentation",
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface.withOpacity(0.87),
        ),
      ),

      const SizedBox(height: 16), // space between the two sections

      GestureDetector(
        onTap: () async {
          final url = Uri.parse("https://firebase.google.com/docs/web/setup");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Firebase setup",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Web SDK Documentation",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final url = Uri.parse("https://developers.google.com/maps/documentation/geocoding/overview");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Google geocoding",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "API Documentation",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final url = Uri.parse("https://developers.google.com/identity/protocols/oauth2");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Google OAuth 2.0",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "SSO implementation",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final url = Uri.parse("https://www.twilio.com/docs/whatsapp/api");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Twilio Whatsapp",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "API Documentation",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final url = Uri.parse("https://developers.facebook.com/docs/whatsapp");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Whatsapp Business",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Meta Documentation",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () async {
          final url = Uri.parse("https://platform.openai.com/docs/api-reference");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "OpenAI API",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Platform documentation",
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),

        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
    );
  }

  Widget _buildLink(BuildContext context, String label, String url) {
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
  return GestureDetector(
    onTap: () async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
        fontWeight: FontWeight.w400,
        color: colorScheme.primary,
      ),
    ),
  );
}

}