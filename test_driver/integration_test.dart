import 'package:integration_test/integration_test_driver.dart';

// There is a known bug that sometimes the isolates are paused, which causes the tests to hang.
// https://github.com/flutter/flutter/issues/73355
// This issue can be resolved by switching from 'flutter drive' to 'flutter test'. This can
// only be done when `flutter test` gets support for '--flavor' (check issue below).
// Then, this file can be removed.
// https://github.com/flutter/flutter/issues/82898
Future<void> main() => integrationDriver();
