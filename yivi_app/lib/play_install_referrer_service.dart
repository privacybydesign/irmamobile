import "package:flutter/services.dart";
import "package:yivi_core/yivi_core.dart";

/// Google Play implementation of [InstallReferrerService], backed by the Play
/// Install Referrer library through `InstallReferrerHandler` in the Android
/// host. Lives here in `yivi_app` so the Google library stays out of the FOSS
/// `yivi_fdroid` build, which injects no service at all.
class PlayInstallReferrerService implements InstallReferrerService {
  static const _channel = MethodChannel(
    "foundation.privacybydesign.irmamobile/install_referrer",
  );

  @override
  Future<String?> getInstallReferrer() async {
    try {
      return await _channel.invokeMethod<String>("getInstallReferrer");
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
