import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../irma_binding.dart";
import "empty_app_scenarios/completely_optional_can_submit_empty.dart";
import "empty_app_scenarios/cred_missing.dart";
import "empty_app_scenarios/disjunction_both_options_missing.dart";
import "empty_app_scenarios/multiple_creds_all_missing.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("eudi-disclosure-sessions", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    group("empty-app-scenarios", () {
      // Wallet has no OID4VCI credentials. Because OID4VCI credentials carry
      // no IssueURL, every "missing-required" path for OID4VCI ends in
      // "cannot proceed" — no obtain-during-disclosure is possible.

      // Single email cred requested; wallet empty.
      // Asserts IssueDuringDisclosureScreen with disabled "Close" CTA.
      testWidgets(
        "cred-missing",
        (tester) => credMissingTest(tester, irmaBinding),
      );

      // AND request for two creds; wallet empty.
      testWidgets(
        "multiple-creds-all-missing",
        (tester) => multipleCredsAllMissingTest(tester, irmaBinding),
      );

      // Disjunction (OR) request; neither option owned.
      testWidgets(
        "disjunction-both-options-missing",
        (tester) => disjunctionBothOptionsMissingTest(tester, irmaBinding),
      );

      // Only-optional disclosure request; user can submit empty.
      testWidgets(
        "completely-optional-can-submit-empty",
        (tester) => completelyOptionalCanSubmitEmptyTest(tester, irmaBinding),
      );
    });
  });
}
