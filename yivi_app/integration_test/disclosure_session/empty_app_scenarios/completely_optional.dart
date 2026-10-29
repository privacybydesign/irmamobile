import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_tab.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/home/home_screen.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/widgets/credential_card/irma_empty_credential_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> completelyOptionalTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Scenario requesting:
  // E-mail address OR nothing
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              []
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Nothing is required: the share screen opens directly, with the e-mail
  // address as optional data that is not in the app yet.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byKey(const Key("share_lead")), findsOneWidget);
  expect(findShareSlot(0), findsNothing);

  // Add it: the sheet offers it under "Not in your app yet".
  await addOptional(tester, 0);
  expect(
    find.descendant(
      of: findChoiceSheet(),
      // "Add demo Email address": the name in sentence case.
      matching: find.textContaining("mail address"),
    ),
    findsWidgets,
  );
  await startAdding(tester, "irma-demo.sidn-pbdf.email");

  // The "Go to" button opens the issuer's website; the test issues the card
  // the way that website would. Back from it, the new card is included.
  await issueEmailAddress(tester, irmaBinding);
  await tester.waitFor(findShareSlot(0));
  expect(findChoiceSheet(), findsNothing);

  // Leave the optional data out again.
  await removeOptional(tester, 0);
  expect(findShareSlot(0), findsNothing);
  expect(find.text("Share without data"), findsOneWidget);

  await tapShare(tester);
  await evaluateFeedback(tester);

  //  start session again to verify that the email is still not pre-selected
  await irmaBinding.repository.startTestSession(sessionRequest);
  await tester.waitFor(find.byKey(const Key("share_button")));
  await tapShare(tester);
  await evaluateFeedback(tester);

  // Navigate to to activity tab
  expect(find.byType(HomeScreen), findsOneWidget);
  await tester.tap(find.byKey(const Key("nav_button_activity")));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(ActivityTab), findsOneWidget);

  // Tap the second activity card.
  // That's the session that is completely empty.
  final secondActivityCardFinder = find
      .byType(ActivityCard)
      .at(1)
      .hitTestable();
  await tester.scrollUntilVisible(
    secondActivityCardFinder,
    50,
    scrollable: activityScrollable(),
  );
  await tester.tapAndSettle(secondActivityCardFinder);

  // Expect the no data card
  expect(find.byType(IrmaEmptyCredentialCard), findsOneWidget);
}
