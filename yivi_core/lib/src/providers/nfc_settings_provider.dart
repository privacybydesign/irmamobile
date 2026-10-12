import "package:flutter_riverpod/flutter_riverpod.dart";

import "../util/nfc_settings.dart";

final nfcSettingsOpenerProvider = Provider<NfcSettingsOpener>(
  (ref) => RealNfcSettingsOpener(),
);
