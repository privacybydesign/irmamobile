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
/// is treated as NFC-capable (`true`). This is the safe default: it leaves the
/// credential store untouched rather than hiding NFC-requiring credentials —
/// and, since the store filter never hides credentials on a `true` result, it
/// keeps a failed check from blanking the entire credential list.
final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    final status = await NfcProvider.nfcStatus;
    return status != NfcStatus.notSupported;
  } catch (_) {
    return true;
  }
});
