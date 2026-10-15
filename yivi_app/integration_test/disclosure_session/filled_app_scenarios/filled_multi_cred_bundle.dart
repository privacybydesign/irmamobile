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

/// All three credentials pre-issued. The inner con on the first discon spans
/// two singleton credentials (MijnOverheid.root + MijnOverheid.fullName), so
/// the share screen renders that bundle as one tile of two cards. The second
/// discon (email OR mobile) has email pre-issued + mobile obtainable, so its
/// "Change" button is there.
Future<void> filledMultiCredBundleTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueMijnOverheidRoot(tester, irmaBinding);
  await issueMijnOverheidFullName(tester, irmaBinding);
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
  await waitForRequest(tester);

  // Straight to overview — nothing needs to be obtained.
  expect(find.byType(DisclosureShareScreen), findsOneWidget);
  await tester.waitFor(find.byType(SessionRequestorHeader));

  // Two tiles on the share screen: root + fullName (a bundle), and email.
  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsNWidgets(2));

  // The two cards that go together are one tile.
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
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
    cardsFinder.at(1),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [("Email address", "test@example.com")],
    style: IrmaCardStyle.normal,
  );

  // First discon has one bundle, no alternatives -> no Change.
  // Second discon has 1 owned (email) + 1 obtainable (mobile) -> Change.
  expect(find.byKey(const Key("share_change_0")), findsNothing);
  expect(find.byKey(const Key("share_change_1")), findsOneWidget);

  await tapShare(tester);
  await evaluateFeedback(tester);
}
