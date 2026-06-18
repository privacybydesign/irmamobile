import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../providers/app_locked_provider.dart";
import "../screens/home/home_screen.dart";
import "../screens/home/widgets/irma_nav_bar.dart";
import "../screens/home/widgets/irma_qr_scan_button.dart";
import "../screens/pin/pin_screen.dart";
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
  "/scanner",
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
    // Defensive: in case `MaterialApp.router`'s builder doesn't always
    // rebuild this widget on a route change, ask for a rebuild
    // ourselves. The post-frame defer avoids `setState during build`
    // on the initial route configuration, where the delegate notifies
    // synchronously during Router's first build.
    widget.router.routerDelegate.addListener(_scheduleRebuild);
  }

  void _scheduleRebuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_scheduleRebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockedProvider);
    // Read the path live so a rebuild triggered by a parent (e.g. the
    // router swapping `widget.child` for the new route) sees the new
    // path immediately — no one-frame flicker of unlocked content
    // before the overlay catches up.
    final path = widget.router.routerDelegate.currentConfiguration.uri.path;
    final isUnlockedRoute = _unlockedPathPrefixes.any(
      (prefix) => path == prefix || path.startsWith("$prefix/"),
    );
    final showOverlay = locked && !isUnlockedRoute;

    return Stack(
      children: [
        widget.child,
        if (showOverlay)
          Positioned.fill(
            child: TermsChangedListener(
              child: PinScreen(
                onAuthenticated: () {
                  if (context.mounted) {
                    context.read<HomeTabState>().add(IrmaNavBarTab.data);
                  }
                },
                leading: YiviAppBarQrCodeButton(
                  onTap: () => openQrCodeScanner(
                    context,
                    requireAuthBeforeSession: true,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
