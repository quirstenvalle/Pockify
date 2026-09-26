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
  const neutral = Color(0xFF111827);
  const slate = Color(0xFF5B6472);
  const mist = Color(0xFFF3F5F4);
  const card = Color(0xFFFFFFFF);
  const softBorder = Color(0xFFE7E9E5);
  const accent = Color(0xFF2E7D67);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: neutral,
    brightness: Brightness.light,
    primary: neutral,
    secondary: accent,
    surface: card,
  );
  final textTheme = alignedTextTheme(Typography.material2021().black);

  return ThemeData(
    useMaterial3: true,
    fontFamily: kAppFontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: mist,
    cardColor: card,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    dividerColor: softBorder,
    iconTheme: const IconThemeData(opticalSize: 22, color: neutral),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: softBorder, width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: alignTextStyle(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: mist,
      side: const BorderSide(color: softBorder),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9FAF9),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: alignTextStyle(
        const TextStyle(fontSize: 14, color: Color(0xFF7B818A)),
      ),
      labelStyle: alignTextStyle(const TextStyle(fontSize: 14, color: neutral)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: softBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: softBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: neutral, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: neutral,
        textStyle: alignTextStyle(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: neutral,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: alignTextStyle(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: neutral),
      titleTextStyle: alignTextStyle(
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: neutral,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hintColor: slate,
    primaryColor: neutral,
  );
}

/// Caps system font scaling so layout/letter metrics stay predictable on APKs.
Widget pockifyTextScaler(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final clamped = mq.textScaler.clamp(
    minScaleFactor: 0.9,
    maxScaleFactor: 1.15,
  );
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
