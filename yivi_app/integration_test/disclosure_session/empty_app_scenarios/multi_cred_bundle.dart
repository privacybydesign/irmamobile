import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

/// Empty wallet. The share screen shows two empty spots: one for
/// MijnOverheid.root + MijnOverheid.fullName (the two singletons that together
/// satisfy the first discon's inner con) and one for email or mobile. Once
/// they are added, the spots show the 2-card bundle and the email card.
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

  // Two empty spots: the set of root + name, and e-mail or mobile.
  await waitForRequest(tester);
  expect(findEmptySpot(0), findsOneWidget);
  expectEmptySpot(1, "Demo Email address or Demo Mobile phone number");
  expect(shareButtonEnabled(tester), isFalse);

  // The cards of the set come in one by one (as from the issuer's own QR
  // codes); the first spot fills once both are there.
  await issueMijnOverheidRoot(tester, irmaBinding);
  expect(findEmptySpot(0), findsOneWidget);
  await issueMijnOverheidFullName(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);

  // E-mail or mobile is what Share waits for now. Mobile remains
  // obtainable once the e-mail address is in.
  expectShareWaitsFor(tester, "Demo Email address or Demo Mobile phone number");
  await issueEmailAddress(tester, irmaBinding);
  await expectAddedInPlace(tester, 1);
  await tester.waitFor(find.byType(SessionRequestorHeader));

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
