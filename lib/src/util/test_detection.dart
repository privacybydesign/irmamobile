bool isRunningInTest() {
  const inTest = bool.fromEnvironment('YIVI_TEST', defaultValue: false);
  return inTest;
}
