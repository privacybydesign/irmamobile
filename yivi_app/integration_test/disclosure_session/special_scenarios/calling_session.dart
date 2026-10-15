import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/call_info_screen.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> callingSessionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  await issueEmailAddress(tester, irmaBinding);
  await tester.tapAndSettle(find.text("OK"));

  // Session requesting:
  // Email or mobile number
  // And calling the number +31612345678" at the end
  const sessionRequest = '''
       {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ],
          "clientReturnUrl": "tel:+31612345678"
       }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);
  await waitForRequest(tester);

  // Share: the button is the consent, there is no confirmation dialog.
  await tapShare(tester);

  // Expect to be on the call info screen
  final callInfoScreenFinder = find.byType(CallInfoScreen);
  expect(callInfoScreenFinder, findsOneWidget);

  // The screen should have a IrmaAppBar with the right header
  final appBarFinder = find.byType(IrmaAppBar);
  expect(appBarFinder, findsOneWidget);

  const expectedAppBarText = "Call via Yivi";
  final appBarHeaderFinder = find.descendant(
    of: appBarFinder,
    matching: find.text(expectedAppBarText),
  );
  expect(appBarHeaderFinder, findsOneWidget);

  // Shared, now call: the requestor, the number and the call button.
  expect(
    find.text("Shared. Now call is.demo.staging.yivi.app"),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const Key("call_number")),
      matching: find.text("+31612345678"),
    ),
    findsOneWidget,
  );
  expect(find.text("Call is.demo.staging.yivi.app"), findsOneWidget);

  // Note: We don't press the call button because this will initiate the call,
  // which is not supported in integration tests.
}
