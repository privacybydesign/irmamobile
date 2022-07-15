import 'package:flutter/widgets.dart';

extension Tablet on BuildContext {
  // 600 is a common breakpoint for a typical 7-inch tablet
  bool get isTabletDevice {
    var shortestSide = MediaQuery.of(this).size.shortestSide;
    return shortestSide > 600;
  }
}
