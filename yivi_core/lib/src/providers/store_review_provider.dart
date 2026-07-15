import "package:flutter_riverpod/flutter_riverpod.dart";

import "preferences_provider.dart";

/// Wraps the platform in-app review API (Google Play In-App Review / iOS
/// SKStoreReviewController). Injected from the outside via `runYiviApp` so the
/// proprietary `in_app_review` dependency never enters the FOSS (F-Droid) build:
/// there the provider stays `null` and the whole feature is gated off.
abstract class StoreReviewService {
  /// Whether the native in-app review flow can be shown right now. False on
  /// devices without the backing store services (e.g. some Android devices
  /// without Google Play), in which case the prompt is skipped entirely.
  Future<bool> isAvailable();

  /// Asks the platform to show its native in-app review card. The platform
  /// decides whether to actually display it; there is no callback and no
  /// guarantee it appears.
  Future<void> requestReview();
}

/// Null by default. Overridden in `runYiviApp` with a concrete implementation
/// in the Play Store build; left null in the F-Droid build.
final storeReviewServiceProvider = Provider<StoreReviewService?>((ref) => null);

/// Number of successful sessions since the review state was last reset. Drives
/// the gate rebuild so the sentiment prompt can appear once the threshold is
/// crossed.
final reviewSuccessCountProvider = StreamProvider<int>(
  (ref) => ref.watch(preferencesProvider).getReviewSuccessCount(),
);

/// Terminal flag: the user has either accepted (native prompt shown) or
/// declined (routed to feedback) — never asked again once set.
final reviewDoneProvider = StreamProvider<bool>(
  (ref) => ref.watch(preferencesProvider).getReviewDone(),
);

/// Successful sessions before the first ask.
const reviewFirstAskThreshold = 5;

/// Successful sessions before the (single) second ask, which also requires
/// [reviewReAskDelay] to have passed since the first ask.
const reviewSecondAskThreshold = 15;

/// Minimum time between the first ask and the second ask.
const reviewReAskDelay = Duration(days: 90);

/// Pure eligibility check for the sentiment gate, kept free of Flutter and
/// I/O so it can be unit-tested directly. Mirrors the trigger table in
/// privacybydesign/irmamobile#648.
bool shouldAskForReview({
  required bool done,
  required int timesAsked,
  required int successCount,
  required int lastAskEpochMs,
  required int nowEpochMs,
}) {
  if (done) return false;
  if (timesAsked == 0) {
    return successCount >= reviewFirstAskThreshold;
  }
  if (timesAsked == 1) {
    return successCount >= reviewSecondAskThreshold &&
        (nowEpochMs - lastAskEpochMs) >= reviewReAskDelay.inMilliseconds;
  }
  // Asked twice already: terminal.
  return false;
}
