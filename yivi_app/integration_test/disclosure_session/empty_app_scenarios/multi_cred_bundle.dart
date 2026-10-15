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

/// Empty wallet. The add screen asks for MijnOverheid.root +
/// MijnOverheid.fullName (the two singletons that together satisfy the first
/// discon's inner con) and then email (to satisfy the second discon). Then the
/// share screen shows the 2-card bundle for the first discon and the email
/// card for the second.
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

  // Two steps to add: the set of root + name, then e-mail or mobile.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsOneWidget);
  expect(find.text("These cards are only accepted together."), findsOneWidget);
  expect(find.byKey(const Key("add_checklist")), findsOneWidget);
  expectAddButtonFor(tester, "Demo Root");

  // The button opens the issuer's website; the test issues the cards the
  // way that website would. The cards of the set go one by one.
  await issueMijnOverheidRoot(tester, irmaBinding);
  await tester.waitFor(
    find.descendant(
      of: find.byKey(const Key("add_checklist")),
      matching: find.text("Added"),
    ),
  );
  expectAddButtonFor(tester, "Demo Name");
  await issueMijnOverheidFullName(tester, irmaBinding);

  // The set is done; e-mail or mobile is next, e-mail selected. Mobile
  // remains obtainable on the share screen.
  await tester.waitFor(
    find.descendant(of: findAddStep(0), matching: find.text("Added")),
  );
  expectAddButtonFor(tester, "Demo Email address");
  await issueEmailAddress(tester, irmaBinding);

  // Everything is added: the share screen follows by itself.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  await tester.waitFor(find.byType(SessionRequestorHeader));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);

  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsNWidgets(2));

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

  await evaluateCredentialCard(
    tester,
    findShareSlot(1),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  // First discon: single bundle, no alternative -> no Change.
  // Second discon: 1 owned (email) + 1 obtainable (mobile) -> Change.
  expect(find.byKey(const Key("share_change_0")), findsNothing);
  expect(find.byKey(const Key("share_change_1")), findsOneWidget);

  await tapShare(tester);
  await evaluateFeedback(tester);
}
