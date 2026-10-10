import "package:flutter/services.dart";

abstract class NfcSettingsOpener {
  /// Opens the system screen where the user can turn NFC on. Android only.
  Future<void> open();
}

class RealNfcSettingsOpener implements NfcSettingsOpener {
  static const _channel = MethodChannel("yivi.app/nfc_settings");

  @override
  Future<void> open() => _channel.invokeMethod<void>("open");
}
