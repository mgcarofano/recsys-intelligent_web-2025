/*

	theme.dart
	by MARIO GABRIELE CAROFANO and OLEKSANDR SOSOVSKYY.

	Questo file contiene la definizione del tema dell'applicazione, inclusi i
  colori, i font e gli stili di testo.

*/

// ignore_for_file: file_names
// ignore_for_file: curly_braces_in_flow_control_structures

//	############################################################################
//	LIBRERIE

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//	############################################################################
//	COSTANTI e VARIABILI

//	############################################################################
//	ALTRI METODI

TextTheme createTextTheme(
  BuildContext context,
  String bodyFontString,
  String displayFontString,
) {
  TextTheme baseTextTheme = Theme.of(context).textTheme;
  TextTheme bodyTextTheme = GoogleFonts.getTextTheme(
    bodyFontString,
    baseTextTheme,
  );
  TextTheme displayTextTheme = GoogleFonts.getTextTheme(
    displayFontString,
    baseTextTheme,
  );
  TextTheme textTheme = displayTextTheme.copyWith(
    bodyLarge: bodyTextTheme.bodyLarge,
    bodyMedium: bodyTextTheme.bodyMedium,
    bodySmall: bodyTextTheme.bodySmall,
    labelLarge: bodyTextTheme.labelLarge,
    labelMedium: bodyTextTheme.labelMedium,
    labelSmall: bodyTextTheme.labelSmall,
  );
  return textTheme;
}

//	############################################################################
//	CLASSI e ROUTE

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff605690),
      surfaceTint: Color(0xff605690),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe6deff),
      onPrimaryContainer: Color(0xff483f77),
      secondary: Color(0xff605c71),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe6dff9),
      onSecondaryContainer: Color(0xff484459),
      tertiary: Color(0xff7c5263),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffd8e6),
      onTertiaryContainer: Color(0xff623b4c),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffdf8ff),
      onSurface: Color(0xff1c1b20),
      onSurfaceVariant: Color(0xff48454e),
      outline: Color(0xff79757f),
      outlineVariant: Color(0xffc9c4d0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff312f36),
      inversePrimary: Color(0xffcabeff),
      primaryFixed: Color(0xffe6deff),
      onPrimaryFixed: Color(0xff1c1149),
      primaryFixedDim: Color(0xffcabeff),
      onPrimaryFixedVariant: Color(0xff483f77),
      secondaryFixed: Color(0xffe6dff9),
      onSecondaryFixed: Color(0xff1c192b),
      secondaryFixedDim: Color(0xffc9c3dc),
      onSecondaryFixedVariant: Color(0xff484459),
      tertiaryFixed: Color(0xffffd8e6),
      onTertiaryFixed: Color(0xff301120),
      tertiaryFixedDim: Color(0xffedb8cc),
      onTertiaryFixedVariant: Color(0xff623b4c),
      surfaceDim: Color(0xffddd8e0),
      surfaceBright: Color(0xfffdf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2fa),
      surfaceContainer: Color(0xfff1ecf4),
      surfaceContainerHigh: Color(0xffebe6ee),
      surfaceContainerHighest: Color(0xffe6e1e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff372e65),
      surfaceTint: Color(0xff605690),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6f65a0),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff373447),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff6f6a80),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff4f2b3b),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff8c6072),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf8ff),
      onSurface: Color(0xff121016),
      onSurfaceVariant: Color(0xff37353e),
      outline: Color(0xff54515a),
      outlineVariant: Color(0xff6f6b75),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff312f36),
      inversePrimary: Color(0xffcabeff),
      primaryFixed: Color(0xff6f65a0),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff564d86),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff6f6a80),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff565267),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff8c6072),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff71495a),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc9c5cd),
      surfaceBright: Color(0xfffdf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f2fa),
      surfaceContainer: Color(0xffebe6ee),
      surfaceContainerHigh: Color(0xffe0dbe3),
      surfaceContainerHighest: Color(0xffd4d0d8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff2d235a),
      surfaceTint: Color(0xff605690),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff4b4179),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff2d2a3d),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff4a465b),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff442131),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff653d4e),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffdf8ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff2d2b33),
      outlineVariant: Color(0xff4a4851),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff312f36),
      inversePrimary: Color(0xffcabeff),
      primaryFixed: Color(0xff4b4179),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff342a61),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff4a465b),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff343044),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff653d4e),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff4b2737),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbbb7bf),
      surfaceBright: Color(0xfffdf8ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff4eff7),
      surfaceContainer: Color(0xffe6e1e9),
      surfaceContainerHigh: Color(0xffd7d3db),
      surfaceContainerHighest: Color(0xffc9c5cd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcabeff),
      surfaceTint: Color(0xffcabeff),
      onPrimary: Color(0xff31285f),
      primaryContainer: Color(0xff483f77),
      onPrimaryContainer: Color(0xffe6deff),
      secondary: Color(0xffc9c3dc),
      onSecondary: Color(0xff312e41),
      secondaryContainer: Color(0xff484459),
      onSecondaryContainer: Color(0xffe6dff9),
      tertiary: Color(0xffedb8cc),
      onTertiary: Color(0xff492535),
      tertiaryContainer: Color(0xff623b4c),
      onTertiaryContainer: Color(0xffffd8e6),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff141318),
      onSurface: Color(0xffe6e1e9),
      onSurfaceVariant: Color(0xffc9c4d0),
      outline: Color(0xff938f99),
      outlineVariant: Color(0xff48454e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe6e1e9),
      inversePrimary: Color(0xff605690),
      primaryFixed: Color(0xffe6deff),
      onPrimaryFixed: Color(0xff1c1149),
      primaryFixedDim: Color(0xffcabeff),
      onPrimaryFixedVariant: Color(0xff483f77),
      secondaryFixed: Color(0xffe6dff9),
      onSecondaryFixed: Color(0xff1c192b),
      secondaryFixedDim: Color(0xffc9c3dc),
      onSecondaryFixedVariant: Color(0xff484459),
      tertiaryFixed: Color(0xffffd8e6),
      onTertiaryFixed: Color(0xff301120),
      tertiaryFixedDim: Color(0xffedb8cc),
      onTertiaryFixedVariant: Color(0xff623b4c),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff3a383e),
      surfaceContainerLowest: Color(0xff0f0d13),
      surfaceContainerLow: Color(0xff1c1b20),
      surfaceContainer: Color(0xff201f25),
      surfaceContainerHigh: Color(0xff2b292f),
      surfaceContainerHighest: Color(0xff36343a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffe0d7ff),
      surfaceTint: Color(0xffcabeff),
      onPrimary: Color(0xff261c53),
      primaryContainer: Color(0xff9389c6),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffe0d9f2),
      onSecondary: Color(0xff262336),
      secondaryContainer: Color(0xff938ea5),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffffd0e1),
      onTertiary: Color(0xff3c1b2a),
      tertiaryContainer: Color(0xffb38396),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff141318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdfdae6),
      outline: Color(0xffb4b0bb),
      outlineVariant: Color(0xff928f99),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe6e1e9),
      inversePrimary: Color(0xff494078),
      primaryFixed: Color(0xffe6deff),
      onPrimaryFixed: Color(0xff11043e),
      primaryFixedDim: Color(0xffcabeff),
      onPrimaryFixedVariant: Color(0xff372e65),
      secondaryFixed: Color(0xffe6dff9),
      onSecondaryFixed: Color(0xff120f20),
      secondaryFixedDim: Color(0xffc9c3dc),
      onSecondaryFixedVariant: Color(0xff373447),
      tertiaryFixed: Color(0xffffd8e6),
      onTertiaryFixed: Color(0xff240615),
      tertiaryFixedDim: Color(0xffedb8cc),
      onTertiaryFixedVariant: Color(0xff4f2b3b),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff45434a),
      surfaceContainerLowest: Color(0xff08070c),
      surfaceContainerLow: Color(0xff1e1d22),
      surfaceContainer: Color(0xff29272d),
      surfaceContainerHigh: Color(0xff333238),
      surfaceContainerHighest: Color(0xff3f3d43),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xfff3edff),
      surfaceTint: Color(0xffcabeff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffc6bafb),
      onPrimaryContainer: Color(0xff0b0036),
      secondary: Color(0xfff3edff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffc5bfd8),
      onSecondaryContainer: Color(0xff0c091a),
      tertiary: Color(0xffffebf0),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffe9b4c8),
      onTertiaryContainer: Color(0xff1c020f),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff141318),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xfff3eef9),
      outlineVariant: Color(0xffc5c1cc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe6e1e9),
      inversePrimary: Color(0xff494078),
      primaryFixed: Color(0xffe6deff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffcabeff),
      onPrimaryFixedVariant: Color(0xff11043e),
      secondaryFixed: Color(0xffe6dff9),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffc9c3dc),
      onSecondaryFixedVariant: Color(0xff120f20),
      tertiaryFixed: Color(0xffffd8e6),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffedb8cc),
      onTertiaryFixedVariant: Color(0xff240615),
      surfaceDim: Color(0xff141318),
      surfaceBright: Color(0xff514f56),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff201f25),
      surfaceContainer: Color(0xff312f36),
      surfaceContainerHigh: Color(0xff3c3a41),
      surfaceContainerHighest: Color(0xff48464c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.background,
    canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}

//	############################################################################
//	RIFERIMENTI

//  https://api.flutter.dev/flutter/material/TextTheme-class.html
