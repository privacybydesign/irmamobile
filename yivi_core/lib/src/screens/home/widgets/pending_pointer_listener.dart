import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/session.dart";
import "../../../providers/app_locked_provider.dart";
import "../../../providers/pending_pointer_provider.dart";
import "../../../providers/session_launcher.dart";
import "../../../util/after_frame.dart";
import "../../../util/email_linking.dart";

/// Picks up a queued session/URL pointer and starts the session — but only
/// once the app is unlocked. While locked the pointer waits behind the lock
/// overlay's PIN: starting it earlier would let the session hit `requestPin`
/// before the unlock refreshes the keyshare token (a second PIN prompt), and
/// would clear the pending-pointer signal the lock screen uses to hide
/// biometric. Biometric unlock also flips `AppLock.locked` to false without
/// refreshing the token, but the biometric backstop
/// ([BiometricService.authenticateAndUnlock]) refuses to unlock while a pointer
/// is pending, so when we start here the unlock came from a PIN and the token is
/// fresh.
class PendingPointerListener extends StatefulWidget {
  final Widget child;
  const PendingPointerListener({super.key, required this.child});

  @override
  State<PendingPointerListener> createState() => _PendingPointerListenerState();
}

class _PendingPointerListenerState extends State<PendingPointerListener> {
  // Subscribed on the container, not through a ConsumerState's `ref`: those
  // pause while the widget is out of view (home under a session screen),
  // and a link must start then too.
  final _subscriptions = <ProviderSubscription<Object?>>[];

  Pointer? _pointer;
  bool _locked = true;
  bool _handling = false;

  @override
  void initState() {
    super.initState();

    afterFrame(() {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      _subscriptions
        ..add(
          container.listen<Pointer?>(pendingPointerProvider, (_, pointer) {
            _pointer = pointer;
            _maybeHandle();
          }, fireImmediately: true),
        )
        ..add(
          container.listen<bool>(appLockedProvider, (_, locked) {
            _locked = locked;
            _maybeHandle();
          }, fireImmediately: true),
        );
    });
  }

  void _maybeHandle() {
    final pointer = _pointer;
    if (pointer == null || _locked || _handling || !mounted) return;
    _handling = true;
    final outcome = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(sessionLauncherProvider).handle(pointer);
    if (outcome case LinkForLinking(openLinking: true)) {
      openEmailLinking(context);
    }
    // One at a time: a session's pointer stays queued until its start
    // reaches the queue, a microtask later.
    scheduleMicrotask(() => _handling = false);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
