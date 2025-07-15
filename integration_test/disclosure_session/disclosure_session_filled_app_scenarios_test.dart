import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../irma_binding.dart';
import 'filled_app_scenarios/filled_choice.dart';
import 'filled_app_scenarios/filled_choice_mixed.dart';
import 'filled_app_scenarios/filled_discon.dart';
import 'filled_app_scenarios/filled_no_choice_multiple_creds.dart';
import 'filled_app_scenarios/filled_no_choice_same_creds.dart';
import 'filled_app_scenarios/filled_optional_disjunction.dart';
import 'filled_app_scenarios/filled_specific_attribute_values_match.dart';
import 'filled_app_scenarios/filled_specific_attribute_values_no_match.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('disclosure-session', () {
    setUp(() async => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    group('filled-app-scenarios', () {
      // All these tests start with a filled app including:
      // An email address
      // Personal data from municipality

      // Email OR your mobile number.
      testWidgets('filled-choice', (tester) => filledChoiceTest(tester, irmaBinding));

      // Email AND telephone number
      testWidgets('filled-no-choice-multiple-creds', (tester) => filledNoChoiceMultipleCredsTest(tester, irmaBinding));

      // Requests only the email address,
      // but the app already has two email address
      testWidgets('filled-no-choice-same-creds', (tester) => filledNoChoiceSameCredsTest(tester, irmaBinding));

      // Address from municipality OR
      // Address from iDIN, with city
      testWidgets('filled-choice-mixed', (tester) => filledChoiceMixedTest(tester, irmaBinding));

      // Address from municipality OR
      // Address from iDIN AND
      // Email
      testWidgets('filled-discon', (tester) => filledDisconTest(tester, irmaBinding));

      // Address from municipality where city hast to be Arnhem AND
      // Email address where domain has to be test.com
      testWidgets(
        'filled-specific-attribute-values-match',
        (tester) => filledSpecificAttributeValuesMatchTest(tester, irmaBinding),
      );

      // Email address where domain has to be test.com
      testWidgets(
        'filled-specific-attribute-values-no-match',
        (tester) => filledSpecificAttributeValuesNoMatchTest(tester, irmaBinding),
      );

      // Email address and optionally a mobile number
      testWidgets('filled-optional-disjunction', (tester) => filledOptionalDisjunctionTest(tester, irmaBinding));
    });
  });
}
