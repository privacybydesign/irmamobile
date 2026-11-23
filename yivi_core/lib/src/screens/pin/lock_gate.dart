import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";

import "../../../routing.dart";
import "../../providers/app_locked_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/preferences_provider.dart";
import "../../util/after_frame.dart";
import "../../util/i18n.dart";
import "../../util/rebuild_when_safe.dart";
import "../../widgets/bars/app_bar.dart";
import "../../widgets/feedback/app_toast.dart";
import "../home/widgets/home_tab.dart";
import "../home/widgets/open_qr_scanner.dart";
import "../reset_pin/reset_pin_screen.dart";
import "../scanner/lock_scanner_sheet.dart";
import "../terms_changed/terms_changed_dialog.dart";
import "pin_screen.dart";
import "providers/biometric_provider.dart";
import "widgets/biometric_opt_in_dialog.dart";

/// Routes that bypass the lock overlay. Conceptually the inverse of
/// the previous `whiteListedOnLocked` redirect-whitelist: with the
/// overlay design they aren't "redirected away from" — the overlay
/// simply doesn't draw on top of them.
const _unlockedPathPrefixes = {
  "/loading",
  "/enrollment",
  "/reset_pin",
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
/// The router comes from [routerProvider] because `GoRouter.of(context)`
/// doesn't resolve inside `MaterialApp.router`'s `builder` (the
/// inherited widget lives further down, inside the Router).
class LockGate extends ConsumerStatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with RebuildWhenSafe {
  // Whether the lock overlay was showing on the previous build, so we can
  // detect the unlock transition (overlay dismissed) and offer biometric.
  bool _overlayShown = false;

  late final GoRouter _router = ref.read(routerProvider);

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(rebuildWhenSafe);
    lockScannerSheetHolds.addListener(rebuildWhenSafe);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(rebuildWhenSafe);
    lockScannerSheetHolds.removeListener(rebuildWhenSafe);
    super.dispose();
  }

  /// One-time biometric opt-in, offered right after the lock overlay is
  /// dismissed by a successful unlock. Triggered from here — a host that
  /// survives the unlock — rather than from PinScreen, which the unlock tears
  /// down. Shown on the root navigator so it sits above the now-visible app.
  void _maybeOfferBiometricUnlock() {
    final available = ref.read(biometricAvailableProvider).value ?? false;
    final enabled = ref.read(biometricEnabledProvider);
    final dismissed = ref.read(biometricPromptDismissedProvider);
    if (!available || enabled || dismissed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) showBiometricOptInDialog(ctx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockedProvider);
    // Warm the biometric availability/prefs so they're resolved by the time
    // the overlay is dismissed and we offer the opt-in.
    ref.watch(biometricAvailableProvider);
    ref.watch(biometricEnabledProvider);
    ref.watch(biometricPromptDismissedProvider);
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    final isUnlockedRoute = _unlockedPathPrefixes.any(
      (prefix) => path == prefix || path.startsWith("$prefix/"),
    );
    // The scanner sheet on the lock screen carries an issuance past the
    // unlock: the overlay (its home) stays until the sheet closes. The PIN
    // screen under the sheet is gone by then (it hides once authenticated),
    // so the app shows behind the sheet.
    final holding = lockScannerSheetHolds.value && _overlayShown;
    final showOverlay = (locked || holding) && !isUnlockedRoute;

    // Offer biometric only on a genuine unlock: the overlay was showing and we
    // are now unlocked on a normal in-app route. The !isUnlockedRoute guard
    // skips the transient startup→/enrollment route flicker, which would
    // otherwise pop the dialog over the enrollment screen.
    if (_overlayShown && !showOverlay && !locked && !isUnlockedRoute) {
      _maybeOfferBiometricUnlock();
    }
    _overlayShown = showOverlay;

    return Stack(
      children: [
        widget.child,
        if (showOverlay)
          // Local Navigator so widgets inside the overlay can use the
          // usual Navigator operations (showDialog, modal sheets, pop
          // dialogs) — `Navigator.of(context)` resolves to THIS nav,
          // which is what we want for overlay-internal interactions.
          //
          // Own ScaffoldMessenger so a snackbar shown here reaches only the
          // overlay's Scaffold. A messenger paints its snackbar in *every*
          // registered root Scaffold, and [child]'s Scaffold stays mounted
          // underneath — on the root messenger the logout confirmation was
          // rendered twice, once in the hidden tree and once here.
          Positioned.fill(
            child: ScaffoldMessenger(
              child: _LogoutConfirmation(
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (innerCtx) => TermsChangedListener(
                      child: PinScreen(
                        onAuthenticated: () {
                          if (context.mounted) {
                            ref
                                .read(homeTabProvider.notifier)
                                .select(HomeTab.data);
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
                        onForgotPin: () {
                          // The logout confirmation explains why *this* screen
                          // is asking for a PIN; it has nothing to say on the
                          // reset flow, and the messenger would otherwise keep
                          // it up over the pushed route. Removed, not hidden:
                          // while it slid away it would also be laid out on
                          // the reset screen, whose action bar leaves no room
                          // for a toast placed for the top of the PIN screen.
                          ScaffoldMessenger.of(
                            innerCtx,
                          ).removeCurrentSnackBar();
                          Navigator.of(innerCtx).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ResetPinScreen(),
                            ),
                          );
                        },
                        leading: QrCodeBarButton(
                          // Same sheet entry point as the home-screen QR
                          // button — the modal opens on this local
                          // Navigator (since `innerCtx` is below it), sits
                          // on top of PinScreen, and the scanner queues
                          // the pointer for `PendingPointerListener` to
                          // pick up after PIN unlock.
                          onTap: () =>
                              openQrCodeScanner(innerCtx, lockScreen: true),
                        ),
                      ),
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

/// Shows the logout confirmation once, on the [ScaffoldMessenger] above it,
/// after the More tab's Log out ([AppLock.consumeLogoutConfirmation]). Lives
/// inside the overlay so the message appears on the PIN screen the user is
/// actually looking at — and only there.
class _LogoutConfirmation extends ConsumerStatefulWidget {
  final Widget child;
  const _LogoutConfirmation({required this.child});

  @override
  ConsumerState<_LogoutConfirmation> createState() =>
      _LogoutConfirmationState();
}

class _LogoutConfirmationState extends ConsumerState<_LogoutConfirmation> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(appLockProvider).consumeLogoutConfirmation()) return;
    // Post-frame: the messenger's State is only reachable once this subtree is
    // mounted.
    afterFrame(() {
      // At the top: the PIN screen's keypad and link fill the bottom.
      showAppToast(
        context,
        context.tr("more_tab.logged_out_toast"),
        atTop: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
