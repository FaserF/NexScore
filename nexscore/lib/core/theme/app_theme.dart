import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFFEC4899); // Pink
  static const Color accent = Color(0xFF14B8A6); // Teal

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textLight = Color(0xFF334155);
  static const Color textDark = Color(0xFFF8FAFC);

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: primary,
        primaryContainer: Color(0xFFE0E7FF),
        secondary: secondary,
        secondaryContainer: Color(0xFFFCE7F3),
        tertiary: accent,
        tertiaryContainer: Color(0xFFCCFBF1),
        appBarColor: surfaceLight,
        error: Color(0xFFEF4444),
      ),
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 2,
      appBarStyle: FlexAppBarStyle.background,
      appBarOpacity: 0.95,
      transparentStatusBar: true,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      swapColors: false,
      lightIsWhite: true,
      scaffoldBackground: backgroundLight,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 24.0,
        cardRadius: 24.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimary,
        elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        toggleButtonsBorderSchemeColor: SchemeColor.primary,
        segmentedButtonSchemeColor: SchemeColor.primary,
        segmentedButtonBorderSchemeColor: SchemeColor.primary,
        unselectedToggleIsColored: true,
        sliderValueTinted: true,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBackgroundAlpha: 15,
        inputDecoratorUnfocusedHasBorder: false,
        inputDecoratorFocusedBorderWidth: 2.0,
        inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
        fabUseShape: true,
        fabAlwaysCircular: true,
        fabSchemeColor: SchemeColor.tertiary,
        popupMenuRadius: 16.0,
        popupMenuElevation: 8.0,
        dialogRadius: 28.0,
        dialogElevation: 10.0,
        timePickerDialogRadius: 28.0,
        bottomSheetRadius: 28.0,
        bottomSheetElevation: 10.0,
        bottomSheetModalElevation: 10.0,
        bottomNavigationBarElevation: 0.0,
        bottomNavigationBarOpacity: 0.95,
        navigationBarIndicatorOpacity: 0.20,
        navigationBarOpacity: 0.95,
        navigationRailIndicatorOpacity: 0.20,
        navigationRailOpacity: 0.95,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: primary,
        primaryContainer: Color(0xFF3730A3),
        secondary: secondary,
        secondaryContainer: Color(0xFF831843),
        tertiary: accent,
        tertiaryContainer: Color(0xFF115E59),
        appBarColor: surfaceDark,
        error: Color(0xFFEF4444),
      ),
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 15,
      appBarStyle: FlexAppBarStyle.background,
      appBarOpacity: 0.90,
      transparentStatusBar: true,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      swapColors: false,
      darkIsTrueBlack: false,
      scaffoldBackground: backgroundDark,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        defaultRadius: 24.0,
        cardRadius: 24.0,
        elevatedButtonSchemeColor: SchemeColor.onPrimary,
        elevatedButtonSecondarySchemeColor: SchemeColor.primary,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
        toggleButtonsBorderSchemeColor: SchemeColor.primary,
        segmentedButtonSchemeColor: SchemeColor.primary,
        segmentedButtonBorderSchemeColor: SchemeColor.primary,
        unselectedToggleIsColored: true,
        sliderValueTinted: true,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBackgroundAlpha: 22,
        inputDecoratorUnfocusedHasBorder: false,
        inputDecoratorFocusedBorderWidth: 2.0,
        inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
        fabUseShape: true,
        fabAlwaysCircular: true,
        fabSchemeColor: SchemeColor.tertiary,
        popupMenuRadius: 16.0,
        popupMenuElevation: 8.0,
        dialogRadius: 28.0,
        dialogElevation: 10.0,
        timePickerDialogRadius: 28.0,
        bottomSheetRadius: 28.0,
        bottomSheetElevation: 10.0,
        bottomSheetModalElevation: 10.0,
        bottomNavigationBarElevation: 0.0,
        bottomNavigationBarOpacity: 0.90,
        navigationBarIndicatorOpacity: 0.20,
        navigationBarOpacity: 0.90,
        navigationRailIndicatorOpacity: 0.20,
        navigationRailOpacity: 0.90,
      ),
      useMaterial3: true,
    );
  }
}
