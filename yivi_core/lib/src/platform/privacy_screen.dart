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
  /// They survive the app being backgrounded, because the system UI they cover
  /// does too: a biometric prompt started with `persistAcrossBackgrounding` is
  /// re-presented when the app becomes active again, with this call still
  /// pending, so dropping the suspension on the way out would blur that second
  /// prompt. The price is that a suspension which never made it back holds the
  /// resign-active blur for the rest of the process. Only a debug hot restart
  /// gets there, since the native count is static and a killed isolate takes
  /// the process with it, and the blur that hides the app in the switcher is
  /// added whatever the count says, so it is never the one at stake.
  static Future<T> suspendDuring<T>(Future<T> Function() action) async {
    await _channel.invokeMethod("suspendPrivacyScreen");
    try {
      return await action();
    } finally {
      await _channel.invokeMethod("resumePrivacyScreen");
    }
  }
}
