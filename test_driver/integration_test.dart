import 'package:integration_test/integration_test_driver.dart';

// There is a known bug that sometimes the isolates are paused, which causes the tests to hang.
// https://github.com/flutter/flutter/issues/73355
Future<void> main() => integrationDriver();
