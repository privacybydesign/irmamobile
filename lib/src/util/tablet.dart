import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

extension Tablet on BuildContext {
  // 600 a common breakpoint for a typical 7-inch tablet.
  bool get isTabletDevice {
    var shortestSide = MediaQuery.of(this).size.shortestSide;
    if (kDebugMode) {
      print('shortest edge: $shortestSide');
    }
    return shortestSide > 600;
  }
}
