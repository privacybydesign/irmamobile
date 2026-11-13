import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../models/enrollment_status.dart";
import "../providers/irma_repository_provider.dart";

/// Locks the app when it has been backgrounded for longer than
/// [idleThreshold], or left open and untouched for longer than
/// [foregroundIdleThreshold]. The `LockGate` widget reacts to the locked state
/// stream and overlays `PinScreen` on top of whatever route is mounted
/// — no navigation is needed here.
///
/// The foreground timer covers a phone that is put down unlocked with Yivi
/// open: without it the wallet stays open for as long as the screen stays on.
/// Any touch restarts it.
///
/// Tracks `paused` and `resumed` lifecycle events. `inactive` and `hidden` are
/// intentionally ignored: only a real backgrounding sets `_lastPausedAt`, so
/// transient interruptions (Apple Pay, brief Control Center pulls) cannot
/// trigger a lock.
class IdleLockObserver extends ConsumerStatefulWidget {
  final Widget child;
  final Duration idleThreshold;
  final Duration foregroundIdleThreshold;

  const IdleLockObserver({
    super.key,
    required this.child,
    this.idleThreshold = const Duration(minutes: 5),
    this.foregroundIdleThreshold = const Duration(minutes: 5),
  });

  @override
  ConsumerState<IdleLockObserver> createState() => _IdleLockObserverState();
}

class _IdleLockObserverState extends ConsumerState<IdleLockObserver>
    with WidgetsBindingObserver {
  DateTime? _lastPausedAt;
  Timer? _foregroundIdleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restartForegroundIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foregroundIdleTimer?.cancel();
    super.dispose();
  }

  void _restartForegroundIdleTimer() {
    _foregroundIdleTimer?.cancel();
    _foregroundIdleTimer = Timer(widget.foregroundIdleThreshold, () {
      // Start counting again right away: an unlock with biometrics does not
      // touch the app, so nothing else would restart the timer after it.
      _restartForegroundIdleTimer();
      _lock();
    });
  }

  Future<void> _lock() async {
    final repo = ref.read(irmaRepositoryProvider);
    final status = await repo.getEnrollmentStatus().firstWhere(
      (s) => s != EnrollmentStatus.undetermined,
    );
    if (!mounted) return;
    if (status != EnrollmentStatus.enrolled) return;

    if (await repo.getLocked().first) return;
    if (!mounted) return;

    repo.lock();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _lastPausedAt = DateTime.now();
      // In the background the paused timestamp takes over.
      _foregroundIdleTimer?.cancel();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    _restartForegroundIdleTimer();

    final pausedAt = _lastPausedAt;
    _lastPausedAt = null;
    if (pausedAt == null) return;
    if (DateTime.now().difference(pausedAt) <= widget.idleThreshold) return;

    await _lock();
  }

  @override
  Widget build(BuildContext context) => Listener(
    // Sees every pointer that goes down anywhere in the app, without taking
    // part in the gesture arena.
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _restartForegroundIdleTimer(),
    child: widget.child,
  );
}
