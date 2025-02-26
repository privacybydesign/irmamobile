// There are some things we want to (not) do when running in integration tests
// this function is meant to tell whether we're running integration tests.
// Note that this implies that when starting integration tests we have to pass
// a compile time environment variable, like this:
// `flutter test integration_test --dart-define YIVI_INTEGRATION_TEST=true`
bool isRunningIntegrationTest() {
  return const bool.fromEnvironment('YIVI_INTEGRATION_TEST', defaultValue: false);
}
