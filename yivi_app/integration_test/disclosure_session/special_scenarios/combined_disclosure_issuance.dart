import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/screens/session/session_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_success_screen.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> combinedDisclosureIssuanceSessionTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueEmailAddress(tester, irmaBinding);

  // Email address
  // And receiving the  irma-demo.sidn-pbdf.uniqueid credential
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/issuance/v2",
          "credentials": [{
              "credential" : "irma-demo.sidn-pbdf.uniqueid",
              "attributes": {
                "uniqueid": "1234",
                "organization": "E-mail guild"
              }
            }],
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ]
            ]
          ]
        }
      ''';

  await irmaBinding.repository.startTestSession(sessionRequest);

  // One screen for both: what is shared, and the card that is received.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(
    find.text("Do you want to share this data and add a card?"),
    findsOneWidget,
  );
  expect(find.text("YOU RECEIVE"), findsOneWidget);
  expect(find.text("Demo Login data"), findsWidgets);
  expect(find.text("1234"), findsOneWidget);
  expect(find.text("Share and add card"), findsOneWidget);

  await tapShare(tester);

  final successScreenFinder = find.byType(IssuanceSuccessScreen);
  expect(successScreenFinder, findsOneWidget);

  await tester.tapAndSettle(find.text("OK"));

  expect(find.byType(SessionScreen), findsNothing);
}
