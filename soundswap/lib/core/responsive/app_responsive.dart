import 'package:flutter/material.dart';

enum AppWindowSize { small, medium, large }

class AppResponsive {
  const AppResponsive._();

  // Windows desktop breakpoints tuned for narrow, standard, and wide app
  // windows. Keep all layout decisions tied to these values.
  static const double smallBreakpoint = 700;
  static const double largeBreakpoint = 1100;

  static AppWindowSize windowSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < smallBreakpoint) {
      return AppWindowSize.small;
    }
    if (width < largeBreakpoint) {
      return AppWindowSize.medium;
    }
    return AppWindowSize.large;
  }

  static bool isSmall(BuildContext context) =>
      windowSize(context) == AppWindowSize.small;

  static bool isMedium(BuildContext context) =>
      windowSize(context) == AppWindowSize.medium;

  static bool isLarge(BuildContext context) =>
      windowSize(context) == AppWindowSize.large;

  static double horizontalPadding(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 16,
      AppWindowSize.medium => 20,
      AppWindowSize.large => 28,
    };
  }

  static double verticalPadding(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 14,
      AppWindowSize.medium => 18,
      AppWindowSize.large => 24,
    };
  }

  static double maxContentWidth(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => double.infinity,
      AppWindowSize.medium => 1040,
      AppWindowSize.large => 1440,
    };
  }

  static double cardGap(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 12,
      AppWindowSize.medium => 16,
      AppWindowSize.large => 20,
    };
  }

  static double cardRadius(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 8,
      AppWindowSize.medium => 8,
      AppWindowSize.large => 10,
    };
  }

  static double iconSize(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 20,
      AppWindowSize.medium => 22,
      AppWindowSize.large => 24,
    };
  }

  static double titleSize(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 22,
      AppWindowSize.medium => 25,
      AppWindowSize.large => 28,
    };
  }

  static double bodySize(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 13,
      AppWindowSize.medium => 14,
      AppWindowSize.large => 15,
    };
  }

  static double buttonHeight(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 40,
      AppWindowSize.medium => 42,
      AppWindowSize.large => 44,
    };
  }

  static double sidebarWidth(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => double.infinity,
      AppWindowSize.medium => 340,
      AppWindowSize.large => 410,
    };
  }

  // Fixed-format panels use these heights so short desktop windows remain
  // predictable while their inner content can scroll.
  static double queuePanelHeight(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 420,
      AppWindowSize.medium => double.infinity,
      AppWindowSize.large => double.infinity,
    };
  }

  static double debugPanelHeight(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 420,
      AppWindowSize.medium => 340,
      AppWindowSize.large => 360,
    };
  }

  static double debugLogHeight(BuildContext context) {
    return switch (windowSize(context)) {
      AppWindowSize.small => 180,
      AppWindowSize.medium => 150,
      AppWindowSize.large => 170,
    };
  }

}

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppResponsive.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppResponsive.horizontalPadding(context),
        vertical: AppResponsive.verticalPadding(context),
      ),
      child: child,
    );
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.small,
    required this.medium,
    required this.large,
    super.key,
  });

  final Widget small;
  final Widget medium;
  final Widget large;

  @override
  Widget build(BuildContext context) {
    return switch (AppResponsive.windowSize(context)) {
      AppWindowSize.small => small,
      AppWindowSize.medium => medium,
      AppWindowSize.large => large,
    };
  }
}
