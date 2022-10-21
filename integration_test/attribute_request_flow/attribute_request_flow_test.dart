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
import 'empty_app_scenarios/scenario_6.dart';
import 'empty_app_scenarios/scenario_7.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('attribute-request-flow', () {
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group('empty-app-scenarios', () {
      // Full name AND nationality
      testWidgets('scenario-1', (tester) => scenario1(tester, irmaBinding));

      // Email OR your mobile number.
      testWidgets('scenario-2', (tester) => scenario2(tester, irmaBinding));

      // Email AND mobile number
      testWidgets('scenario-3', (tester) => scenario3(tester, irmaBinding));

      // Address from multiplicity OR iDIN
      // AND your AGB code (from Nuts)
      testWidgets('scenario-4', (tester) => scenario4(tester, irmaBinding));

      // Student/employee id from university OR
      // Full name from municipality AND email address
      testWidgets('scenario-5', (tester) => scenario5(tester, irmaBinding));

      // Bank account number from iDeal. BIC has to be RABONL2U. AND
      // Initials, family name and city from iDIN. The city has to be Arnhem
      testWidgets('scenario-6', (tester) => scenario6(tester, irmaBinding));

      // Address from iDIN or municipality
      // And optionally mobile number or e-mail address
      testWidgets('scenario-7', (tester) => scenario7(tester, irmaBinding));
    });
  });
}
