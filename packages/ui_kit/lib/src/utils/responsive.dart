import 'package:flutter/material.dart';

/// Standard breakpoints for GreenLoop applications.
class GLBreakpoints {
  static const double mobile = 600.0;
  static const double tablet = 1024.0;
  static const double desktop = 1440.0;
}

/// A utility widget to build different layouts based on screen size.
class GLResponsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const GLResponsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Static helper to check screen size anywhere in the build context.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < GLBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= GLBreakpoints.mobile &&
      MediaQuery.of(context).size.width < GLBreakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= GLBreakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width >= GLBreakpoints.tablet) {
      return desktop;
    } else if (width >= GLBreakpoints.mobile && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
