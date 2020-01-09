import 'package:flutter/widgets.dart';

class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState get() {
    return navigatorKey.currentState;
  }
}
