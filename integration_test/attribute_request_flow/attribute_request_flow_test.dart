// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../irma_binding.dart';
import 'empty_app_scenarios/scenario_1.dart';
import 'empty_app_scenarios/scenario_2.dart';
import 'empty_app_scenarios/scenario_3.dart';
import 'empty_app_scenarios/scenario_4.dart';
import 'empty_app_scenarios/scenario_5.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('attribute-request-flow', () {
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group('empty-app-scenarios', () {
      // Share your full name AND nationality
      testWidgets('scenario-1', (tester) => scenario1(tester, irmaBinding));

      // Share your email OR your mobile number.
      testWidgets('scenario-2', (tester) => scenario2(tester, irmaBinding));

      // Share your email AND mobile number
      testWidgets('scenario-3', (tester) => scenario3(tester, irmaBinding));

      // Address from multiplicity OR your AGB code (from Nuts)
      testWidgets('scenario-4', (tester) => scenario4(tester, irmaBinding));

      // Student/employee id from university OR full name from municipality AND email address
      testWidgets('scenario-5', (tester) => scenario5(tester, irmaBinding));
    });
  });
}
