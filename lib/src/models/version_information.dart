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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is VersionInformation &&
        currentVersion == other.currentVersion &&
        requiredVersion == other.requiredVersion &&
        availableVersion == other.availableVersion;
  }

  @override
  int get hashCode => Object.hash(currentVersion, requiredVersion, availableVersion);
}
