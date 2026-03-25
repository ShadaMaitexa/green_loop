import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

/// The core ThemeData provider for GreenLoop Applications.
class GreenLeafTheme {
  /// Applies GreenLeaf Light Theme
  static ThemeData light() {
    final colorScheme = GLColorScheme.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface, // Better mapped via Material 3 standard than hardcoded colors
      textTheme: GLTypography.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      // Component defaults
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: GLElevation.low,
      ),
    );
  }

  /// Applies GreenLeaf Dark Theme
  static ThemeData dark() {
    final colorScheme = GLColorScheme.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GLTypography.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        elevation: GLElevation.none,
      ),
    );
  }
}
