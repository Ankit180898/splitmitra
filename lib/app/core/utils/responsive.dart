import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 650 && 
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1100;

  static double getWidth(BuildContext context) => 
      MediaQuery.of(context).size.width;

  static double getHeight(BuildContext context) => 
      MediaQuery.of(context).size.height;

  // Get responsive value based on screen size
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // Get responsive padding
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
      vertical: getResponsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }

  // Get responsive spacing
  static double getSpacing(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 24.0,
    );
  }

  // Get responsive border radius
  static double getBorderRadius(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  // Get responsive column count for grid layouts
  static int getColumnCount(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  // Get responsive font size scale
  static double getFontScale(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
    );
  }

  // Get responsive widget for different screen sizes
  static Widget getResponsiveWidget({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Get responsive max width constraint
  static double getMaxWidth(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 650.0,
      desktop: 1200.0,
    );
  }

  // Check if the device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}