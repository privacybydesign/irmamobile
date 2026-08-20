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

/// Empty wallet. The wizard must issue MijnOverheid.root + MijnOverheid.fullName
/// (the two singletons that together satisfy the first discon's inner con) plus
/// email (to satisfy the second discon). Then the overview renders the 2-card
/// bundle for the first discon and the email card for the second.
Future<void> multiCredBundleTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

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

  // Wizard runs for all missing credentials.
  expect(find.text("Collect data"), findsOneWidget);
  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);

  // Issue the credentials one by one; the wizard sees each new credential and
  // advances. For the second discon (email OR mobile), we satisfy it with
  // email — mobile remains obtainable on the overview.
  await issueMijnOverheidRoot(tester, irmaBinding);
  await issueMijnOverheidFullName(tester, irmaBinding);
  await issueEmailAddress(tester, irmaBinding);

  // Wizard should be completed.
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
