import "package:flutter_riverpod/flutter_riverpod.dart";

import "preferences_provider.dart";

/// Reads the Google Play install referrer. Only the Play build of the app
/// provides one: the F-Droid build and iOS have no install referrer.
abstract class InstallReferrerService {
  /// The referrer the Play Store link carried (for example `from=web`), or
  /// null when it cannot be read.
  Future<String?> getInstallReferrer();
}

final installReferrerServiceProvider = Provider<InstallReferrerService?>(
  (ref) => null,
);

const _sourceParameter = "from";
const _webSource = "web";

bool _isFromWeb(String? referrer) {
  if (referrer == null) return false;

  try {
    return Uri.splitQueryString(referrer)[_sourceParameter] == _webSource;
  } on FormatException {
    return false;
  } on ArgumentError {
    return false;
  }
}

/// Reads the install referrer on the first launch, once, and remembers whether
/// the install started on a website. Only `from=web` is stored: the referrer
/// passes through Google, so it never carries session data.
///
/// The read counts as done even when the service returned null, which also
/// happens for a transient Play failure. Retrying would need the service to
/// tell the two apart, and the cost of a miss is small: the user lands on the
/// empty data tab, which explains how to go back to the website.
final installReferrerReaderProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(installReferrerServiceProvider);
  if (service == null) return;

  final preferences = ref.watch(preferencesProvider);
  if (await preferences.getInstallReferrerRead().first) return;

  if (_isFromWeb(await service.getInstallReferrer())) {
    await preferences.markBackToWebsitePending();
  }
  await preferences.markInstallReferrerRead();
});
