import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/add_data/schemaless_add_data_details_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// Partial bundle: MijnOverheid.root + email pre-issued, MijnOverheid.fullName
/// needs to be issued during disclosure. After issuing fullName, the
/// auto-issuance flow must find the bundle whose credentialHashes contains the
/// new fullName hash and pre-select it. Then the overview renders root +
/// fullName as a 2-card bundle, plus the pre-existing email.
Future<void> multiCredBundlePartialTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueMijnOverheidRoot(tester, irmaBinding);
  await issueEmailAddress(tester, irmaBinding);

  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [[
              "irma-demo.MijnOverheid.root.BSN",
              "irma-demo.MijnOverheid.fullName.firstname",
              "irma-demo.MijnOverheid.fullName.familyname"
            ]],
            [["irma-demo.sidn-pbdf.email.email"], ["irma-demo.sidn-pbdf.mobilenumber.mobilenumber"]]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // The wizard runs for the missing fullName credential.
  expect(find.text("Collect data"), findsOneWidget);
  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);
  await issueMijnOverheidFullName(tester, irmaBinding);

  // Wizard should be completed and we advance to the overview.
  expect(find.text("All required data has been added."), findsOneWidget);
  await tester.tapAndSettle(find.text("Next step"));

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  await tester.waitFor(find.byType(RequestorHeader));

  final cardsFinder = find.byType(YiviCredentialCard);
  expect(cardsFinder, findsNWidgets(3));

  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Root",
    issuerName: "Demo MijnOverheid.nl",
    attributes: [("BSN", "999999990")],
    style: IrmaCardStyle.normal,
  );

  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: "Demo Name",
    issuerName: "Demo MijnOverheid.nl",
    attributes: [("First name", "Willeke"), ("Family name", "Bruijn")],
    style: IrmaCardStyle.normal,
  );

  await evaluateCredentialCard(
    tester,
    cardsFinder.at(2),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  // First discon: single bundle, no alternative -> no Change choice.
  // Second discon: 1 owned (email) + 1 obtainable (mobile) -> Change choice.
  expect(find.text("Change choice"), findsOneWidget);

  await tester.tapAndSettle(find.text("Share data"));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
