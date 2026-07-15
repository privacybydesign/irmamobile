import "package:flutter_riverpod/flutter_riverpod.dart";

import "irma_repository_provider.dart";

/// Mirrors `repo.getCarrierWindowClosed()`: `false` while the carrier window is
/// open, `true` once it has closed. A *carrier* is the string that transports a
/// session pointer into the app (universal link, custom-scheme link, or raw
/// pointer JSON); the *carrier window* is the interval right after the app
/// starts or returns to the foreground during which a carrier that opened it may
/// still be in flight.
///
/// While the window is open the lock-screen [PinScreen] withholds its biometric
/// surfaces (the automatic prompt and the button), so biometric can't win the
/// race against a link and unlock the app before the session pointer that opened
/// it is known — which would otherwise let a link session ride in on a
/// biometric-only unlock (issue #644 on cold start, issue #654 on resume-lock).
class CarrierWindowClosedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(irmaRepositoryProvider);
    final sub = repo.getCarrierWindowClosed().listen((v) => state = v);
    ref.onDispose(sub.cancel);
    return false;
  }
}

final carrierWindowClosedProvider =
    NotifierProvider<CarrierWindowClosedNotifier, bool>(
      CarrierWindowClosedNotifier.new,
    );
