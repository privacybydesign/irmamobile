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

/// Partial bundle: MijnOverheid.root + email pre-issued, MijnOverheid.fullName
/// needs to be issued during disclosure. After issuing fullName, the
/// auto-issuance flow must find the bundle whose credentialHashes contains the
/// new fullName hash and pre-select it. Then the share screen shows root +
/// fullName as one 2-card item, plus the pre-existing email.
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

  // The add screen asks only for the missing fullName.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expectAddButtonFor(tester, "Demo Name");

  // The button opens the issuer's website; the test issues the card the
  // way that website would.
  await issueMijnOverheidFullName(tester, irmaBinding);

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
