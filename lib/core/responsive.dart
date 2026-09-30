import 'package:flutter/material.dart';

enum AppDeviceType {
  phone,
  tablet,
  largeTablet,
}

enum AppScreenMode {
  phonePortrait,
  phoneLandscape,
  tabletPortrait,
  tabletLandscape,
  largeTabletPortrait,
  largeTabletLandscape,
}

class AppResponsive {
  final BuildContext context;
  final Size size;
  final Orientation orientation;

  const AppResponsive._({
    required this.context,
    required this.size,
    required this.orientation,
  });

  factory AppResponsive.of(BuildContext context) {
    final media = MediaQuery.of(context);

    return AppResponsive._(
      context: context,
      size: media.size,
      orientation: media.orientation,
    );
  }

  double get width => size.width;
  double get height => size.height;

  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  bool get isPhone => shortestSide < 600;
  bool get isTablet => shortestSide >= 600 && shortestSide < 900;
  bool get isLargeTablet => shortestSide >= 900;

  double get shortestSide => size.shortestSide;
  double get longestSide => size.longestSide;

  AppDeviceType get deviceType {
    if (isLargeTablet) return AppDeviceType.largeTablet;
    if (isTablet) return AppDeviceType.tablet;
    return AppDeviceType.phone;
  }

  AppScreenMode get screenMode {
    if (isLargeTablet && isLandscape) {
      return AppScreenMode.largeTabletLandscape;
    }

    if (isLargeTablet && isPortrait) {
      return AppScreenMode.largeTabletPortrait;
    }

    if (isTablet && isLandscape) {
      return AppScreenMode.tabletLandscape;
    }

    if (isTablet && isPortrait) {
      return AppScreenMode.tabletPortrait;
    }

    if (isPhone && isLandscape) {
      return AppScreenMode.phoneLandscape;
    }

    return AppScreenMode.phonePortrait;
  }

  bool get useCompactLayout {
    return screenMode == AppScreenMode.phonePortrait;
  }

  bool get useWideLayout {
    return isLandscape || isTablet || isLargeTablet;
  }

  bool get useTwoColumnLayout {
    return isTabletLandscape || isLargeTabletLandscape;
  }

  bool get isTabletLandscape {
    return isTablet && isLandscape;
  }

  bool get isLargeTabletLandscape {
    return isLargeTablet && isLandscape;
  }

  double get horizontalPadding {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return 16;
      case AppScreenMode.phoneLandscape:
        return 22;
      case AppScreenMode.tabletPortrait:
        return 28;
      case AppScreenMode.tabletLandscape:
        return 34;
      case AppScreenMode.largeTabletPortrait:
        return 36;
      case AppScreenMode.largeTabletLandscape:
        return 44;
    }
  }

  double get verticalPadding {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return 14;
      case AppScreenMode.phoneLandscape:
        return 10;
      case AppScreenMode.tabletPortrait:
        return 20;
      case AppScreenMode.tabletLandscape:
        return 16;
      case AppScreenMode.largeTabletPortrait:
        return 24;
      case AppScreenMode.largeTabletLandscape:
        return 18;
    }
  }

  double get maxContentWidth {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return width;
      case AppScreenMode.phoneLandscape:
        return 720;
      case AppScreenMode.tabletPortrait:
        return 760;
      case AppScreenMode.tabletLandscape:
        return 1040;
      case AppScreenMode.largeTabletPortrait:
        return 900;
      case AppScreenMode.largeTabletLandscape:
        return 1180;
    }
  }

  double get appBarHeight {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return 64;
      case AppScreenMode.phoneLandscape:
        return 52;
      case AppScreenMode.tabletPortrait:
        return 72;
      case AppScreenMode.tabletLandscape:
        return 58;
      case AppScreenMode.largeTabletPortrait:
        return 78;
      case AppScreenMode.largeTabletLandscape:
        return 62;
    }
  }

  int gridCount({
    int phonePortrait = 2,
    int phoneLandscape = 4,
    int tabletPortrait = 3,
    int tabletLandscape = 4,
    int largeTabletPortrait = 4,
    int largeTabletLandscape = 5,
  }) {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return phonePortrait;
      case AppScreenMode.phoneLandscape:
        return phoneLandscape;
      case AppScreenMode.tabletPortrait:
        return tabletPortrait;
      case AppScreenMode.tabletLandscape:
        return tabletLandscape;
      case AppScreenMode.largeTabletPortrait:
        return largeTabletPortrait;
      case AppScreenMode.largeTabletLandscape:
        return largeTabletLandscape;
    }
  }

  double gridAspectRatio({
    double phonePortrait = 0.95,
    double phoneLandscape = 1.45,
    double tabletPortrait = 1.05,
    double tabletLandscape = 1.55,
    double largeTabletPortrait = 1.15,
    double largeTabletLandscape = 1.75,
  }) {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return phonePortrait;
      case AppScreenMode.phoneLandscape:
        return phoneLandscape;
      case AppScreenMode.tabletPortrait:
        return tabletPortrait;
      case AppScreenMode.tabletLandscape:
        return tabletLandscape;
      case AppScreenMode.largeTabletPortrait:
        return largeTabletPortrait;
      case AppScreenMode.largeTabletLandscape:
        return largeTabletLandscape;
    }
  }

  double textScale({
    double phonePortrait = 1,
    double phoneLandscape = 0.92,
    double tabletPortrait = 1.08,
    double tabletLandscape = 1,
    double largeTabletPortrait = 1.15,
    double largeTabletLandscape = 1.08,
  }) {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return phonePortrait;
      case AppScreenMode.phoneLandscape:
        return phoneLandscape;
      case AppScreenMode.tabletPortrait:
        return tabletPortrait;
      case AppScreenMode.tabletLandscape:
        return tabletLandscape;
      case AppScreenMode.largeTabletPortrait:
        return largeTabletPortrait;
      case AppScreenMode.largeTabletLandscape:
        return largeTabletLandscape;
    }
  }

  double clampDouble({
    required double value,
    required double min,
    required double max,
  }) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  double responsiveValue({
    required double phonePortrait,
    required double phoneLandscape,
    required double tabletPortrait,
    required double tabletLandscape,
    required double largeTabletPortrait,
    required double largeTabletLandscape,
  }) {
    switch (screenMode) {
      case AppScreenMode.phonePortrait:
        return phonePortrait;
      case AppScreenMode.phoneLandscape:
        return phoneLandscape;
      case AppScreenMode.tabletPortrait:
        return tabletPortrait;
      case AppScreenMode.tabletLandscape:
        return tabletLandscape;
      case AppScreenMode.largeTabletPortrait:
        return largeTabletPortrait;
      case AppScreenMode.largeTabletLandscape:
        return largeTabletLandscape;
    }
  }
}

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? r.maxContentWidth,
        ),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: r.horizontalPadding,
                vertical: r.verticalPadding,
              ),
          child: child,
        ),
      ),
    );
  }
}

class ResponsiveGridDelegate {
  ResponsiveGridDelegate._();

  static SliverGridDelegateWithFixedCrossAxisCount cards(
      BuildContext context, {
        int phonePortrait = 2,
        int phoneLandscape = 4,
        int tabletPortrait = 3,
        int tabletLandscape = 4,
        int largeTabletPortrait = 4,
        int largeTabletLandscape = 5,
        double spacing = 16,
        double? aspectRatio,
      }) {
    final r = AppResponsive.of(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: r.gridCount(
        phonePortrait: phonePortrait,
        phoneLandscape: phoneLandscape,
        tabletPortrait: tabletPortrait,
        tabletLandscape: tabletLandscape,
        largeTabletPortrait: largeTabletPortrait,
        largeTabletLandscape: largeTabletLandscape,
      ),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio ?? r.gridAspectRatio(),
    );
  }
}