import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// Two-bundle choice with Bundle A partially pre-issued: MijnOverheid.root is
/// owned, MijnOverheid.fullName is missing. The Go-side createIssuanceBundle
/// filter removes the owned root from Bundle A in the wizard, so the wizard
/// only asks the user to add fullName. After it is added the share screen
/// shows Bundle A as one item with two cards (the pre-existing root and the
/// just-issued fullName); Bundle B remains obtainable so "Change" stays
/// visible.
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
  await waitForRequest(tester);

  // The add screen asks for the missing fullName of Bundle A. Bundle B is
  // still fully missing but Bundle A is the default selection, so the user
  // can complete the step by adding only fullName.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(
    find.descendant(of: findAddOption(0, 0), matching: find.text("Demo Name")),
    // The option's name, and its line in the list of what is added.
    findsWidgets,
  );
  expect(
    find.descendant(
      of: findAddOption(0, 1),
      matching: find.text("Demo iDIN + Demo Address"),
    ),
    findsOneWidget,
  );
  expectAddButtonFor(tester, "Demo Name");

  // The button opens the issuer's website; the test issues the card the
  // way that website would.
  await issueMijnOverheidFullName(tester, irmaBinding);

  await tester.waitFor(find.byType(DisclosureShareScreen));
  await tester.waitFor(find.byType(SessionRequestorHeader));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);

  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    findShareSlot(0),
    credentialName: "Demo Root + Demo Name",
    issuerName: "Demo MijnOverheid.nl",
    attributes: [
      ("BSN", "999999990"),
      ("First name", "Willeke"),
      ("Family name", "Bruijn"),
    ],
    style: IrmaCardStyle.normal,
  );

  // Bundle B remains obtainable -> the Change button is visible.
  expect(find.byKey(const Key("share_change_0")), findsOneWidget);

  await tapShare(tester);
  await evaluateFeedback(tester);
}
