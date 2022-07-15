import 'package:flutter/widgets.dart';

import 'scale.dart';

extension Tablet on BuildContext {
  // 600 is a common breakpoint for a typical 7-inch tablet
  bool get isTabletDevice {
    var side = shortestSide(this);
    return side > 600;
  }
}
