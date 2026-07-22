import "package:flutter_test/flutter_test.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

// On a second-device session (QR shown on another device) the browser that
// started the session lives on that other device and honours the client return
// URL there. The wallet must therefore NOT open the return URL on the phone —
// it confirms success locally instead. See issue #656.

Future<void> _runDisregardTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required String returnUrl,
  required List<String> externalLaunches,
  required List<String> inAppLaunches,
}) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueEmailAddress(tester, irmaBinding);
  await tester.tapAndSettle(find.text("OK"));

  final sessionRequest =
      '''
       {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ],
          "clientReturnUrl": "$returnUrl"
       }
      ''';

  // Second-device is the default for test sessions; this is the case #656 is
  // about, so we rely on that default rather than annotating it.
  await irmaBinding.repository.startTestSession(sessionRequest);
  await evaluateIntroduction(tester);

  await tester.tapAndSettle(find.text("Share data"));
  await tester.tapAndSettle(find.text("Share"));
  await tester.pumpAndSettle();

  // The return URL must be disregarded — nothing is opened on the phone.
  expect(externalLaunches, isEmpty);
  expect(inAppLaunches, isEmpty);

  // Success is confirmed in-app instead (this also taps OK and asserts the
  // session flow is over).
  await evaluateFeedback(tester);
}

Future<void> returnUrlSecondDeviceExternalTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required List<String> externalLaunches,
  required List<String> inAppLaunches,
}) => _runDisregardTest(
  tester,
  irmaBinding,
  returnUrl: "https://example.com/done",
  externalLaunches: externalLaunches,
  inAppLaunches: inAppLaunches,
);

Future<void> returnUrlSecondDeviceInAppTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  required List<String> externalLaunches,
  required List<String> inAppLaunches,
}) => _runDisregardTest(
  tester,
  irmaBinding,
  returnUrl: "https://example.com/done?inapp=true",
  externalLaunches: externalLaunches,
  inAppLaunches: inAppLaunches,
);
