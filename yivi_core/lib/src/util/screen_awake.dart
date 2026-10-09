import "package:flutter/services.dart";

/// Keeps the display awake for the duration of a user-attended flow.
///
/// A session makes the user wait on work they cannot speed up — a ZK age proof
/// is ~2 s of single-threaded CPU on a modern phone, more on a slow one — while
/// they watch a progress indicator and touch nothing. If the display timeout
/// fires in that window the flow is interrupted, and on Android it also costs
/// performance: the app leaves `top-app` for the `background` cpuset, which is
/// the little cluster on every big.LITTLE device we have measured, and the
/// remaining work finishes about three times slower.
///
/// Holds are counted natively, so nested sessions — a disclosure that starts an
/// issuance on top of itself — cannot release each other's hold.
class ScreenAwake {
  static final MethodChannel _channel = MethodChannel("screen_awake");

  /// Takes a hold on the display. Every call must be balanced by
  /// [allowScreenOff]; prefer [keepAwakeDuring] where the flow is an await.
  static Future<void> keepScreenOn() async {
    await _channel.invokeMethod("keepScreenOn");
  }

  /// Releases one hold taken by [keepScreenOn]. Releasing more often than
  /// holding is harmless: the native count floors at zero.
  static Future<void> allowScreenOff() async {
    await _channel.invokeMethod("allowScreenOff");
  }

  /// Runs [action] with the display held awake, releasing the hold even when
  /// [action] throws.
  static Future<T> keepAwakeDuring<T>(Future<T> Function() action) async {
    await keepScreenOn();
    try {
      return await action();
    } finally {
      await allowScreenOff();
    }
  }
}
