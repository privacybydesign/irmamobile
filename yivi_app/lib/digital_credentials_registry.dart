import "dart:convert";

import "package:flutter/services.dart";
import "package:yivi_core/yivi_core.dart";

/// Android implementation of [DigitalCredentialsRegistry]: hands the entries to
/// `DigitalCredentialsRegistrar`, which registers the ones Android knows the
/// format of with the Credential Manager. Lives here in `yivi_app` because that
/// registration is stored by Google Play services, through a proprietary
/// library the FOSS `yivi_fdroid` build must not carry; it injects no registry
/// at all.
class MethodChannelDigitalCredentialsRegistry
    implements DigitalCredentialsRegistry {
  static const _channel = MethodChannel(
    "irma.app/digital_credentials_registry",
  );

  @override
  Future<void> register(List<Map<String, dynamic>> entries) =>
      _channel.invokeMethod<void>("register", jsonEncode(entries));
}
