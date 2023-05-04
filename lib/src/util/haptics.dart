import 'package:flutter/services.dart';

extension Haptic<P, R> on R Function(P) {
  R Function(P) get haptic => (P p) {
        HapticFeedback.lightImpact();
        return this(p);
      };
}

extension HapticVoid on VoidCallback {
  VoidCallback get haptic => () {
        HapticFeedback.lightImpact();
        this();
      };
}
