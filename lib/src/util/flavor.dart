import 'package:package_info/package_info.dart';

enum Flavor {
  alpha,
  beta,
  unknown,
}

Future<Flavor> getFlavor() async {
  final packageInfo = await PackageInfo.fromPlatform();
  switch (packageInfo.packageName) {
    case 'foundation.privacybydesign.irmamobile.alpha':
    case 'foundation.privacybydesign.irmamob.alpha':
      return Flavor.alpha;
    case 'org.irmacard.cardemu':
    case 'foundation.privacybydesign.irmamob':
      return Flavor.beta;
    default:
      return Flavor.unknown;
  }
}
