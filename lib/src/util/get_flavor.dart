import 'dart:io';

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
      return Flavor.alpha;
    case 'org.irmacard.cardemu':
      return Flavor.beta;
    case 'foundation.privacybydesign.irmamobile':
      return Platform.isAndroid ? Flavor.alpha : Flavor.beta;
    default:
      return Flavor.unknown;
  }
}
