import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../routing.dart";
import "../providers/app_locked_provider.dart";
import "../providers/preferences_provider.dart";
import "../providers/store_review_provider.dart";
import "../screens/review/store_review_gate_dialog.dart";

/// The only route on which the review prompt may appear: the idle home screen.
/// An exact match means nothing is stacked above the dashboard (a session,
/// the success screen, a sub-page), so the prompt never lands mid-flow.
const _homePath = "/home";

/// Watches for the moment the user is back on an idle home screen with enough
/// successful sessions behind them, then shows the sentiment gate once. Sits in
/// `MaterialApp.router`'s builder next to [LockGate] and, like it, listens to
/// the router so it re-checks on every navigation. Does nothing when no
/// store-review service is injected (the F-Droid build).
class StoreReviewGate extends ConsumerStatefulWidget {
  final GoRouter router;
  final Widget child;
  const StoreReviewGate({super.key, required this.router, required this.child});

  @override
  ConsumerState<StoreReviewGate> createState() => _StoreReviewGateState();
}

class _StoreReviewGateState extends ConsumerState<StoreReviewGate> {
  // Guards against scheduling a second attempt while one is already in flight
  // (the async availability check and the dialog span multiple frames).
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_scheduleRebuild);
  }

  void _scheduleRebuild() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(() {});
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_scheduleRebuild);
    super.dispose();
  }

  Future<void> _maybeAsk() async {
    if (_asking) return;
    final service = ref.read(storeReviewServiceProvider);
    if (service == null) return;

    final prefs = ref.read(preferencesProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!shouldAskForReview(
      done: prefs.getReviewDoneNow(),
      timesAsked: prefs.getReviewTimesAskedNow(),
      successCount: prefs.getReviewSuccessCountNow(),
      lastAskEpochMs: prefs.getReviewLastAskEpochMsNow(),
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
    // Rebuild when the counter or terminal flag changes so a freshly crossed
    // threshold is picked up even without a navigation event.
    ref.watch(reviewSuccessCountProvider);
    ref.watch(reviewDoneProvider);
    final locked = ref.watch(appLockedProvider);

    final path = widget.router.routerDelegate.currentConfiguration.uri.path;
    if (!locked && path == _homePath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeAsk();
      });
    }

    return widget.child;
  }
}
