import "package:flutter_riverpod/flutter_riverpod.dart";

import "../platform/nfc_settings.dart";

final nfcSettingsOpenerProvider = Provider<NfcSettingsOpener>(
  (ref) => RealNfcSettingsOpener(),
);
