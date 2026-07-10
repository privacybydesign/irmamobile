import "dart:async";

import "package:flutter/material.dart";

import "../../../models/session.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../util/handle_pointer.dart";

/// Picks up a queued session/URL pointer and starts the session — but only
/// once the app is unlocked. While locked the pointer waits behind the lock
/// overlay's PIN: starting it earlier would let the session hit `requestPin`
/// before the unlock refreshes the keyshare token (a second PIN prompt), and
/// would clear the pending-pointer signal the lock screen uses to hide
/// biometric. `getLocked()` only flips to false after a successful
/// KeyshareVerifyPin, so by the time we start here the token is fresh.
class PendingPointerListener extends StatefulWidget {
  final Widget child;
  const PendingPointerListener({super.key, required this.child});

  @override
  State<PendingPointerListener> createState() => _PendingPointerListenerState();
}

class _PendingPointerListenerState extends State<PendingPointerListener> {
  StreamSubscription<Pointer?>? _pointerSubscription;
  StreamSubscription<bool>? _lockedSubscription;

  Pointer? _pointer;
  bool _locked = true;
  bool _handling = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = IrmaRepositoryProvider.of(context);
      _pointerSubscription = repo.getPendingPointer().listen((pointer) {
        _pointer = pointer;
        _maybeHandle();
      });
      _lockedSubscription = repo.getLocked().listen((locked) {
        _locked = locked;
        _maybeHandle();
      });
    });
  }

  void _maybeHandle() {
    final pointer = _pointer;
    if (pointer == null || _locked || _handling || !mounted) return;

    // A session must be gated behind a real PIN (which refreshes the keyshare
    // token). If the app was unlocked biometric-only — e.g. the cold-start
    // biometric auto-scan won the race against a universal link and unlocked
    // before the session pointer was delivered — bounce back to the lock screen.
    // The pointer stays queued; `hasPendingSession` then hides biometric on the
    // lock screen, and after the PIN unlock this fires again and starts the
    // session. lock() also drops the keyshare token, so there is no bypass.
    final repo = IrmaRepositoryProvider.of(context);
    if (pointer is SessionPointer && repo.unlockedWithoutPin) {
      repo.lock();
      return;
    }

    _handling = true;
    handlePointer(context, pointer).whenComplete(() => _handling = false);
  }

  @override
  void dispose() {
    _pointerSubscription?.cancel();
    _lockedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
