import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// Partial bundle: MijnOverheid.root + email pre-issued, MijnOverheid.fullName
/// needs to be issued during disclosure. Its spot has one way to fill it, so
/// tapping it opens the name's details at once. After issuing fullName, the
/// bundle whose credentialHashes contains the new fullName hash is selected:
/// the spot shows root + fullName as one 2-card item, next to the
/// pre-existing email.
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

  // Only the set is missing: one empty spot, the e-mail address in place.
  await waitForRequest(tester);
  expect(findEmptySpot(0), findsOneWidget);
  expect(findShareSlot(1), findsOneWidget);
  expect(shareButtonEnabled(tester), isFalse);

  // One way to fill the spot: the sheet opens on the name's details, and
  // "Add" opens the website while the sheet waits.
  await tapSpot(tester, 0);
  await tapAddOnDetails(tester);

  // The test issues the card the way that website would; it shows in the
  // sheet and the set lands in its spot.
  await issueMijnOverheidFullName(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);
  expect(findAddedNote(1), findsNothing);
  await tester.waitFor(find.byType(RequestorCard));

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
