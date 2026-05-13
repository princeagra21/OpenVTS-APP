export 'open_vts_borders.dart';
export 'open_vts_colors.dart';
export 'open_vts_icon_sizes.dart';
export 'open_vts_motion.dart';
export 'open_vts_radius.dart';
export 'open_vts_shadows.dart';
export 'open_vts_spacing.dart';
export 'open_vts_typography.dart';

import 'package:flutter/material.dart';

import 'open_vts_colors.dart';
import 'open_vts_radius.dart';
import 'open_vts_spacing.dart';
import 'open_vts_typography.dart';

class OpenVtsTheme {
	const OpenVtsTheme._();

	static const Color defaultBrand = OpenVtsColors.brandInk;
	static const Color defaultDarkBrand = OpenVtsColors.white;

	static ThemeData light([Color? brand]) {
		final Color primary = _effectiveBrand(brand, isDark: false);
		final TextTheme textTheme = OpenVtsTypography.textTheme(
			brightness: Brightness.light,
		);

		final ColorScheme scheme = ColorScheme(
			brightness: Brightness.light,
			primary: primary,
			onPrimary: OpenVtsColors.white,
			secondary: OpenVtsColors.brandInkSoft,
			onSecondary: OpenVtsColors.white,
			tertiary: OpenVtsColors.textSecondary,
			onTertiary: OpenVtsColors.white,
			error: OpenVtsColors.danger,
			onError: OpenVtsColors.white,
			surface: OpenVtsColors.surface,
			onSurface: OpenVtsColors.textPrimary,
			outline: OpenVtsColors.border,
			outlineVariant: OpenVtsColors.divider,
			shadow: const Color(0x22000000),
			scrim: const Color(0x66000000),
			inverseSurface: OpenVtsColors.brandInk,
			onInverseSurface: OpenVtsColors.white,
			inversePrimary: OpenVtsColors.white,
		);

		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.light,
			fontFamily: OpenVtsTypography.fontFamily,
			colorScheme: scheme,
			primaryColor: primary,
			scaffoldBackgroundColor: OpenVtsColors.background,
			canvasColor: OpenVtsColors.background,
			dividerColor: OpenVtsColors.divider,
			textTheme: textTheme,
			appBarTheme: AppBarTheme(
				backgroundColor: OpenVtsColors.background,
				foregroundColor: OpenVtsColors.textPrimary,
				elevation: 0,
				centerTitle: false,
				titleTextStyle: textTheme.titleLarge,
			),
			cardTheme: CardThemeData(
				color: OpenVtsColors.surface,
				elevation: 0,
				shape: RoundedRectangleBorder(
					borderRadius: OpenVtsRadius.radiusLg,
					side: const BorderSide(color: OpenVtsColors.border),
				),
				margin: const EdgeInsets.all(OpenVtsSpacing.sm),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: OpenVtsColors.white,
				contentPadding: const EdgeInsets.symmetric(
					horizontal: OpenVtsSpacing.lg,
					vertical: OpenVtsSpacing.md,
				),
				hintStyle: textTheme.bodyMedium?.copyWith(
					color: OpenVtsColors.textTertiary,
				),
				labelStyle: textTheme.bodyMedium?.copyWith(
					color: OpenVtsColors.textSecondary,
				),
				enabledBorder: const OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: OpenVtsColors.border),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: primary, width: 1.4),
				),
				errorBorder: const OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: OpenVtsColors.danger),
				),
				focusedErrorBorder: const OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: OpenVtsColors.danger, width: 1.4),
				),
			),
			elevatedButtonTheme: ElevatedButtonThemeData(
				style: ElevatedButton.styleFrom(
					elevation: 0,
					backgroundColor: primary,
					foregroundColor: OpenVtsColors.white,
					minimumSize: const Size(0, OpenVtsSpacing.buttonHeight),
					shape: const RoundedRectangleBorder(
						borderRadius: OpenVtsRadius.radiusMd,
						side: BorderSide(color: Colors.transparent),
					),
					textStyle: textTheme.labelLarge,
				),
			),
			outlinedButtonTheme: OutlinedButtonThemeData(
				style: OutlinedButton.styleFrom(
					foregroundColor: OpenVtsColors.textPrimary,
					minimumSize: const Size(0, OpenVtsSpacing.buttonHeight),
					side: const BorderSide(color: OpenVtsColors.border),
					shape: const RoundedRectangleBorder(
						borderRadius: OpenVtsRadius.radiusMd,
					),
					textStyle: textTheme.labelLarge,
				),
			),
			textButtonTheme: TextButtonThemeData(
				style: TextButton.styleFrom(
					foregroundColor: primary,
					textStyle: textTheme.labelLarge,
				),
			),
			chipTheme: ChipThemeData(
				backgroundColor: OpenVtsColors.surface,
				selectedColor: OpenVtsColors.brandInk.withValues(alpha: 0.1),
				disabledColor: OpenVtsColors.surface,
				padding: const EdgeInsets.symmetric(
					horizontal: OpenVtsSpacing.sm,
					vertical: OpenVtsSpacing.xs,
				),
				side: const BorderSide(color: OpenVtsColors.border),
				shape: const StadiumBorder(),
				labelStyle: textTheme.labelMedium ?? const TextStyle(),
			),
			progressIndicatorTheme: const ProgressIndicatorThemeData(
				color: OpenVtsColors.brandInk,
			),
		);
	}

	static ThemeData dark([Color? brand]) {
		final Color primary = _effectiveBrand(brand, isDark: true);
		final TextTheme textTheme = OpenVtsTypography.textTheme(
			brightness: Brightness.dark,
		);

		final ColorScheme scheme = ColorScheme(
			brightness: Brightness.dark,
			primary: primary,
			onPrimary: OpenVtsColors.brandInk,
			secondary: OpenVtsColors.darkTextSecondary,
			onSecondary: OpenVtsColors.brandInk,
			tertiary: OpenVtsColors.darkTextTertiary,
			onTertiary: OpenVtsColors.brandInk,
			error: OpenVtsColors.danger,
			onError: OpenVtsColors.white,
			surface: OpenVtsColors.darkSurface,
			onSurface: OpenVtsColors.darkTextPrimary,
			outline: OpenVtsColors.darkBorder,
			outlineVariant: OpenVtsColors.darkDivider,
			shadow: const Color(0x66000000),
			scrim: const Color(0x99000000),
			inverseSurface: OpenVtsColors.white,
			onInverseSurface: OpenVtsColors.brandInk,
			inversePrimary: OpenVtsColors.brandInk,
		);

		return ThemeData(
			useMaterial3: true,
			brightness: Brightness.dark,
			fontFamily: OpenVtsTypography.fontFamily,
			colorScheme: scheme,
			primaryColor: primary,
			scaffoldBackgroundColor: OpenVtsColors.darkBackground,
			canvasColor: OpenVtsColors.darkBackground,
			dividerColor: OpenVtsColors.darkDivider,
			textTheme: textTheme,
			appBarTheme: AppBarTheme(
				backgroundColor: OpenVtsColors.darkBackground,
				foregroundColor: OpenVtsColors.darkTextPrimary,
				elevation: 0,
				centerTitle: false,
				titleTextStyle: textTheme.titleLarge,
			),
			cardTheme: CardThemeData(
				color: OpenVtsColors.darkSurface,
				elevation: 0,
				shape: RoundedRectangleBorder(
					borderRadius: OpenVtsRadius.radiusLg,
					side: const BorderSide(color: OpenVtsColors.darkBorder),
				),
				margin: const EdgeInsets.all(OpenVtsSpacing.sm),
			),
			inputDecorationTheme: InputDecorationTheme(
				filled: true,
				fillColor: OpenVtsColors.darkSurface,
				contentPadding: const EdgeInsets.symmetric(
					horizontal: OpenVtsSpacing.lg,
					vertical: OpenVtsSpacing.md,
				),
				hintStyle: textTheme.bodyMedium?.copyWith(
					color: OpenVtsColors.darkTextTertiary,
				),
				labelStyle: textTheme.bodyMedium?.copyWith(
					color: OpenVtsColors.darkTextSecondary,
				),
				enabledBorder: const OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: OpenVtsColors.darkBorder),
				),
				focusedBorder: OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: primary, width: 1.4),
				),
				errorBorder: const OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: OpenVtsColors.danger),
				),
				focusedErrorBorder: const OutlineInputBorder(
					borderRadius: OpenVtsRadius.radiusMd,
					borderSide: BorderSide(color: OpenVtsColors.danger, width: 1.4),
				),
			),
			elevatedButtonTheme: ElevatedButtonThemeData(
				style: ElevatedButton.styleFrom(
					elevation: 0,
					backgroundColor: primary,
					foregroundColor: OpenVtsColors.brandInk,
					minimumSize: const Size(0, OpenVtsSpacing.buttonHeight),
					shape: const RoundedRectangleBorder(
						borderRadius: OpenVtsRadius.radiusMd,
						side: BorderSide(color: Colors.transparent),
					),
					textStyle: textTheme.labelLarge,
				),
			),
			outlinedButtonTheme: OutlinedButtonThemeData(
				style: OutlinedButton.styleFrom(
					foregroundColor: OpenVtsColors.darkTextPrimary,
					minimumSize: const Size(0, OpenVtsSpacing.buttonHeight),
					side: const BorderSide(color: OpenVtsColors.darkBorder),
					shape: const RoundedRectangleBorder(
						borderRadius: OpenVtsRadius.radiusMd,
					),
					textStyle: textTheme.labelLarge,
				),
			),
			textButtonTheme: TextButtonThemeData(
				style: TextButton.styleFrom(
					foregroundColor: primary,
					textStyle: textTheme.labelLarge,
				),
			),
			chipTheme: ChipThemeData(
				backgroundColor: OpenVtsColors.darkSurface,
				selectedColor: OpenVtsColors.white.withValues(alpha: 0.12),
				disabledColor: OpenVtsColors.darkSurface,
				padding: const EdgeInsets.symmetric(
					horizontal: OpenVtsSpacing.sm,
					vertical: OpenVtsSpacing.xs,
				),
				side: const BorderSide(color: OpenVtsColors.darkBorder),
				shape: const StadiumBorder(),
				labelStyle: textTheme.labelMedium ?? const TextStyle(),
			),
			progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
		);
	}

	static Color _effectiveBrand(Color? candidate, {required bool isDark}) {
		final Color fallback = isDark ? defaultDarkBrand : defaultBrand;
		if (candidate == null) {
			return fallback;
		}

		if (!isDark &&
				ThemeData.estimateBrightnessForColor(candidate) == Brightness.light) {
			return fallback;
		}
		return candidate;
	}
}

