import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../routing.dart";
import "../../providers/app_locked_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../providers/store_review_provider.dart";
import "../../util/after_frame.dart";
import "../../util/rebuild_when_safe.dart";
import "store_review_gate_dialog.dart";

/// The only route on which the review prompt may appear: the idle home screen.
/// An exact match means nothing is stacked above the dashboard (a session,
/// the success screen, a sub-page), so the prompt never lands mid-flow.
const _homePath = "/home";

/// Watches for the moment the user is back on an idle home screen with enough
/// successful sessions behind them, then shows the sentiment gate once. Sits in
/// `MaterialApp.router`'s builder next to [LockGate] and, like it, listens to
/// the router ([routerProvider]) so it re-checks on every navigation. Does
/// nothing when no store-review service is injected (the F-Droid build).
class StoreReviewGate extends ConsumerStatefulWidget {
  final Widget child;
  const StoreReviewGate({super.key, required this.child});

  @override
  ConsumerState<StoreReviewGate> createState() => _StoreReviewGateState();
}

class _StoreReviewGateState extends ConsumerState<StoreReviewGate>
    with RebuildWhenSafe {
  // Guards against scheduling a second attempt while one is already in flight
  // (the async availability check and the dialog span multiple frames).
  bool _asking = false;

  late final GoRouter _router = ref.read(routerProvider);

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(rebuildWhenSafe);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(rebuildWhenSafe);
    super.dispose();
  }

  Future<void> _maybeAsk() async {
    if (_asking) return;
    final service = ref.read(storeReviewServiceProvider);
    if (service == null) return;

    final prefs = ref.read(preferencesProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!shouldAskForReview(
      done: prefs.reviewDone.value,
      timesAsked: prefs.reviewTimesAsked.value,
      successCount: prefs.reviewSuccessCount.value,
      lastAskEpochMs: prefs.reviewLastAskEpochMs.value,
      nowEpochMs: now,
    )) {
      return;
    }

    _asking = true;
    // Skip entirely when the native review API can't be shown (e.g. Android
    // without Play services) rather than popping a gate that leads nowhere.
    final available = await service.isAvailable();
    if (!available) {
      _asking = false;
      return;
    }

    // Record the ask before showing so a dismiss (tap-outside/back) still
    // counts towards the at-most-two-asks rule.
    await prefs.recordReviewAsked(nowEpochMs: now);

    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await showStoreReviewGateDialog(ctx);
    }
    _asking = false;
  }

  @override
  Widget build(BuildContext context) {
    // The threshold is always crossed mid-session (off /home); the router
    // listener re-runs this build on the return navigation to /home, which is
    // where the prompt is meant to appear anyway.
    final locked = ref.watch(appLockedProvider);

    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (!locked && path == _homePath) {
      afterFrame(() => _maybeAsk());
    }

    return widget.child;
  }
}
