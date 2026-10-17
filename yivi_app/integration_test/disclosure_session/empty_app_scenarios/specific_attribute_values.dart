import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> specificAttributeValuesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Bank account number from iDeal. BIC has to be RABONL2U. AND
  // Initials, family name and city from iDIN. The city has to be Arnhem
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.idin.idin.initials", "irma-demo.idin.idin.familyname", { "type" : "irma-demo.idin.idin.city", "value" : "Arnhem" }]
            ],
            [
              [ "irma-demo.ideal.ideal.iban", { "type": "irma-demo.ideal.ideal.bic", "value": "RABONL2U" }]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Two empty spots: iDIN (the city must be Arnhem) and iDEAL (the BIC must
  // be RABONL2U).
  await waitForRequest(tester);
  expectEmptySpot(0, "Demo iDIN");
  expectEmptySpot(1, "Demo iDEAL");
  expectShareWaitsFor(tester, "Demo iDIN");

  // The test issues the cards the way the issuers' websites would. First
  // the right iDIN credential: it lands in its spot.
  await issueIdin(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);
  expectShareWaitsFor(tester, "Demo iDEAL");

  // Now obtain the iDEAL credential with the wrong BIC
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.ideal.ideal.fullname": "John Doe",
    "irma-demo.ideal.ideal.iban": "NL60RABO5614740864",
    "irma-demo.ideal.ideal.bic": "INGBNL2A",
  });

  // The spot says so in place (no dialog): what was added next to what is
  // needed. It stays empty, and Share keeps waiting.
  final wrongFinder = find.descendant(
    of: findEmptySpot(1),
    matching: find.byKey(const Key("share_spot_wrong")),
  );
  await tester.waitFor(wrongFinder);
  expect(find.byType(Dialog), findsNothing);
  expect(
    tester.widget<Text>(wrongFinder).data,
    "You added INGBNL2A, needed RABONL2U. Tap to add it again.",
  );
  final palette = YiviPalette.of(tester.element(wrongFinder));
  expect(tester.widget<Text>(wrongFinder).style?.color, palette.errorText);
  expect(shareButtonEnabled(tester), isFalse);

  // Now issue the credential with requested BIC
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.ideal.ideal.fullname": "John Doe",
    "irma-demo.ideal.ideal.iban": "NL82RABO9763136946",
    "irma-demo.ideal.ideal.bic": "RABONL2U",
  });

  // The right card is in its place, without the note.
  await expectAddedInPlace(tester, 1);
  expect(find.byKey(const Key("share_spot_wrong")), findsNothing);
  await tapShare(tester);
  await evaluateFeedback(tester);
}
