import 'dart:math';

import 'package:flutter/widgets.dart';

/// current ux-2.0 designs at set at viewport width of 375px
const designScreenWidth = 375.0;

/// For non-tablet devices:
/// afaik (2022), the smallest viewport width is iPhone 5 at 320,
/// the largest viewport width is samsung z fold / iPhone xs max at 414 * 2
const _smallestViewportWidth = 320.0 / designScreenWidth;
const _largestViewportWidth = 414.0 / designScreenWidth;

double _minimumDeviceViewportWidth(BuildContext context) =>
    min<double>(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);

extension YiviDesignDouble on double {
  double scale(BuildContext context) {
    final factor = _minimumDeviceViewportWidth(context) / designScreenWidth;
    return this * factor.clamp(_smallestViewportWidth, _largestViewportWidth);
  }
}

extension YiviDesignInt on int {
  double scale(BuildContext context) {
    final factor = _minimumDeviceViewportWidth(context) / designScreenWidth;
    return this * factor.clamp(_smallestViewportWidth, _largestViewportWidth);
  }
}
