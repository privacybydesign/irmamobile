import 'package:flutter/widgets.dart';

/// current ux-2.0 designs at set at viewport width of 375px
const designScreenWidth = 375.0;

/// For non-tablet devices:
/// afaik (2022), the smallest viewport width is iPhone 5 at 320,
/// the largest viewport width is samsung z fold / iPhone xs max at 414 * 2
/// Scaling stops beyond non-mobile phone devices.
const _smallestViewportWidth = 320.0 / designScreenWidth;
const _largestViewportWidth = 414.0 / designScreenWidth;

double shortestSide(BuildContext context) => MediaQuery.of(context).size.shortestSide;

extension YiviDesignDouble on double {
  double scaleToDesignSize(BuildContext context) {
    final factor = shortestSide(context) / designScreenWidth;
    return this * factor.clamp(_smallestViewportWidth, _largestViewportWidth);
  }
}

extension YiviDesignInt on int {
  double scaleToDesignSize(BuildContext context) {
    final factor = shortestSide(context) / designScreenWidth;
    return this * factor.clamp(_smallestViewportWidth, _largestViewportWidth);
  }
}
