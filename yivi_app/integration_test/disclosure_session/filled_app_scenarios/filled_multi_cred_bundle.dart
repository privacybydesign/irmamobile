import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
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
  expect(find.byType(DisclosureFlow), findsOneWidget);
  await toOverview(tester);

  // On the change page: the root and the name (one set), and the e-mail.
  final cardsFinder = findCredentialCards();
  await openChangePage(tester);
  expect(cardsFinder, findsNWidgets(3));

  // The set is one card on the change page, with a head per card.
  await evaluateCredentialCard(
    tester,
    cardsFinder.at(0),
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

  // First discon has one bundle, no alternatives -> no Change.
  // Second discon has 1 owned (email) + 1 obtainable (mobile) -> Change.
  await expectCanChange(tester, 0, false);
  await expectCanChange(tester, 1, true);

  await tapShare(tester);
  await evaluateFeedback(tester);
}
