import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/main.dart' show themeController;
import 'package:open_vts/modules/admin/layout/app_layout.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({super.key});

  @override
  State<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  String selectedTheme = "Default";
  bool isDarkMode = false;

  final Map<String, Color> themeColors = {
    "Default": OpenVtsTheme.defaultBrand,
    "Corporate": OpenVtsColors.themeCorporate,
    "Modern": OpenVtsColors.themeModern,
    "Luxury": OpenVtsColors.themeLuxury,
    "Futuristic": OpenVtsColors.themeFuturistic,
  };

  Color get currentBrand => themeController.brandColor.value;


  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final savedBrand = themeController.brandColor.value;

    final matchEntry = themeColors.entries.firstWhere(
      (e) => e.value.value == savedBrand.value,
      orElse: () => const MapEntry("Default", OpenVtsTheme.defaultBrand),
    );

    setState(() {
      selectedTheme = matchEntry.key;
      isDarkMode = themeController.themeMode.value == ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode
        ? OpenVtsTheme.dark(currentBrand)
        : OpenVtsTheme.light(currentBrand);

    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "Open VTS",
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
                        ? OpenVtsTheme.defaultDarkBrand
                        : color;

                    await themeController.setBrand(brandToSet);
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
                            : theme.colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: (themeName == "Default" && isDarkMode)
                              ? OpenVtsTheme.defaultDarkBrand
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
                  style: AppFonts.inter(
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
                          newDark
                              ? OpenVtsTheme.defaultDarkBrand
                              : OpenVtsTheme.defaultBrand;

                      await themeController.setBrand(forcedBrand);

                      setState(() {
                        // Ensure UI buttons (circle + tick) use currentBrand immediately
                        selectedTheme = "Default";
                      });
                    } else {
                      // Reapply existing brand color for other themes
                      final selectedColor =
                          themeColors[selectedTheme] ?? themeController.brandColor.value;
                      await themeController.setBrand(selectedColor);
                    }

                    // Save dark mode
                    await themeController.setThemeMode(
                      newDark ? ThemeMode.dark : ThemeMode.light,
                    );
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
                    style: AppFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This is how your UI will look.",
                    style: AppFonts.inter(
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

