// Build configuration to detect if MLKit is available
// This will be true for standard builds and false for fdroid builds
// For fdroid builds, use: flutter build apk --dart-define=HAS_MLKIT=false --flavor fdroid
const bool hasMlKit = bool.fromEnvironment('HAS_MLKIT', defaultValue: true);
