import "package:flutter/services.dart";

abstract class NfcSettingsOpener {
  /// Opens the system screen where the user can turn NFC on. Android only.
  Future<void> open();
}

class RealNfcSettingsOpener implements NfcSettingsOpener {
  static const _channel = MethodChannel("yivi.app/nfc_settings");

  @override
  Future<void> open() async {
    try {
      await _channel.invokeMethod<void>("open");
    } on PlatformException {
      // A device without the screen (`no_nfc_settings`). The NFC screen stays
      // as it is: it still asks for NFC to be turned on and offers Cancel.
    }
  }
}
