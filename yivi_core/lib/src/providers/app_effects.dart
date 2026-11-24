import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../models/enrollment_status.dart";
import "../models/update_schemes_event.dart";
import "../platform/privacy_screen.dart";
import "idle_lock.dart";
import "irma_repository_provider.dart";
import "preferences_provider.dart";

// What the app does by itself, outside any screen. Each provider is switched
// on by one `ref.watch` in the app's build, and undoes itself on dispose.

/// How often the schemes are updated, at the most.
const schemeUpdateIntervalHours = 3;

/// Updates the schemes when the last update is more than
/// [schemeUpdateIntervalHours] ago: at the start, and again on every return
/// to the app.
final schemeUpdateProvider = Provider<void>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  final prefs = ref.watch(preferencesProvider);

  Future<void> update() async {
    final lastSchemeUpdate = await prefs.lastSchemeUpdate.stream.first;
    if (DateTime.now().difference(lastSchemeUpdate).inHours >
        schemeUpdateIntervalHours) {
      prefs.lastSchemeUpdate.set(DateTime.now());
      repo.bridgedDispatch(UpdateSchemesEvent());
    }
  }

  update();
  final listener = AppLifecycleListener(
    onStateChange: (state) {
      if (state == AppLifecycleState.resumed) update();
    },
  );
  ref.onDispose(listener.dispose);
});

/// The privacy screen (no screenshots, a blurred app switcher) follows the
/// screenshot preference.
final privacyScreenProvider = Provider<void>((ref) {
  final subscription = ref
      .watch(preferencesProvider)
      .screenshotsEnabled
      .stream
      .listen((enabled) async {
        if (enabled) {
          await PrivacyScreen.disablePrivacyScreen();
        } else {
          await PrivacyScreen.enablePrivacyScreen();
        }
      });
  ref.onDispose(subscription.cancel);
});

/// How long the app may stay in the background before it locks.
/// Integration tests make it short.
final idleLockThresholdProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 5),
);

/// How long the app may stay open and untouched before it locks.
final foregroundIdleLockThresholdProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 5),
);

/// Locks the app when it was left alone (see [IdleLock]). The lock overlay
/// follows the lock; no navigation is needed here. Use of the app reaches it
/// through [IdleLock.noteUse], from an [IdleUseListener] around the app.
final idleLockProvider = Provider<IdleLock>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  final lock = ref.watch(appLockProvider);

  /// Only a wallet that exists and is open can be locked.
  Future<void> lockIfOpen() async {
    final status = await repo.getEnrollmentStatus().firstWhere(
      (s) => s != EnrollmentStatus.undetermined,
    );
    if (!ref.mounted) return;
    if (status != EnrollmentStatus.enrolled) return;

    if (await lock.locked.first) return;
    if (!ref.mounted) return;

    lock.lock();
  }

  final idle = IdleLock(
    background: ref.watch(idleLockThresholdProvider),
    foreground: ref.watch(foregroundIdleLockThresholdProvider),
    lock: lockIfOpen,
  );
  ref.onDispose(idle.dispose);
  return idle;
});

/// Once unenrolled, the name-changed notice is switched off for good: it is
/// meant for those who used the app under its old name.
final nameChangedResetProvider = Provider<void>((ref) {
  final repo = ref.watch(irmaRepositoryProvider);
  final prefs = ref.watch(preferencesProvider);
  StreamSubscription<EnrollmentStatus>? subscription;
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    subscription?.cancel();
  });

  prefs.showNameChangedNotification.stream.first.then((show) {
    if (!show || disposed) return;
    subscription = repo.getEnrollmentStatus().listen((status) {
      if (status == EnrollmentStatus.unenrolled) {
        prefs.showNameChangedNotification.set(false);
        subscription?.cancel();
      }
    });
  });
});
