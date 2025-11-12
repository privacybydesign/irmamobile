import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../irma_binding.dart';
import 'empty_app_scenarios/choice.dart';
import 'empty_app_scenarios/choice_mixed.dart';
import 'empty_app_scenarios/completely_optional.dart';
import 'empty_app_scenarios/no_choice.dart';
import 'empty_app_scenarios/no_choice_multiple_creds.dart';
import 'empty_app_scenarios/optionals.dart';
import 'empty_app_scenarios/specific_attribute_values.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('disclosure-session', () {
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group('empty-app-scenarios', () {
      // Full name AND nationality
      testWidgets(
        'no-choice',
        (tester) => noChoiceTest(tester, irmaBinding),
      );

      // Email OR your mobile number
      testWidgets(
        'choice',
        (tester) => choiceTest(tester, irmaBinding),
      );

      // Email AND mobile number
      testWidgets(
        'no-choice-multiple-creds',
        (tester) => noChoiceMultipleCredsTest(tester, irmaBinding),
      );

      // Address from multiplicity OR iDIN
      // AND your AGB code (from Nuts)
      testWidgets(
        'choice-mixed',
        (tester) => choiceMixedTest(tester, irmaBinding),
      );

      // TODO Fix this test
      // // Student/employee id from university OR
      // // Full name from municipality AND email address
      // testWidgets(
      //   'choice-mixed-sources',
      //   (tester) => choiceMixedSourcesTest(tester, irmaBinding),
      // );

      // Bank account number from iDeal. BIC has to be RABONL2U. AND
      // Initials, family name and city from iDIN. The city has to be Arnhem
      testWidgets(
        'specific-attribute-values',
        (tester) => specificAttributeValuesTest(tester, irmaBinding),
      );

      // Address from iDIN or municipality
      // And optionally mobile number or e-mail address
      testWidgets('optionals', (tester) => optionalsTest(tester, irmaBinding));

      // E-mail address or nothing
      testWidgets(
        'completely-optional',
        (tester) => completelyOptionalTest(tester, irmaBinding),
      );
    });
  });
}
