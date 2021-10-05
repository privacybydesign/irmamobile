class VersionInformation {
  final int currentVersion;
  final int requiredVersion;
  final int availableVersion;

  VersionInformation({
    required this.availableVersion,
    required this.requiredVersion,
    required this.currentVersion,
  });

  bool updateAvailable() {
    return availableVersion > currentVersion;
  }

  bool updateRequired() {
    return requiredVersion > currentVersion;
  }
}
