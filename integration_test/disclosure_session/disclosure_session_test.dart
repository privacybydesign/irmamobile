// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../irma_binding.dart';
import 'empty_app_scenarios/completely_optional.dart';
import 'empty_app_scenarios/no_choice.dart';
import 'empty_app_scenarios/choice.dart';
import 'empty_app_scenarios/no_choice_mlptl_creds.dart';
import 'empty_app_scenarios/choice_mixed.dart';
import 'empty_app_scenarios/choice_mixed_sources.dart';
import 'empty_app_scenarios/specific_att_values.dart';
import 'empty_app_scenarios/optionals.dart';
import 'filled_app_scenearios/filled_choice_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('disclosure-session', () {
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group(
      'empty-app-scenarios',
      () {
        // Full name AND nationality
        testWidgets(
          'no-choice',
          (tester) => noChoiceTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );

        // Email OR your mobile number.
        testWidgets(
          'choice',
          (tester) => choiceTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );

        // Email AND mobile number
        testWidgets(
          'no-choice-mltpl-creds',
          (tester) => noChoiceMltplCredsTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );

        // Address from multiplicity OR iDIN
        // AND your AGB code (from Nuts)
        testWidgets(
          'choice-mixed',
          (tester) => choiceMixedTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );

        // Student/employee id from university OR
        // Full name from municipality AND email address
        testWidgets(
          'choice-mixed-sources',
          (tester) => choiceMixedSourcesTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );

        // Bank account number from iDeal. BIC has to be RABONL2U. AND
        // Initials, family name and city from iDIN. The city has to be Arnhem
        testWidgets(
          'specific-att-values',
          (tester) => specificAttValuesTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );

        // Address from iDIN or municipality
        // And optionally mobile number or e-mail address
        testWidgets(
          'optionals',
          (tester) => optionalsTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );

        // E-mail address or nothing
        testWidgets(
          'completely-optional',
          (tester) => completelyOptionalTest(tester, irmaBinding),
          timeout: const Timeout(
            Duration(minutes: 1),
          ),
        );
      },
    );

    group('filled-app-scenarios', () {
      testWidgets(
        'filed-choice-test',
        (tester) => filledChoiceTest(tester, irmaBinding),
        timeout: const Timeout(
          Duration(minutes: 1),
        ),
      );
    });
  });
}
