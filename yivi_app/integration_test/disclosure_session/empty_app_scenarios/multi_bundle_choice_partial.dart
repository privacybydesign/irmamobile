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

/// Two-bundle choice with Bundle A partially pre-issued: MijnOverheid.root is
/// owned, MijnOverheid.fullName is missing. The Go-side createIssuanceBundle
/// filter removes the owned root from Bundle A in the wizard, so the wizard
/// only asks the user to issue fullName. After issuance the overview renders
/// Bundle A's two cards (the pre-existing root and the just-issued fullName);
/// Bundle B remains obtainable so "Change choice" stays visible.
Future<void> multiBundleChoicePartialTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueMijnOverheidRoot(tester, irmaBinding);

  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [
                "irma-demo.MijnOverheid.root.BSN",
                "irma-demo.MijnOverheid.fullName.firstname",
                "irma-demo.MijnOverheid.fullName.familyname"
              ],
              [
                "irma-demo.idin.idin.initials",
                "irma-demo.idin.idin.familyname",
                "irma-demo.gemeente.address.street",
                "irma-demo.gemeente.address.houseNumber",
                "irma-demo.gemeente.address.city"
              ]
            ]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  // Wizard runs for the missing fullName credential of Bundle A. Bundle B is
  // still fully missing but Bundle A is the default selection, so the user
  // can complete the discon by issuing only fullName.
  expect(find.text("Collect data"), findsOneWidget);
  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);
  await issueMijnOverheidFullName(tester, irmaBinding);

  expect(find.text("All required data has been added."), findsOneWidget);
  await tester.tapAndSettle(find.text("Next step"));

  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  await tester.waitFor(find.byType(RequestorHeader));

  final cardsFinder = find.byType(YiviCredentialCard);
  expect(cardsFinder, findsNWidgets(2));

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

  // Bundle B remains obtainable -> Change choice button is visible.
  expect(find.text("Change choice"), findsOneWidget);

  await tester.tapAndSettle(find.text("Share data"));

  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
