import 'package:flutter/foundation.dart';
import 'package:version/version.dart';

class VersionInformation {
  Version availableVersion;
  Version requiredVersion;
  Version currentVersion;

  VersionInformation({
    @required this.availableVersion,
    @required this.requiredVersion,
    @required this.currentVersion,
  })  : assert(availableVersion != null),
        assert(requiredVersion != null),
        assert(currentVersion != null);

  bool updateAvailable() {
    return availableVersion > currentVersion;
  }

  bool updateRequired() {
    return requiredVersion > currentVersion;
  }
}
