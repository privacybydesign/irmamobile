// We cannot test using null safety as long as there are widgets that are not migrated yet.
// @dart=2.11

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../irma_binding.dart';
import 'empty_app_scenarios/choice.dart';
import 'empty_app_scenarios/choice_mixed.dart';
import 'empty_app_scenarios/choice_mixed_sources.dart';
import 'empty_app_scenarios/completely_optional.dart';
import 'empty_app_scenarios/no_choice.dart';
import 'empty_app_scenarios/no_choice_mlptl_creds.dart';
import 'empty_app_scenarios/optionals.dart';
import 'empty_app_scenarios/specific_att_values.dart';
import 'filled_app_scenearios/filled_choice_mixed.dart';
import 'filled_app_scenearios/filled_choice_test.dart';
import 'filled_app_scenearios/filled_discon.dart';
import 'filled_app_scenearios/filled_no_choice_multiple_creds.dart';
import 'filled_app_scenearios/filled_specific_attribute_values_match.dart';
import 'filled_app_scenearios/filled_specific_attribute_values_no_match.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  const generalTimeout = Timeout(Duration(minutes: 1));

  group('disclosure-session', () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group(
      'empty-app-scenarios',
      () {
        // Full name AND nationality
        testWidgets(
          'no-choice',
          (tester) => noChoiceTest(tester, irmaBinding),
          timeout: generalTimeout,
        );

        // Email OR your mobile number
        testWidgets(
          'choice',
          (tester) => choiceTest(tester, irmaBinding),
          timeout: generalTimeout,
        );

        // Email AND mobile number
        testWidgets(
          'no-choice-mltpl-creds',
          (tester) => noChoiceMltplCredsTest(tester, irmaBinding),
          timeout: generalTimeout,
        );

        // Address from multiplicity OR iDIN
        // AND your AGB code (from Nuts)
        testWidgets(
          'choice-mixed',
          (tester) => choiceMixedTest(tester, irmaBinding),
          timeout: generalTimeout,
        );

        // Student/employee id from university OR
        // Full name from municipality AND email address
        testWidgets(
          'choice-mixed-sources',
          (tester) => choiceMixedSourcesTest(tester, irmaBinding),
          timeout: generalTimeout,
        );

        // Bank account number from iDeal. BIC has to be RABONL2U. AND
        // Initials, family name and city from iDIN. The city has to be Arnhem
        testWidgets(
          'specific-att-values',
          (tester) => specificAttValuesTest(tester, irmaBinding),
          timeout: generalTimeout,
        );

        // Address from iDIN or municipality
        // And optionally mobile number or e-mail address
        testWidgets(
          'optionals',
          (tester) => optionalsTest(tester, irmaBinding),
          timeout: generalTimeout,
        );

        // E-mail address or nothing
        testWidgets(
          'completely-optional',
          (tester) => completelyOptionalTest(tester, irmaBinding),
          timeout: generalTimeout,
        );
      },
    );

    group('filled-app-scenarios', () {
      // All these tests start with a filled app including:
      // An email address
      // Personal data from municipality

      // Email OR your mobile number.
      testWidgets(
        'filled-choice-test',
        (tester) => filledChoiceTest(tester, irmaBinding),
        timeout: generalTimeout,
      );

      // Email AND telephone number
      testWidgets(
        'filled-no-choice-multiple-creds',
        (tester) => filledNoChoiceMultipleCredsTest(tester, irmaBinding),
        timeout: generalTimeout,
      );

      // Address from municipality OR
      // Address from iDIN, with city
      testWidgets(
        'filled-choice-mixed',
        (tester) => filledChoiceMixedTest(tester, irmaBinding),
        timeout: generalTimeout,
      );

      // Address from municipality OR
      // Address from iDIN AND
      // Email
      testWidgets(
        'filled-discon',
        (tester) => filledDisconTest(tester, irmaBinding),
        timeout: generalTimeout,
      );

      // Address from municipality where city hast to be Arnhem AND
      // Email address where domain has to be test.com
      testWidgets(
        'filled-specific-attribute-values-match',
        (tester) => filledSpecificAttributeValuesMatchTest(tester, irmaBinding),
        timeout: generalTimeout,
      );

      // Email address where domain has to be test.com
      testWidgets(
        'filled-specific-attribute-values-no-match',
        (tester) => filledSpecificAttributeValuesNoMatchTest(tester, irmaBinding),
        timeout: generalTimeout,
      );
    });
  });
}
