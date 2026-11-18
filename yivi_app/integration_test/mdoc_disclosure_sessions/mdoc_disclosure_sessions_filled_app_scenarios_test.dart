import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../irma_binding.dart";
import "filled_app_scenarios/activity_log_after_disclosure.dart";
import "filled_app_scenarios/age_requested_value_match.dart";
import "filled_app_scenarios/age_requested_value_no_match.dart";
import "filled_app_scenarios/age_single_claim.dart";
import "filled_app_scenarios/age_single_use_decrement.dart";
import "filled_app_scenarios/age_two_candidates_choice.dart";
import "filled_app_scenarios/age_two_thresholds.dart";
import "filled_app_scenarios/credential_set_age_or_pid.dart";
import "filled_app_scenarios/mdl_portrait_and_privileges.dart";
import "filled_app_scenarios/mixed_sdjwt_email_and_age.dart";
import "filled_app_scenarios/optional_extra_pid.dart";
import "filled_app_scenarios/pid_and_mdl_two_doctypes.dart";
import "filled_app_scenarios/pid_nested_values.dart";
import "filled_app_scenarios/pid_requested_value_one_of_two.dart";
import "filled_app_scenarios/pid_requested_value_two_match.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("mdoc-disclosure-sessions", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    group("filled-app-scenarios", () {
      // mdocs are issued by the staging EUDI Python issuer first, then
      // disclosed to the staging EUDI Kotlin verifier over OpenID4VP/DCQL.

      // Happy path: one claim, vouched verifier, presentation received.
      testWidgets(
        "age-single-claim",
        (tester) => ageSingleClaimTest(tester, irmaBinding),
      );

      // Two thresholds: a yes and a no.
      testWidgets(
        "age-two-thresholds",
        (tester) => ageTwoThresholdsTest(tester, irmaBinding),
      );

      // One copy spent per disclosure: 30 becomes 29.
      testWidgets(
        "age-single-use-decrement",
        (tester) => ageSingleUseDecrementTest(tester, irmaBinding),
      );

      // Requested value satisfied: sole owned option.
      testWidgets(
        "age-requested-value-match",
        (tester) => ageRequestedValueMatchTest(tester, irmaBinding),
      );

      // Requested value not satisfied: missing card with required value.
      testWidgets(
        "age-requested-value-no-match",
        (tester) => ageRequestedValueNoMatchTest(tester, irmaBinding),
      );

      // Several acceptable values on a string element: one of two matches.
      testWidgets(
        "pid-requested-value-one-of-two",
        (tester) => pidRequestedValueOneOfTwoTest(tester, irmaBinding),
      );

      // Several acceptable values: two match, user picks.
      testWidgets(
        "pid-requested-value-two-match",
        (tester) => pidRequestedValueTwoMatchTest(tester, irmaBinding),
      );

      // Two age mdocs: oldest first, newest pre-selected, switch and share.
      testWidgets(
        "age-two-candidates-choice",
        (tester) => ageTwoCandidatesChoiceTest(tester, irmaBinding),
      );

      // credential_sets: age or PID; only age owned, then both.
      testWidgets(
        "credential-set-age-or-pid",
        (tester) => credentialSetAgeOrPidTest(tester, irmaBinding),
      );

      // Optional PID next to a required age claim: add, remove, share.
      testWidgets(
        "optional-extra-pid",
        (tester) => optionalExtraPidTest(tester, irmaBinding),
      );

      // Structured PID values unfold into nested rows; dates read as dates.
      testWidgets(
        "pid-nested-values",
        (tester) => pidNestedValuesTest(tester, irmaBinding),
      );

      // mDL portrait as a picture, driving privileges as nested rows.
      testWidgets(
        "mdl-portrait-and-privileges",
        (tester) => mdlPortraitAndPrivilegesTest(tester, irmaBinding),
      );

      // Two document types in one request.
      testWidgets(
        "pid-and-mdl-two-doctypes",
        (tester) => pidAndMdlTwoDoctypesTest(tester, irmaBinding),
      );

      // SD-JWT over IRMA and an mdoc in one query.
      testWidgets(
        "mixed-sdjwt-email-and-age",
        (tester) => mixedSdJwtEmailAndAgeTest(tester, irmaBinding),
      );

      // The log entry names the verifier and the disclosed elements.
      testWidgets(
        "activity-log-after-disclosure",
        (tester) => activityLogAfterDisclosureTest(tester, irmaBinding),
      );
    });
  });
}
