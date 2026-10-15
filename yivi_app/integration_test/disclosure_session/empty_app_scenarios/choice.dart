import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> choiceTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Email OR your mobile number.
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email" ],
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber" ]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // First, the missing data is added: one step, a choice between the
  // e-mail address and the mobile number. The first starts selected.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  expect(find.text("Which one do you want to add?"), findsOneWidget);
  _expectOption(
    0,
    0,
    "Demo Email address",
    "Demo Privacy by Design Foundation via SIDN",
  );
  expect(findAddOption(0, 1), findsOneWidget);
  expectAddButtonFor(tester, "Demo Email address");

  // The button opens the issuer's website; the test issues the card the
  // way that website would.
  await issueEmailAddress(tester, irmaBinding);

  // Everything is added: the share screen follows by itself.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(findAddScreen(), findsNothing);
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

/// Checks option [option] of step [step] on the add screen: its name and
/// "{issuer} · on {host}".
void _expectOption(int step, int option, String name, String issuer) {
  final row = findAddOption(step, option);
  expect(row, findsOneWidget);
  expect(find.descendant(of: row, matching: find.text(name)), findsWidgets);
  expect(
    find.descendant(
      of: row,
      matching: find.text("$issuer · on portal.yivi.app"),
    ),
    findsOneWidget,
  );
}
