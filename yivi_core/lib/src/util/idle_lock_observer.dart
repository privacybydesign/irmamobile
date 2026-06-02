import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../routing.dart";
import "../models/enrollment_status.dart";
import "../providers/irma_repository_provider.dart";

/// Locks the app when it has been backgrounded for longer than
/// [idleThreshold] and resets navigation to `/home`, so the user emerges to a
/// fresh stack on unlock instead of to whatever screen they left behind.
///
/// Tracks `paused` and `resumed` lifecycle events. `inactive` and `hidden` are
/// intentionally ignored: only a real backgrounding sets `_lastPausedAt`, so
/// transient interruptions (Apple Pay, brief Control Center pulls) cannot
/// trigger a lock.
class IdleLockObserver extends ConsumerStatefulWidget {
  final Widget child;
  final Duration idleThreshold;

  const IdleLockObserver({
    super.key,
    required this.child,
    this.idleThreshold = const Duration(minutes: 5),
  });

  @override
  ConsumerState<IdleLockObserver> createState() => _IdleLockObserverState();
}

class _IdleLockObserverState extends ConsumerState<IdleLockObserver>
    with WidgetsBindingObserver {
  DateTime? _lastPausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _lastPausedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _lastPausedAt;
    _lastPausedAt = null;
    if (pausedAt == null) return;
    if (DateTime.now().difference(pausedAt) <= widget.idleThreshold) return;

    final repo = ref.read(irmaRepositoryProvider);
    final status = await repo.getEnrollmentStatus().firstWhere(
      (s) => s != EnrollmentStatus.undetermined,
    );
    if (!mounted) return;
    if (status != EnrollmentStatus.enrolled) return;

    if (await repo.getLocked().first) return;
    if (!mounted) return;

    repo.lock();
    rootNavigatorKey.currentContext?.go("/home");
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
