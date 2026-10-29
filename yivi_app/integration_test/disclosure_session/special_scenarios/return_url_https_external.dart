import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
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

  // Same-device: the browser that started the session is on this phone, so the
  // client return URL is opened here on success.
  await irmaBinding.repository.startTestSession(
    sessionRequest,
    continueOnSecondDevice: false,
  );
  await waitForRequest(tester);

  await tapShare(tester);
  await tester.pumpAndSettle();

  // The done screen first: what was shared, and "Back to {host}" at the
  // top and as its button. Nothing opens before she taps it.
  await tester.waitFor(find.byKey(const Key("share_done_next")));
  expect(externalLaunches, isEmpty);
  expect(inAppLaunches, isEmpty);
  await tester.tapAndSettle(find.byKey(const Key("ok_button")));

  expect(externalLaunches, [_returnUrl]);
  expect(inAppLaunches, isEmpty);
  expect(find.byType(SessionScreen), findsNothing);
}
