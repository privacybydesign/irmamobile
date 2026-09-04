import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../irma_binding.dart";
import "empty_app_scenarios/age_missing.dart";
import "empty_app_scenarios/age_requested_value_missing.dart";
import "empty_app_scenarios/completely_optional_can_submit_empty.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("mdoc-disclosure-sessions", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    group("empty-app-scenarios", () {
      // The wallet holds no mdoc. An mdoc descriptor never carries an issue
      // URL, so every missing-required path ends in "Close".

      // Age document requested; wallet empty.
      testWidgets(
        "age-missing",
        (tester) => ageMissingTest(tester, irmaBinding),
      );

      // Age document with a required value requested; wallet empty. The
      // missing card shows the required value.
      testWidgets(
        "age-requested-value-missing",
        (tester) => ageRequestedValueMissingTest(tester, irmaBinding),
      );

      // Only-optional request; user can submit empty.
      testWidgets(
        "completely-optional-can-submit-empty",
        (tester) => completelyOptionalCanSubmitEmptyTest(tester, irmaBinding),
      );
    });
  });
}
