import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:vcmrtd/vcmrtd.dart";

/// Whether the current device has usable onboard NFC hardware.
///
/// Returns `false` only when the device has no NFC chip at all
/// ([NfcStatus.notSupported], e.g. iPads). A device whose NFC radio is merely
/// switched off ([NfcStatus.disabled]) still counts as NFC-capable, because the
/// user can enable it and complete the document-scanning flow.
final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  final status = await NfcProvider.nfcStatus;
  return status != NfcStatus.notSupported;
});
