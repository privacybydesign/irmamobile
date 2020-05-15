import 'package:flutter/foundation.dart';

class VersionInformation {
  int currentVersion;
  int requiredVersion;
  int availableVersion;

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
