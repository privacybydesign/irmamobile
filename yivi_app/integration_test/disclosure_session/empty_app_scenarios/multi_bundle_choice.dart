import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/screens/add_data/schemaless_add_data_details_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_discon_stepper.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_permission_choice.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";
import "package:yivi_core/src/widgets/irma_card.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// Two-bundle choice with an empty wallet. The discon offers:
///
/// - Bundle A: MijnOverheid.root + MijnOverheid.fullName (2 singletons)
/// - Bundle B: idin.idin + gemeente.address (2 singletons)
///
/// Default selection is Bundle A (option index 0). The user does not tap the
/// other option; they issue Bundle A's credentials one by one. After both are
/// issued, the overview shows Bundle A. Bundle B remains obtainable so
/// "Change choice" is visible.
Future<void> multiBundleChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

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

  // Wizard runs. The discon-stepper renders one DisclosurePermissionChoice
  // with two bundle options (Bundle A + Bundle B).
  final disConStepperFinder = find.byType(DisclosureDisconStepper);
  expect(disConStepperFinder, findsOneWidget);

  final choiceFinder = find.descendant(
    of: disConStepperFinder,
    matching: find.byType(DisclosurePermissionChoice),
  );
  expect(choiceFinder, findsOneWidget);

  // Bundle A's first card (Demo Root) is selected by default. Both bundles
  // are rendered side-by-side: Bundle A has 2 cards, Bundle B has 2 cards.
  final choiceCardsFinder = find.descendant(
    of: choiceFinder,
    matching: find.byType(YiviCredentialCard),
  );
  expect(choiceCardsFinder, findsNWidgets(4));
  await evaluateCredentialCard(
    tester,
    choiceCardsFinder.first,
    credentialName: "Demo Root",
    issuerName: "Demo MijnOverheid.nl",
    isSelected: true,
  );

  // Issue Bundle A's two credentials in order.
  await tester.tapAndSettle(find.text("Obtain data"));
  expect(find.byType(SchemalessAddDataDetailsScreen), findsOneWidget);
  await issueMijnOverheidRoot(tester, irmaBinding);

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
