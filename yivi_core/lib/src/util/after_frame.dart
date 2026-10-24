import "package:flutter/widgets.dart";

extension AfterFrame on State {
  /// Runs [callback] once this frame is done, if this State is still there.
  void afterFrame(VoidCallback callback) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) callback();
      });
}
