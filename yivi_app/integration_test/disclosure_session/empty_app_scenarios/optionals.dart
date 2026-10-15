import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

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

  // First the required address is added: one step, with a choice between
  // the municipality and iDIN. The municipality starts selected.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddOption(0, 0), findsOneWidget);
  expect(findAddOption(0, 1), findsOneWidget);
  expect(find.text("Which one do you want to add?"), findsOneWidget);
  expectAddButtonFor(tester, "Demo Address");

  // The button opens the issuer's website; the test issues the card the
  // way that website would.
  await issueMunicipalityAddress(tester, irmaBinding);

  // Everything required is added: the share screen follows, with the
  // optional data not included yet.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);
  expect(find.text("OPTIONAL"), findsOneWidget);
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
