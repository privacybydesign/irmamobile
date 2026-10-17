import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> optionalsTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Address from iDIN or municipality
  // And optionally mobile number or e-mail address
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address" , "irma-demo.idin.idin.city" ]
            ],
            [
              [],
              [ "irma-demo.sidn-pbdf.email.email" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The request shows at once: the required address is an empty spot (the
  // municipality or iDIN), the optional data an "Add" row, not included.
  await waitForRequest(tester);
  expectEmptySpot(
    0,
    "Demo Address or Demo iDIN",
    hint: "Tap to choose which one to add",
  );
  expect(find.text("OPTIONAL"), findsOneWidget);
  expect(find.byKey(const Key("share_add_optional_1")), findsOneWidget);
  expectShareWaitsFor(tester, "Demo Address or Demo iDIN");

  // The address comes in without the sheet; it lands in its spot.
  await issueMunicipalityAddress(tester, irmaBinding);
  await expectAddedInPlace(tester, 0);
  expect(findShareSlot(1), findsNothing);

  // Add the e-mail address as optional data.
  await addOptional(tester, 1);
  await startAdding(tester, "irma-demo.sidn-pbdf.email");
  await issueEmailAddress(tester, irmaBinding);

  // Back from adding it, it is included, with a remove button.
  await tester.waitFor(findShareSlot(1));
  expect(findCardText(findShareSlot(1), "Demo Email address"), findsOneWidget);
  expect(find.byKey(const Key("share_remove_1")), findsOneWidget);

  // Leave it out again: the "Add" row comes back.
  await removeOptional(tester, 1);
  expect(findShareSlot(1), findsNothing);
  expect(find.byKey(const Key("share_add_optional_1")), findsOneWidget);

  // This time add the mobile number.
  await addOptional(tester, 1);
  await startAdding(tester, "irma-demo.sidn-pbdf.mobilenumber");
  await issueMobileNumber(tester, irmaBinding);

  // The optional card is the phone number now.
  await tester.waitFor(findShareSlot(1));
  expect(
    findCardText(findShareSlot(1), "Demo Mobile phone number"),
    findsOneWidget,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}
