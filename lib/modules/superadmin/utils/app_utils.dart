// app_utils.dart
// This file contains utility constants and helpers for a premium Flutter app.
// It includes dimensions for cards, paddings, borders, buttons, app bars, and more.
// Updated to support light and dark modes with a minimal black, white, and transparent color palette.
// Added app-specific constants to match the provided code (e.g., paddings of 20, sizes of 45/40, etc.).
// Updated fonts: Using 'Inter' from Google Fonts for body text, and 'Satoshi' (custom font) for headings.
// To use 'Inter', add dependency: google_fonts: ^6.2.1 (or latest) in pubspec.yaml.
// For 'Satoshi', download from Fontshare[](https://www.fontshare.com/fonts/satoshi), add font files to assets/fonts/,
// and declare in pubspec.yaml under fonts:
//   - family: Satoshi
//     fonts:
//       - asset: assets/fonts/Satoshi/Fonts/OTF/Satoshi-Light.otf
//         weight: 300
//       - asset: assets/fonts/Satoshi/Fonts/OTF/Satoshi-Regular.otf
//         weight: 400
//       - asset: assets/fonts/Satoshi/Fonts/OTF/Satoshi-Medium.otf
//         weight: 500
//       - asset: assets/fonts/Satoshi/Fonts/OTF/Satoshi-Bold.otf
//         weight: 700
//       - asset: assets/fonts/Satoshi/Fonts/OTF/Satoshi-Black.otf
//         weight: 900
// (Add other weights or italics as needed).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppUtils {
  // Minimal Color Palette (black, white, transparent as specified)
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
  static const Color errorColor = Colors.red; // Kept for errors; can be adjusted if needed

  // Opacity-based subtle colors (using black/white with transparency for premium subtlety)
  static Color subtleBlack(double opacity) => black.withOpacity(opacity);
  static Color subtleWhite(double opacity) => white.withOpacity(opacity);

  // Font Families
  static const String headingFont = 'Satoshi';
  // Body font is handled via GoogleFonts.roboto()

  // Text Styles (premium typography: clean, sans-serif, with hierarchy)
  // Base styles without color; colors applied in themes
  // Headings use 'Satoshi', body uses 'Inter' from Google Fonts
  static TextStyle headlineLargeBase = const TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    fontFamily: headingFont,
  );

  static TextStyle headlineMediumBase = const TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    fontFamily: headingFont,
  );

  static TextStyle headlineSmallBase = const TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    fontFamily: headingFont,
  );

  static TextStyle bodyLargeBase = GoogleFonts.roboto(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );

  static TextStyle bodyMediumBase = GoogleFonts.roboto(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  static TextStyle bodySmallBase = GoogleFonts.roboto(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
  );

  static TextStyle subtitleBase = GoogleFonts.roboto(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
  );

  static TextStyle buttonTextBase = GoogleFonts.roboto(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
  );

  static TextStyle labelBoldBase = const TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    fontFamily: headingFont, // Using Satoshi for bold labels like 'FS'
  );

  // Paddings (symmetric for consistency, premium spacing: generous but not wasteful)
  static const EdgeInsets paddingExtraSmall = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);
  static const EdgeInsets paddingExtraLarge = EdgeInsets.all(32.0);

  // App-specific paddings (matching provided code)
  static const EdgeInsets paddingApp = EdgeInsets.all(20.0);
  static const EdgeInsets paddingHorizontalApp = EdgeInsets.symmetric(horizontal: 20.0);

  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: 24.0);

  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: 24.0);

  // AppBar Height (premium: slightly taller for presence)
  static const double appBarHeightSmall = 56.0; // Standard mobile
  static const double appBarHeightMedium = 64.0; // Slightly taller
  static const double appBarHeightLarge = 72.0; // For tablets or prominent headers
  static const double appBarHeightCustom = 50.0; // Matching provided code

  // Card Sizes (width/height suggestions; use MediaQuery for responsiveness)
  // Small Card: For icons or mini info
  static const double cardWidthSmall = 120.0;
  static const double cardHeightSmall = 80.0;

  // Medium Card: For standard content
  static const double cardWidthMedium = 200.0;
  static const double cardHeightMedium = 150.0;

  // Large Card: For featured items
  static const double cardWidthLarge = 300.0;
  static const double cardHeightLarge = 250.0;

  // Border Radii (for rounded corners; premium: subtle rounding for elegance)
  static const BorderRadius borderRadiusExtraSmall = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius borderRadiusExtraLarge = BorderRadius.all(Radius.circular(32.0));
  static const BorderRadius borderRadiusCircle = BorderRadius.all(Radius.circular(100.0)); // For avatars

  // Elevations (shadows for premium depth)
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0; // Subtle
  static const double elevationMedium = 4.0; // Standard card
  static const double elevationHigh = 8.0; // Floating elements

  // Button Sizes and Styles
  // Button Heights (premium: comfortable tap targets)
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Button Widths (use minWidth for consistency)
  static const double buttonMinWidthSmall = 88.0;
  static const double buttonMinWidthMedium = 120.0;
  static const double buttonMinWidthLarge = 160.0;

  // App-specific sizes
  static const double avatarSize = 35.0; // For FS circle
  static const double iconButtonSize = 40.0; // For right icons

  // Pre-defined Button Styles (using ElevatedButton for premium feel)
  // Styles are mode-agnostic; colors pulled from theme
  static ButtonStyle elevatedButtonStyle({
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? borderRadiusMedium,
      ),
      padding: padding ?? paddingMedium,
      elevation: elevationMedium,
      shadowColor: black.withOpacity(0.2), // Subtle shadow
    );
  }

  static ButtonStyle outlinedButtonStyle({
    Color? borderColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: borderColor ?? black, width: 2.0),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? borderRadiusMedium,
      ),
      padding: padding ?? paddingMedium,
    );
  }

  static ButtonStyle textButtonStyle({
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return TextButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? borderRadiusMedium,
      ),
      padding: padding ?? paddingMedium,
    );
  }

  // Icon Sizes (premium: balanced with text)
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeApp = 20.0; // Matching provided code

  // Spacing (for SizedBox, etc.)
  static const double spacingExtraSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;
  static const double spacingAppSmall = 3.0; // For subtitle spacing
  static const double spacingAppMedium = 12.0; // For avatar spacing

  // Screen Edge Insets (for safe areas, premium: respect device notches)
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Responsive Helpers (for premium adaptability across devices)
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isTablet(BuildContext context) => screenWidth(context) > 600;

  // Example: Responsive card width
  static double responsiveCardWidth(BuildContext context, {required double baseWidth}) {
    return isTablet(context) ? baseWidth * 1.5 : baseWidth;
  }

  // Theme Helpers (for light and dark modes with minimal palette)
  static ThemeData getLightTheme() {
    const Color textColor = black;
    const Color subtleTextColor = Color(0xFF757575); // Gray for subtlety
    const Color backgroundColor = white;
    const Color primaryColor = black; // For accents in light mode

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        color: primaryColor,
        elevation: elevationMedium,
        titleTextStyle: headlineMediumBase.copyWith(color: white),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      textTheme: TextTheme(
        headlineLarge: headlineLargeBase.copyWith(color: textColor),
        headlineMedium: headlineMediumBase.copyWith(color: textColor),
        headlineSmall: headlineSmallBase.copyWith(color: textColor),
        bodyLarge: bodyLargeBase.copyWith(color: textColor),
        bodyMedium: bodyMediumBase.copyWith(color: textColor),
        bodySmall: bodySmallBase.copyWith(color: subtleTextColor),
      ),
      // No global fontFamily set; handled in individual styles
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.grey, // Minimal, using grey for scheme
      ).copyWith(
        secondary: black,
        background: backgroundColor,
        error: errorColor,
      ),
    );
  }

  static ThemeData getDarkTheme() {
    const Color textColor = white;
    const Color subtleTextColor = Color(0xFFBDBDBD); // Lighter gray for subtlety in dark
    const Color backgroundColor = black;
    const Color primaryColor = white; // For accents in dark mode

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        color: primaryColor,
        elevation: elevationMedium,
        titleTextStyle: headlineMediumBase.copyWith(color: black),
      ),
      cardTheme: CardThemeData(
        color: black,
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      textTheme: TextTheme(
        headlineLarge: headlineLargeBase.copyWith(color: textColor),
        headlineMedium: headlineMediumBase.copyWith(color: textColor),
        headlineSmall: headlineSmallBase.copyWith(color: textColor),
        bodyLarge: bodyLargeBase.copyWith(color: textColor),
        bodyMedium: bodyMediumBase.copyWith(color: textColor),
        bodySmall: bodySmallBase.copyWith(color: subtleTextColor),
      ),
      // No global fontFamily set; handled in individual styles
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: white,
        background: backgroundColor,
        error: errorColor,
      ),
    );
  }
}

// Usage Example:
// In your main.dart:
// void main() {
//   runApp(MaterialApp(
//     title: 'Premium App',
//     theme: AppUtils.getLightTheme(),
//     darkTheme: AppUtils.getDarkTheme(),
//     themeMode: ThemeMode.system, // Follows device light/dark mode
//     home: MyHomePage(),
//   ));
// }
//
// In a widget (colors will adapt based on theme mode):
// Card(
//   elevation: AppUtils.elevationMedium,
//   shape: RoundedRectangleBorder(borderRadius: AppUtils.borderRadiusMedium),
//   child: SizedBox(
//     width: AppUtils.cardWidthMedium,
//     height: AppUtils.cardHeightMedium,
//     child: Padding(
//       padding: AppUtils.paddingMedium,
//       child: Text('Premium Content', style: Theme.of(context).textTheme.bodyMedium),
//     ),
//   ),
// )
//
// ElevatedButton(
//   style: AppUtils.elevatedButtonStyle(
//     backgroundColor: Theme.of(context).primaryColor,
//   ),
//   onPressed: () {},
//   child: Text('Premium Button', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppUtils.white)),
// )