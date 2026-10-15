import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> noChoiceMultipleCredsTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Email AND mobile number
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email"]
            ],
            [
              [ "irma-demo.sidn-pbdf.mobilenumber.mobilenumber"]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Two steps to add: the e-mail address first, then the mobile number.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsOneWidget);
  expect(
    find.descendant(
      of: findAddStep(0),
      matching: find.text(
        "Demo Privacy by Design Foundation via SIDN · on portal.yivi.app",
      ),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: findAddStep(1),
      matching: find.text("Demo Mobile phone number"),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(of: findAddStep(1), matching: find.text("Next")),
    findsOneWidget,
  );
  expectAddButtonFor(tester, "Demo Email address");

  // The button opens the issuer's website; the test issues the card the
  // way that website would.
  await issueEmailAddress(tester, irmaBinding);

  // The e-mail step is done, the mobile number is current now.
  await tester.waitFor(
    find.descendant(of: findAddStep(0), matching: find.text("Added")),
  );
  expectAddButtonFor(tester, "Demo Mobile phone number");

  await issueMobileNumber(tester, irmaBinding);

  // Everything is added: the share screen follows by itself, with a Change
  // button on both (another e-mail address or number can still be added).
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);
  expect(find.byKey(const Key("share_change_0")), findsOneWidget);
  expect(find.byKey(const Key("share_change_1")), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
}
