import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../irma_binding.dart";
import "filled_app_scenarios/activity_log_after_disclosure.dart";
import "filled_app_scenarios/claim_sets_pick_first_satisfying.dart";
import "filled_app_scenarios/disclose_with_choice_disjunction.dart";
import "filled_app_scenarios/one_credential_two_choices.dart";
import "filled_app_scenarios/optional_extra_credential.dart";
import "filled_app_scenarios/partial_overlap_one_owned_one_missing.dart";
import "filled_app_scenarios/select_one_of_two_emails_and_two_phones.dart";
import "filled_app_scenarios/single_cred_email_and_domain.dart";
import "filled_app_scenarios/single_cred_email_only.dart";
import "filled_app_scenarios/two_credentials_two_choices_each.dart";
import "filled_app_scenarios/value_options_one_present_one_not.dart";
import "filled_app_scenarios/value_options_two_match.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("eudi-disclosure-sessions", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    group("filled-app-scenarios", () {
      // OID4VCI credentials are issued first, then disclosed via OpenID4VP.
      // Direct ports of the SD-JWT-over-OpenID4VP spine adapted for OID4VCI:
      // any "Obtain new data" affordance is greyed and disabled (no IssueURL).

      // Selective disclosure of a single attribute.
      testWidgets(
        "single-cred-email-only",
        (tester) => singleCredEmailOnlyTest(tester, irmaBinding),
      );

      // Disclose both attributes of a single credential.
      testWidgets(
        "single-cred-email-and-domain",
        (tester) => singleCredEmailAndDomainTest(tester, irmaBinding),
      );

      // DCQL claim_sets — wallet picks the first option whose claim set is
      // fully satisfied.
      testWidgets(
        "claim-sets-pick-first-satisfying",
        (tester) => claimSetsPickFirstSatisfyingTest(tester, irmaBinding),
      );

      // DCQL claim values: two of three issued creds match.
      testWidgets(
        "value-options-two-match",
        (tester) => valueOptionsTwoMatchTest(tester, irmaBinding),
      );

      // DCQL claim values: one of two issued creds matches.
      testWidgets(
        "value-options-one-present-one-not",
        (tester) => valueOptionsOnePresentOneNotTest(tester, irmaBinding),
      );

      // credential_sets with required: false — optional cred can be added /
      // removed in the overview.
      testWidgets(
        "optional-extra-credential",
        (tester) => optionalExtraCredentialTest(tester, irmaBinding),
      );

      // Two emails issued; user picks between them on change-choice screen.
      // Obtainable card is greyed and unselectable.
      testWidgets(
        "one-credential-two-choices",
        (tester) => oneCredentialTwoChoicesTest(tester, irmaBinding),
      );

      // Email AND phone, with two instances of each.
      testWidgets(
        "two-credentials-two-choices-each",
        (tester) => twoCredentialsTwoChoicesEachTest(tester, irmaBinding),
      );

      // OR disjunction across two cred types, two instances of each.
      testWidgets(
        "select-one-of-two-emails-and-two-phones",
        (tester) => selectOneOfTwoEmailsAndTwoPhonesTest(tester, irmaBinding),
      );

      // Email owned, phone missing. Backend hides the choices overview;
      // wallet shows IssueDuringDisclosureScreen with "Close" CTA.
      testWidgets(
        "partial-overlap-one-owned-one-missing",
        (tester) => partialOverlapOneOwnedOneMissingTest(tester, irmaBinding),
      );

      // OR disjunction; both options owned. Default selection + change-choice.
      testWidgets(
        "disclose-with-choice-disjunction",
        (tester) => discloseWithChoiceDisjunctionTest(tester, irmaBinding),
      );

      // Activity log + instance count decrement after a successful disclosure.
      testWidgets(
        "activity-log-after-disclosure",
        (tester) => activityLogAfterDisclosureTest(tester, irmaBinding),
      );
    });
  });
}
