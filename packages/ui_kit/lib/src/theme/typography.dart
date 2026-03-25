import 'package:flutter/material.dart';

/// Central Typography system for GreenLeaf apps.
/// Relies on system default font families mapping natively correctly onto Android
/// enabling default native Malayalam rendering.
class GLTypography {
  static const String _fontFamily = 'System'; // Relies on natively supported sans.

  static TextTheme get textTheme {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        height: 1.25, // For legibility across scripts
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        height: 1.5, // Important for complex Malayalam glyphs
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}
