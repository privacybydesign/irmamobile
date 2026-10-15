import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/add_missing_data_screen.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";

Future<void> nullablesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ { "type": "irma-demo.IRMATube.member.fullname", "notNull": true} ]
            ]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);

  // Expect obtain credential screen
  expect(find.byType(AddMissingDataScreen), findsOneWidget);
  expect(
    find.text(
      "Obtain the required data and share it with the requesting party after that.",
    ),
    findsOneWidget,
  );

  // One stepper should be visible
  expect(find.byKey(const Key("add_missing_data_list")), findsOneWidget);

  // One Credential card should be visible
  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo IRMATube Member",
    issuerName: "Demo IRMATube",
    attributes: [], // TODO Add check for the required/notNull attirbute
    style: IrmaCardStyle.highlighted,
  );

  // TODO Add non matching credential

  // TODO Expect the DisclosurePermissionWrongCredentialsAddedDialog and evaluate it

  // TODO Add matching credential

  // TODO Complete flow
}
