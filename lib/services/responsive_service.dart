import 'package:flutter/material.dart';

class ResponsiveService {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) return baseFontSize;
    if (isTablet(context)) return baseFontSize * 1.1;
    return baseFontSize * 1.2;
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    if (isMobile(context)) return baseIconSize;
    if (isTablet(context)) return baseIconSize * 1.2;
    return baseIconSize * 1.4;
  }

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth * 0.9;
    if (isTablet(context)) return screenWidth * 0.7;
    return screenWidth * 0.5;
  }

  /// Get responsive navigation type
  static NavigationType getNavigationType(BuildContext context) {
    if (isMobile(context)) return NavigationType.bottomNavigation;
    if (isTablet(context)) return NavigationType.navigationRail;
    return NavigationType.navigationDrawer;
  }

  /// Get responsive layout for marketplace
  static Widget getResponsiveMarketplaceLayout({
    required BuildContext context,
    required List<Widget> items,
  }) {
    if (isMobile(context)) {
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      );
    } else {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getGridColumns(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isDesktop(context) ? 1.2 : 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      );
    }
  }

  /// Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth * 0.9;
    if (isTablet(context)) return 500;
    return 600;
  }

  /// Get responsive app bar height
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) return kToolbarHeight;
    return kToolbarHeight * 1.2;
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

enum NavigationType {
  bottomNavigation,
  navigationRail,
  navigationDrawer,
}