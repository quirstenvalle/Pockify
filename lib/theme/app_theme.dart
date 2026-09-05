import 'package:flutter/material.dart';

/// Bundled UI font — same metrics on every Android device.
const String kAppFontFamily = 'NotoSans';

TextStyle? alignTextStyle(TextStyle? style) => style?.copyWith(
  fontFamily: kAppFontFamily,
  letterSpacing: 0,
  height: 1.3,
  leadingDistribution: TextLeadingDistribution.even,
);

TextTheme alignedTextTheme(TextTheme base) {
  final themed = base.apply(
    fontFamily: kAppFontFamily,
    bodyColor: base.bodyMedium?.color,
    displayColor: base.displayMedium?.color,
  );
  return themed.copyWith(
    displayLarge: alignTextStyle(themed.displayLarge),
    displayMedium: alignTextStyle(themed.displayMedium),
    displaySmall: alignTextStyle(themed.displaySmall),
    headlineLarge: alignTextStyle(themed.headlineLarge),
    headlineMedium: alignTextStyle(themed.headlineMedium),
    headlineSmall: alignTextStyle(themed.headlineSmall),
    titleLarge: alignTextStyle(themed.titleLarge),
    titleMedium: alignTextStyle(themed.titleMedium),
    titleSmall: alignTextStyle(themed.titleSmall),
    bodyLarge: alignTextStyle(themed.bodyLarge),
    bodyMedium: alignTextStyle(themed.bodyMedium),
    bodySmall: alignTextStyle(themed.bodySmall),
    labelLarge: alignTextStyle(themed.labelLarge),
    labelMedium: alignTextStyle(themed.labelMedium),
    labelSmall: alignTextStyle(themed.labelSmall),
  );
}

ThemeData buildPockifyTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFFF39A42));
  final textTheme = alignedTextTheme(Typography.material2021().black);

  return ThemeData(
    useMaterial3: true,
    fontFamily: kAppFontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF3F1EB),
    cardColor: const Color(0xFFFDFCFA),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    iconTheme: const IconThemeData(opticalSize: 24),
    cardTheme: CardThemeData(
      color: const Color(0xFFFDFCFA),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      labelStyle: alignTextStyle(
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0EEE9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: alignTextStyle(
        const TextStyle(fontSize: 14, color: Color(0xFF9A958C)),
      ),
      labelStyle: alignTextStyle(const TextStyle(fontSize: 14)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Color(0xFFF39A42)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: alignTextStyle(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: alignTextStyle(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: alignTextStyle(
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    ),
  );
}

/// Caps system font scaling so layout/letter metrics stay predictable on APKs.
Widget pockifyTextScaler(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final clamped = mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);
  return MediaQuery(
    data: mq.copyWith(textScaler: clamped),
    child: DefaultTextStyle(
      style: alignTextStyle(
        const TextStyle(
          fontSize: 14,
          color: Color(0xFF1C1917),
          fontWeight: FontWeight.w400,
        ),
      )!,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
