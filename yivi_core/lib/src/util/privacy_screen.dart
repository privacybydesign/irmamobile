import "package:flutter/services.dart";

class PrivacyScreen {
  static final MethodChannel _channel = MethodChannel("privacy_screen");

  static Future<void> enablePrivacyScreen() async {
    await _channel.invokeMethod("enablePrivacyScreen");
  }

  static Future<void> disablePrivacyScreen() async {
    await _channel.invokeMethod("disablePrivacyScreen");
  }

  /// Runs [action] with the privacy screen held back, for flows that put system
  /// UI on top of the app: the iOS NFC reader sheet and the OS biometric
  /// prompt. Both resign the app active without backgrounding it, and the app
  /// stays resigned until they close, so the blur would otherwise sit over the
  /// whole scan. Leaving the app during [action] still blurs, and the user's
  /// screenshot preference is untouched either way — unlike
  /// [disablePrivacyScreen], which switches the privacy screen off outright.
  ///
  /// Suspensions nest, and are always undone, including when [action] throws.
  /// Backgrounding the app drops them too: the system UI they cover cannot
  /// outlive the app leaving the foreground, so a suspension that never made it
  /// back — the isolate killed mid-flow, a debug hot restart — costs the blur
  /// until the next time the app is backgrounded, not for the rest of the
  /// process.
  static Future<T> suspendDuring<T>(Future<T> Function() action) async {
    await _channel.invokeMethod("suspendPrivacyScreen");
    try {
      return await action();
    } finally {
      await _channel.invokeMethod("resumePrivacyScreen");
    }
  }
}
