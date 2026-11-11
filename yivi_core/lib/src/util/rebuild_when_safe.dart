import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

import "after_frame.dart";

/// For a State that rebuilds when something it listens to changes (the
/// router, in the gates around the app).
mixin RebuildWhenSafe<T extends StatefulWidget> on State<T> {
  /// Rebuilds now when that is allowed, else after this frame.
  ///
  /// Notifications fired during build (the Router's initial route
  /// configuration, some GoRouterDelegate paths) can't call setState
  /// directly without throwing: those wait for the frame to end. Anything
  /// fired while idle (user navigation, test-driven pushes) rebuilds now, so
  /// the gate matches the new route on the same frame.
  void rebuildWhenSafe() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(() {});
    } else {
      afterFrame(() => setState(() {}));
    }
  }
}
