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

/// Two-bundle choice with an empty wallet. The discon offers:
///
/// - Bundle A: MijnOverheid.root + MijnOverheid.fullName (2 singletons)
/// - Bundle B: idin.idin + gemeente.address (2 singletons)
///
/// Default selection is Bundle A (option index 0). The user does not tap the
/// other option; they add Bundle A's credentials one by one. After both are
/// added, the share screen shows Bundle A. Bundle B remains obtainable so
/// "Change" is visible.
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

  // One step to add, with two options that are each a set of two cards.
  // Bundle A starts selected.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expect(
    find.descendant(
      of: findAddOption(0, 0),
      matching: find.text("Demo Root + Demo Name"),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: findAddOption(0, 1),
      matching: find.text("Demo iDIN + Demo Address"),
    ),
    findsOneWidget,
  );

  // The cards of a set are added one by one: root first.
  expect(find.byKey(const Key("add_checklist")), findsOneWidget);
  expectAddButtonFor(tester, "Demo Root");

  // The button opens the issuer's website; the test issues the cards the
  // way that website would.
  await issueMijnOverheidRoot(tester, irmaBinding);

  // Root is in; the name is next.
  await tester.waitFor(
    find.descendant(
      of: find.byKey(const Key("add_checklist")),
      matching: find.text("Added"),
    ),
  );
  expectAddButtonFor(tester, "Demo Name");
  await issueMijnOverheidFullName(tester, irmaBinding);

  // Everything is added: the share screen follows by itself, with Bundle A
  // as one item of two cards.
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
