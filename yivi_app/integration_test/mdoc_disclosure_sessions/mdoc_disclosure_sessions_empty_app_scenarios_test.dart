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
      //
      // Skipped: the wallet is conformant here but the EUDI reference verifier
      // is not. With one optional credential set and nothing to match it,
      // OpenID4VP 1.0 section 8.1 requires the REQUIRED vp_token parameter to
      // be present and to carry no entry ("There MUST NOT be any entry in the
      // JSON-encoded object for optional Credential Queries when there are no
      // matching Credentials"), so irmago posts vp_token={} -- and the
      // reference verifier answers that with a 500, failing the session.
      //
      // The wallet side of this shape stays covered by irmago's
      // testDcApiMdocSkippedOptionalSet (over the DC API, for this same
      // reason) and by the SD-JWT twin of this test against Veramo. Re-enable
      // once the reference verifier accepts an empty vp_token over
      // direct_post.
      testWidgets(
        "completely-optional-can-submit-empty",
        (tester) => completelyOptionalCanSubmitEmptyTest(tester, irmaBinding),
        skip: true,
      );
    });
  });
}
