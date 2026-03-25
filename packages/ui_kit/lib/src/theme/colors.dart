import 'package:flutter/material.dart';

/// Semantic and core color tokens for GreenLeaf Theme.
class GLColors {
  // Primary (Eco-friendly Green Palette)
  static const Color primaryLight = Color(0xFF2E7D32); // Green 800
  static const Color primaryDark = Color(0xFF66BB6A);  // Green 400
  
  static const Color primaryContainerLight = Color(0xFFA5D6A7);
  static const Color primaryContainerDark = Color(0xFF1B5E20);

  // Semantic Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Background and Surfaces — Light
  static const Color backgroundLight = Color(0xFFF1F8E9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1E1E1E);

  // Background and Surfaces — Dark
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFE0E0E0);
}

/// Helper building Material 3 ColorSchemes based on the tokens.
class GLColorScheme {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: GLColors.primaryLight,
    onPrimary: Colors.white,
    primaryContainer: GLColors.primaryContainerLight,
    onPrimaryContainer: Colors.black87,
    secondary: GLColors.success,
    onSecondary: Colors.white,
    error: GLColors.error,
    onError: Colors.white,
    surface: GLColors.surfaceLight,
    onSurface: GLColors.onSurfaceLight,
    // Provide explicit fallback for Material 3 requirements
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: GLColors.primaryDark,
    onPrimary: Colors.black87,
    primaryContainer: GLColors.primaryContainerDark,
    onPrimaryContainer: Colors.white,
    secondary: GLColors.success,
    onSecondary: Colors.black87,
    error: GLColors.error,
    onError: Colors.black87,
    surface: GLColors.surfaceDark,
    onSurface: GLColors.onSurfaceDark,
  );
}
