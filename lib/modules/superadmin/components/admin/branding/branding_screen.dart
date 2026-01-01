import 'package:fleet_stack/main.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/theme/app_theme.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
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
    "Default": AppTheme.defaultBrand,
    "Corporate": AppTheme.corporate,
    "Modern": AppTheme.modern,
    "Luxury": AppTheme.luxury,
    "Futuristic": AppTheme.futuristic,
  };

 Color get currentBrand => AppTheme.brandColor;


  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    await AppTheme.loadTheme();

    final matchEntry = themeColors.entries.firstWhere(
      (e) => e.value.value == AppTheme.brandColor.value,
      orElse: () => const MapEntry("Default", AppTheme.defaultBrand),
    );

    setState(() {
      selectedTheme = matchEntry.key;
      isDarkMode = AppTheme.isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode
        ? AppTheme.dark(currentBrand)
        : AppTheme.light(currentBrand);

    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

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
            // THEME PRESETS
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: themeColors.keys.map((themeName) {
                final isSelected = selectedTheme == themeName;

                return GestureDetector(
                  onTap: () async {
                    setState(() => selectedTheme = themeName);

                    final color = themeColors[themeName]!;

                    // Auto-fix for Default in dark mode
                    final brandToSet = (isDarkMode && themeName == "Default")
                        ? AppTheme.defaultDarkBrand
                        : color;

                    themeController.setBrand(brandToSet);
                    await AppTheme.setBrand(brandToSet);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? currentBrand.withOpacity(0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? currentBrand
                            : theme.tabBarTheme.unselectedLabelColor!,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: (themeName == "Default" && isDarkMode)
                              ? AppTheme.defaultDarkBrand
                              : themeColors[themeName],
                          radius: 6,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          themeName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? currentBrand : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check, size: 14, color: currentBrand),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // LIGHT / DARK MODE TOGGLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Preview Mode",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width),
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(10),
                  selectedColor: theme.colorScheme.onPrimary,
                  fillColor: theme.primaryColor,
                  color: theme.colorScheme.onSurface.withOpacity(0.87),
                  borderColor: theme.primaryColor.withOpacity(0.3),
                  borderWidth: 1.5,
                  isSelected: [!isDarkMode, isDarkMode],
                  onPressed: (index) async {
  final newDark = index == 1;

  // Update dark mode first
  setState(() => isDarkMode = newDark);

  // If Default theme is selected, force the correct brand color
  if (selectedTheme == "Default") {
    final forcedBrand =
        newDark ? AppTheme.defaultDarkBrand : AppTheme.defaultBrand;

    themeController.setBrand(forcedBrand);
    await AppTheme.setBrand(forcedBrand);

    setState(() {
      // Ensure UI buttons (circle + tick) use currentBrand immediately
      selectedTheme = "Default";
    });
  } else {
    // Reapply existing brand color for other themes
    themeController.setBrand(AppTheme.brandColor);
    await AppTheme.setBrand(AppTheme.brandColor);
  }

  // Save dark mode
  themeController.setDarkMode(newDark);
  await AppTheme.setDarkMode(newDark);
},

                  children: const [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text("Light",
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text("Dark",
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // PREVIEW BOX
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sample Dashboard",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This is how your UI will look.",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // BUTTON PREVIEW
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Primary Button",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
