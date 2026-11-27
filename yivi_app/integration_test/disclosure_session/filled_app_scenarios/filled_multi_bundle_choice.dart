import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/disclosure/disclosure_flow.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../disclosure_helpers.dart";

/// Two-bundle choice with Bundle A fully pre-issued. The discon offers two
/// alternative multi-cred bundles; Bundle A's two singletons (root + fullName)
/// are in the wallet, Bundle B (idin + gemeente.address) is fully obtainable.
/// User lands directly on the share screen showing Bundle A; the "Change"
/// button is there because Bundle B remains obtainable.
Future<void> filledMultiBundleChoiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueMijnOverheidRoot(tester, irmaBinding);
  await issueMijnOverheidFullName(tester, irmaBinding);

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

  // Straight to overview — Bundle A satisfies the discon.
  expect(find.byType(DisclosureFlow), findsOneWidget);
  await toOverview(tester);

  final cardsFinder = findCredentialCards();
  await openChangePage(tester);
  expect(cardsFinder, findsNWidgets(2));

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

  // Bundle B remains obtainable -> the Change button is there.
  await expectCanChange(tester, 0, true);

  await tapShare(tester);
  await evaluateFeedback(tester);
}
