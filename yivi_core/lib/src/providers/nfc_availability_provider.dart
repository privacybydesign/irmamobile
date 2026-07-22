import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart";

/// Whether the current device has usable onboard NFC hardware.
///
/// Returns `false` only when the device has no NFC chip at all
/// ([NfcStatus.notSupported], e.g. iPads). A device whose NFC radio is merely
/// switched off ([NfcStatus.disabled]) still counts as NFC-capable, because the
/// user can enable it and complete the document-scanning flow.
///
/// If the NFC status check fails or is unavailable for any reason, the device
/// is treated as NFC-capable (`true`). This is the safe default: greying out a
/// credential the user can actually obtain is worse than showing it normally,
/// so `SchemalessAddDataScreen` only greys out the NFC-requiring credentials on
/// a confirmed "no NFC chip" result, never while the check is loading or after
/// a failure.
final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    final status = await NfcProvider.nfcStatus;
    return status != NfcStatus.notSupported;
  } catch (_) {
    return true;
  }
});
