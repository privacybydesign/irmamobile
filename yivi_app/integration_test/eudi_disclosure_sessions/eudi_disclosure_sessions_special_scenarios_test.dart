import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../irma_binding.dart";
import "special_scenarios/decline_disclosure.dart";
import "special_scenarios/disclose_nested_organization_credential.dart";
import "special_scenarios/low_instance_count_no_reobtain.dart";
import "special_scenarios/zero_instance_count_no_reobtain.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("eudi-disclosure-sessions", () {
    setUp(() async => await irmaBinding.setUp());
    tearDown(() async => await irmaBinding.tearDown());

    group("special-scenarios", () {
      // User cancels at the share-confirm dialog.
      testWidgets(
        "decline-disclosure",
        (tester) => declineDisclosureTest(tester, irmaBinding),
      );

      // Issued via batch2-issuer; both batch instances are drained by two
      // disclosures, then the details-screen card shows danger styling but
      // no Reobtain button (no IssueURL on OID4VCI creds).
      testWidgets(
        "zero-instance-count-no-reobtain",
        (tester) => zeroInstanceCountNoReobtainTest(tester, irmaBinding),
      );

      // Issued via batch2-issuer; 2 ≤ low-instance threshold (5), so the
      // details-screen card shows expiring-soon styling immediately, but
      // again no Reobtain button.
      testWidgets(
        "low-instance-count-no-reobtain",
        (tester) => lowInstanceCountNoReobtainTest(tester, irmaBinding),
      );

      // Disclose the OrganizationCredentialSdJwt's deeply nested data and
      // verify nested attribute rendering on the disclosure card.
      testWidgets(
        "disclose-nested-organization-credential",
        (tester) =>
            discloseNestedOrganizationCredentialTest(tester, irmaBinding),
      );
    });
  });
}
