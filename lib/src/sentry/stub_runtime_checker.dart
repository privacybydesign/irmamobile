import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Stub implementation of RuntimeChecker that does not rely on native integration.
/// This is useful for users that disabled automatic error reporting on iOS, but do want to manually report errors.
class StubRuntimeChecker extends RuntimeChecker {
  @override
  bool isDebugMode() => kDebugMode;

  @override
  bool isProfileMode() => kProfileMode;

  @override
  bool isReleaseMode() => kReleaseMode;
}
