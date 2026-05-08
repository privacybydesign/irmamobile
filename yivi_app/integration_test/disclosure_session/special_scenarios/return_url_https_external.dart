import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

const _returnUrl = "https://example.com/done";

Future<void> returnUrlHttpsExternalTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required List<String> externalLaunches,
  required List<String> inAppLaunches,
}) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueEmailAddress(tester, irmaBinding);
  await tester.tapAndSettle(find.text("OK"));

  const sessionRequest =
      '''
       {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ],
          "clientReturnUrl": "$_returnUrl"
       }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  await tester.tapAndSettle(find.text("Share data"));
  await tester.tapAndSettle(find.text("Share"));

  // The success-path post-frame callback fires openURLExternally and pops.
  // pumpAndSettle runs the microtask + frame queue until everything settles.
  await tester.pumpAndSettle();

  expect(externalLaunches, [_returnUrl]);
  expect(inAppLaunches, isEmpty);
  expect(find.byType(SessionScreen), findsNothing);
}
