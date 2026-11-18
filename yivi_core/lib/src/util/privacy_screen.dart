import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_i18n/flutter_i18n.dart";

/// Keeps the text of the cover that iOS shows while the screen is recorded or
/// shared in the language the app is set to. The cover is drawn by native
/// code, which cannot reach the app's translations and would otherwise follow
/// the language of the system.
///
/// Belongs below the app's localizations, and sends the text again whenever
/// the language changes.
class CaptureCoverText extends StatefulWidget {
  final Widget child;

  const CaptureCoverText({super.key, required this.child});

  @override
  State<CaptureCoverText> createState() => _CaptureCoverTextState();
}

class _CaptureCoverTextState extends State<CaptureCoverText> {
  String? _sent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read to be called again when the language changes.
    Localizations.maybeLocaleOf(context);
    const key = "privacy_screen.capture_cover";
    final text = FlutterI18n.translate(context, key);
    // A translation that is missing comes back as its key.
    if (text == key || text == _sent) return;
    _sent = text;
    PrivacyScreen.setCaptureCoverText(text);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PrivacyScreen {
  static final MethodChannel _channel = MethodChannel("privacy_screen");

  static Future<void> enablePrivacyScreen() async {
    await _channel.invokeMethod("enablePrivacyScreen");
  }

  static Future<void> disablePrivacyScreen() async {
    await _channel.invokeMethod("disablePrivacyScreen");
  }

  /// Sets the text of the cover shown while the screen is recorded or shared.
  /// Only iOS has such a cover: Android keeps the app out of a capture itself.
  static Future<void> setCaptureCoverText(String text) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod("setCaptureCoverText", text);
    } on MissingPluginException {
      // No native side, as in a test: there is no cover to label.
    }
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
