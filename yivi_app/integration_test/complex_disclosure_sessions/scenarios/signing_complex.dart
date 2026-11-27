import "package:flutter_test/flutter_test.dart";

import "../../disclosure_session/disclosure_helpers.dart";
import "../../helpers/helpers.dart";
import "../../irma_binding.dart";
import "../complex_disclosure_helpers.dart";

/// An IRMA signature with two cards, as two choices (the IRMA server allows
/// no two non-singleton types in one conjunction): signing words on the
/// screens, the paper with the signature at the end.
Future<void> signingComplexTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmails(tester, irmaBinding, ["a@one.example"]);
  await issuePhones(tester, irmaBinding, ["0611111111"]);

  await irmaBinding.repository.startTestSession('''
    {
      "@context": "https://irma.app/ld/request/signature/v2",
      "message": "Ik ga akkoord.",
      "disclose": [
        [ [ "irma-demo.sidn-pbdf.email.email" ] ],
        [ [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ] ]
      ]
    }
  ''');
  await waitForRequest(tester);
  expect(find.text("You sign a message for"), findsOneWidget);
  expect(find.text("THE MESSAGE"), findsOneWidget);
  await openChangePage(tester);
  expect(find.text("Choose what you sign with"), findsWidgets);
  await tapShare(tester);
  await evaluateFeedback(tester, isSignatureSession: true);
}
