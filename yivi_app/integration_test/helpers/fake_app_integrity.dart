import "package:yivi_core/src/screens/app_integrity/app_integrity.dart";

/// The integration tests run on emulators and under test tooling, and the iOS
/// ones as a release build, so they never look at the real environment.
class FakeAppIntegrity implements AppIntegrity {
  final IntegrityReport report;

  const FakeAppIntegrity([this.report = IntegrityReport.clean]);

  @override
  Future<IntegrityReport> check() async => report;
}
