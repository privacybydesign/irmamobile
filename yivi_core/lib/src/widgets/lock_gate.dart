import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../providers/app_locked_provider.dart";
import "../screens/home/home_screen.dart";
import "../screens/home/widgets/irma_nav_bar.dart";
import "../screens/home/widgets/irma_qr_scan_button.dart";
import "../screens/pin/pin_screen.dart";
import "../screens/reset_pin/reset_pin_screen.dart";
import "../screens/terms_changed/terms_changed_dialog.dart";
import "../widgets/irma_app_bar.dart";

/// Routes that bypass the lock overlay. Conceptually the inverse of
/// the previous `whiteListedOnLocked` redirect-whitelist: with the
/// overlay design they aren't "redirected away from" — the overlay
/// simply doesn't draw on top of them.
const _unlockedPathPrefixes = {
  "/loading",
  "/enrollment",
  "/reset_pin",
  "/modal_pin",
  "/rooted_warning",
  "/update_required",
  "/error",
};

/// Top-level overlay-style lock. Sits inside `MaterialApp.router`'s
/// `builder` so it wraps every route the router renders. When the app
/// is locked AND the current route isn't in [_unlockedPathPrefixes],
/// `PinScreen` is drawn over [child]. The router's pages stay mounted
/// across lock/unlock — no dispose/dismiss cascade.
///
/// [router] is passed in explicitly because `GoRouter.of(context)`
/// doesn't resolve inside `MaterialApp.router`'s `builder` (the
/// inherited widget lives further down, inside the Router).
class LockGate extends ConsumerStatefulWidget {
  final GoRouter router;
  final Widget child;
  const LockGate({super.key, required this.router, required this.child});

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_scheduleRebuild);
  }

  void _scheduleRebuild() {
    if (!mounted) return;
    // Notifications fired DURING build (initial route configuration
    // by the Router; some GoRouterDelegate paths) can't call setState
    // directly without throwing. Defer those to the post-frame; for
    // anything fired while idle (user navigation, test-driven
    // pushes), rebuild now so the overlay state matches the new
    // route on the same frame.
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

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockedProvider);
    final path = widget.router.routerDelegate.currentConfiguration.uri.path;
    final isUnlockedRoute = _unlockedPathPrefixes.any(
      (prefix) => path == prefix || path.startsWith("$prefix/"),
    );
    final showOverlay = locked && !isUnlockedRoute;

    return Stack(
      children: [
        widget.child,
        if (showOverlay)
          // Local Navigator so widgets inside the overlay can use the
          // usual Navigator operations (showDialog, modal sheets, pop
          // dialogs) — `Navigator.of(context)` resolves to THIS nav,
          // which is what we want for overlay-internal interactions.
          Positioned.fill(
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (innerCtx) => TermsChangedListener(
                  child: PinScreen(
                    allowBiometric: true,
                    onAuthenticated: () {
                      if (context.mounted) {
                        context.read<HomeTabState>().add(IrmaNavBarTab.data);
                      }
                    },
                    // Push ResetPinScreen onto the overlay's local
                    // Navigator. Keeps the forgot-pin flow contained
                    // in the lock overlay — no GoRouter bridge
                    // needed. ResetPinScreen dispatches
                    // ClearAllDataEvent on reset, which flips
                    // `appLocked=false`; LockGate drops the overlay
                    // and the GoRouter redirect handles the rest
                    // (unenrolled → /enrollment).
                    onForgotPin: () => Navigator.of(innerCtx).push(
                      MaterialPageRoute<void>(builder: (_) => ResetPinScreen()),
                    ),
                    leading: YiviAppBarQrCodeButton(
                      // Same sheet entry point as the home-screen QR
                      // button — the modal opens on this local
                      // Navigator (since `innerCtx` is below it), sits
                      // on top of PinScreen, and the scanner queues
                      // the pointer for `PendingPointerListener` to
                      // pick up after PIN unlock.
                      onTap: () => openQrCodeScanner(innerCtx),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
