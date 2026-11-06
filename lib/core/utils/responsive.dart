import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Helper utility for detecting screen types and building responsive UI.
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// True when screen width is below [AppConstants.tabletBreakpoint] (< 700px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.tabletBreakpoint;

  /// True when screen width is between tablet and desktop breakpoints (700px - 1100px)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint &&
      MediaQuery.of(context).size.width < AppConstants.desktopBreakpoint;

  /// True when screen width is desktop-sized (>= 1100px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    if (width >= AppConstants.desktopBreakpoint) {
      return desktop;
    } else if (width >= AppConstants.tabletBreakpoint && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
