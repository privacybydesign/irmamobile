import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

/// Two-bundle choice with Bundle A partially pre-issued: MijnOverheid.root is
/// owned, MijnOverheid.fullName is missing. The share screen shows an empty
/// spot; its sheet offers what is still missing, and only fullName needs to
/// be added. After it is added the spot shows Bundle A as one item with two
/// cards (the pre-existing root and the just-issued fullName); Bundle B
/// remains obtainable so "Change" stays visible.
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

  // The owned root alone does not fill the spot.
  expect(findEmptySpot(0), findsOneWidget);
  expect(shareButtonEnabled(tester), isFalse);

  // Its sheet offers the missing name (the owned root is not offered again)
  // and Bundle B's cards. The name is added in the sheet.
  await tapSpot(tester, 0);
  expect(findSheetAddRow("irma-demo.MijnOverheid.fullName"), findsOneWidget);
  expect(findSheetAddRow("irma-demo.MijnOverheid.root"), findsNothing);
  // Bundle B (iDIN and address, neither in the app) is one set to add.
  expect(
    findSheetAddRow("irma-demo.idin.idin+irma-demo.gemeente.address"),
    findsOneWidget,
  );
  await startAdding(tester, "irma-demo.MijnOverheid.fullName");

  // The test issues the card the way the website would; the issuance shows
  // in the sheet and the set lands in its spot.
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
