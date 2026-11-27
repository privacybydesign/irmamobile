import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

/// Two-bundle choice with an empty wallet. The discon offers:
///
/// - Bundle A: MijnOverheid.root + MijnOverheid.fullName (2 singletons)
/// - Bundle B: idin.idin + gemeente.address (2 singletons)
///
/// The request shows at once with an empty spot. The user adds Bundle A's
/// credentials one by one; the spot stays empty until the set is complete,
/// then shows Bundle A. Bundle B remains obtainable so "Change" is visible.
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

  // One empty spot: neither set is in the app. Share waits for it.
  await waitForRequest(tester);
  expect(findEmptySpot(0), findsOneWidget);
  expect(
    find.descendant(
      of: findEmptySpot(0),
      matching: find.text("Choose from two options"),
    ),
    findsOneWidget,
  );
  expect(shareButtonEnabled(tester), isFalse);

  // The cards of a set come in one by one (here without the sheet, as from
  // the issuer's own QR codes): root first. One card of the set does not
  // fill the spot yet.
  await issueMijnOverheidRoot(tester, irmaBinding);
  expect(findEmptySpot(0), findsOneWidget);
  expect(shareButtonEnabled(tester), isFalse);

  // With the name the set is complete: Bundle A is in its place, as one
  // item of two cards.
  await issueMijnOverheidFullName(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);
  await toOverview(tester);

  // On the change page the set is one card with two heads.
  await openChangePage(tester);
  final cardsFinder = findCredentialCards();
  await openChangePage(tester);
  expect(cardsFinder, findsNWidgets(2));
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

  // Bundle B remains obtainable -> the Change button is visible.
  await expectCanChange(tester, 0, true);

  await tapShare(tester);
  await evaluateFeedback(tester);
}
