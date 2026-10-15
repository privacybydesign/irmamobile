import "package:flutter_test/flutter_test.dart";

import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

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

  // The member card is missing: one step to add it first, with its name
  // and issuer.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expect(
    find.descendant(
      of: findAddStep(0),
      matching: find.textContaining("IRMATube Member"),
    ),
    findsWidgets,
  );
  expect(
    find.descendant(
      of: findAddStep(0),
      matching: find.textContaining("Demo IRMATube"),
    ),
    findsWidgets,
  );
  // TODO Add check for the required/notNull attribute

  // TODO Add non matching credential

  // TODO Expect the wrong-card note (Key("add_wrong_note")) and evaluate it

  // TODO Add matching credential

  // TODO Complete flow
}
