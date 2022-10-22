import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info/package_info.dart';

Future<bool> checkTestingEnabled() async {
  final packageInfo = await PackageInfo.fromPlatform();
  if (Platform.isAndroid && packageInfo.packageName == 'foundation.privacybydesign.irmamobile') {
    return true;
  }
  if (Platform.isIOS && packageInfo.packageName == 'foundation.privacybydesign.irmamobile.alpha') {
    return true;
  }
  return kDebugMode;
}
