import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  String selectedTheme = "Default";
  bool isDarkMode = false;

  final Map<String, Color> themeColors = {
    "Default": const Color(0xFF000000),
    "Corporate": const Color(0xFF1E40AF),
    "Modern": const Color(0xFF6D28D9),
    "Luxury": const Color(0xFF92400E),
    "Futuristic": const Color(0xFF0E7490),
  };

  final Map<String, Map<String, Map<String, Color>>> themes = {
    "Default": {
      "light": {
        "bg": const Color(0xFFFFFFFF),
        "surface": const Color(0xFFF5F5F5),
        "text": const Color(0xFF000000),
        "muted": const Color(0xFF666666),
        "primary": const Color.fromARGB(255, 0, 0, 0),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
      "dark": {
        "bg": const Color(0xFF000000),
        "surface": const Color(0xFF0A0A0A),
        "text": const Color(0xFFFFFFFF),
        "muted": const Color(0xFFA3A3A3),
        "primary": const Color.fromARGB(255, 253, 253, 253),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
    },
    "Corporate": {
      "light": {
        "bg": const Color(0xFFFFFFFF),
        "surface": const Color(0xFFF5F5F5),
        "text": const Color(0xFF000000),
        "muted": const Color(0xFF666666),
        "primary": const Color(0xFF1E40AF),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
      "dark": {
        "bg": const Color(0xFF000000),
        "surface": const Color(0xFF0A0A0A),
        "text": const Color(0xFFFFFFFF),
        "muted": const Color(0xFFA3A3A3),
        "primary": const Color(0xFF1E40AF),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
    },
    "Modern": {
      "light": {
        "bg": const Color(0xFFFFFFFF),
        "surface": const Color(0xFFF5F5F5),
        "text": const Color(0xFF000000),
        "muted": const Color(0xFF666666),
        "primary": const Color(0xFF6D28D9),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
      "dark": {
        "bg": const Color(0xFF000000),
        "surface": const Color(0xFF0A0A0A),
        "text": const Color(0xFFFFFFFF),
        "muted": const Color(0xFFA3A3A3),
        "primary": const Color(0xFF6D28D9),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
    },
    "Luxury": {
      "light": {
        "bg": const Color(0xFFFFFFFF),
        "surface": const Color(0xFFF5F5F5),
        "text": const Color(0xFF000000),
        "muted": const Color(0xFF666666),
        "primary": const Color(0xFF92400E),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
      "dark": {
        "bg": const Color(0xFF000000),
        "surface": const Color(0xFF0A0A0A),
        "text": const Color(0xFFFFFFFF),
        "muted": const Color(0xFFA3A3A3),
        "primary": const Color(0xFF92400E),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
    },
    "Futuristic": {
      "light": {
        "bg": const Color(0xFFFFFFFF),
        "surface": const Color(0xFFF5F5F5),
        "text": const Color(0xFF000000),
        "muted": const Color(0xFF666666),
        "primary": const Color(0xFF0E7490),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
      "dark": {
        "bg": const Color(0xFF000000),
        "surface": const Color(0xFF0A0A0A),
        "text": const Color(0xFFFFFFFF),
        "muted": const Color(0xFFA3A3A3),
        "primary": const Color(0xFF0E7490),
        "warning": const Color(0xFFF59E0B),
        "danger": const Color(0xFFEF4444),
      },
    },
  };

  Color get currentBg => themes[selectedTheme]![isDarkMode ? "dark" : "light"]!["bg"]!;
  Color get currentSurface => themes[selectedTheme]![isDarkMode ? "dark" : "light"]!["surface"]!;
  Color get currentText => themes[selectedTheme]![isDarkMode ? "dark" : "light"]!["text"]!;
  Color get currentMuted => themes[selectedTheme]![isDarkMode ? "dark" : "light"]!["muted"]!;
  Color get currentPrimary => themes[selectedTheme]![isDarkMode ? "dark" : "light"]!["primary"]!;
  Color get currentWarning => themes[selectedTheme]![isDarkMode ? "dark" : "light"]!["warning"]!;
  Color get currentDanger => themes[selectedTheme]![isDarkMode ? "dark" : "light"]!["danger"]!;

  String toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

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
            // Main Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top-right buttons
                      Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  selectedTheme = "Default";
                                  isDarkMode = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_outlined, size: 18, color: Colors.white),
                              label: const Text(
                                "Reset",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                              label: const Text(
                                "Save",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16), // space between buttons and text
                      // Text below
                      Text(
                        "Branding & Colors",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Customize color schemes and instantly preview UI.",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Theme Presets
                 Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    "Default",
    "Corporate",
    "Modern",
    "Luxury",
    "Futuristic",
  ].map((theme) {
    final isSelected = selectedTheme == theme;

    return GestureDetector(
      onTap: () => setState(() => selectedTheme = theme),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColors[theme]!.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? themeColors[theme]! : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: themeColors[theme],
              radius: 6, // smaller avatar
            ),
            SizedBox(width: 6),
            Text(
              theme,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? themeColors[theme]! : Colors.black,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 4),
              Icon(Icons.check, size: 14, color: themeColors[theme]!),
            ],
          ],
        ),
      ),
    );
  }).toList(),
),

                  const SizedBox(height: 32),
                  Stack(
                    children: [
                      // Left: Title
                      Text(
                        "Active Preview",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(width),
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      // Right: Compact ToggleButtons (smaller & tighter)
                      Align(
                        alignment: Alignment.topRight,
                        child: ToggleButtons(
                          constraints: const BoxConstraints(minHeight: 32, minWidth: 56), // smaller buttons
                          borderRadius: BorderRadius.circular(10),
                          selectedColor: Colors.white,
                          fillColor: Colors.black,
                          color: Colors.black87, // unselected text color
                          selectedBorderColor: Colors.black,
                          borderColor: Colors.black26,
                          borderWidth: 1.5,
                          isSelected: [!isDarkMode, isDarkMode],
                          onPressed: (index) {
                            setState(() => isDarkMode = index == 1);
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                "Light",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                "Dark",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Sample Dashboard Preview
                  // Sample Dashboard Preview
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: currentSurface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.black.withOpacity(0.1)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Sample Dashboard",
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
          fontWeight: FontWeight.w800,
          color: currentText,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        "This is how your UI will look.",
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
          color: currentMuted,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        "Muted text example",
        style: GoogleFonts.inter(color: currentMuted),
      ),
      const SizedBox(height: 16),

      // Buttons using Container
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: currentPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                "Primary Button",
                style: TextStyle(
                  color: isDarkMode ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              alignment: Alignment.center,
              child: Text(
                "Secondary Button",
                style: TextStyle(
                  color: currentText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
),

                   
                  const SizedBox(height: 32),
                  // Color Palette Table
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LIGHT MODE",
                              style: GoogleFonts.inter(
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _colorRow(themes[selectedTheme]!["light"]!["text"]!, "Text / Icons"),
                            _colorRow(themes[selectedTheme]!["light"]!["bg"]!, "Background"),
                            _colorRow(themes[selectedTheme]!["light"]!["surface"]!, "Cards"),
                            _colorRow(themes[selectedTheme]!["light"]!["muted"]!, "Muted Text"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "DARK MODE",
                              style: GoogleFonts.inter(
                                fontSize: AdaptiveUtils.getTitleFontSize(width),
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _colorRow(themes[selectedTheme]!["dark"]!["text"]!, "Text / Icons"),
                            _colorRow(themes[selectedTheme]!["dark"]!["bg"]!, "Background"),
                            _colorRow(themes[selectedTheme]!["dark"]!["surface"]!, "Cards"),
                            _colorRow(themes[selectedTheme]!["dark"]!["muted"]!, "Muted Text"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorRow(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                toHex(color),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}