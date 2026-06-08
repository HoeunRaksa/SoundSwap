import 'package:flutter/widgets.dart';

class AppResponsive {
  const AppResponsive._();

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 900;
  }

  static double pagePadding(BuildContext context) {
    return isCompact(context) ? 16 : 24;
  }
}
