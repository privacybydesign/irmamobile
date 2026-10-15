import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/screens/session/widgets/session_requestor_header.dart";
import "package:yivi_core/src/widgets/irma_card.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> filledSpecificAttributeValuesNoMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Email address where domain has to be test.com
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.sidn-pbdf.email.email", { "type" : "irma-demo.sidn-pbdf.email.domain", "value": "sidn.nl" }  ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The owned e-mail address has the wrong domain, so one step adds one
  // that matches, and says what the domain must be.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  _expectRequiredValue("Email domain name", "sidn.nl");
  expect(find.byKey(const Key("add_wrong_note")), findsNothing);
  expectAddButtonFor(tester, "Demo Email address");

  // The issuer adds an e-mail address with the wrong domain.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@demo.com",
    "irma-demo.sidn-pbdf.email.domain": "demo.com",
  });

  // The step says so in place: what was added and what is needed, and the
  // button adds again.
  await tester.waitFor(find.byKey(const Key("add_wrong_note")));
  expect(findAddScreen(), findsOneWidget);
  _expectCompare("You added", "demo.com");
  _expectCompare("Needed", "sidn.nl");
  expect(addButtonTexts(tester).first, "Add again");

  // Now the issuer adds the right one: the share screen follows by itself.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@sidn.nl",
    "irma-demo.sidn-pbdf.email.domain": "sidn.nl",
  });
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);
  expect(find.byType(SessionRequestorHeader), findsOneWidget);

  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsOneWidget);
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [
      ("Email address", "test@sidn.nl"),
      ("Email domain name", "sidn.nl"),
    ],
    style: IrmaCardStyle.normal,
  );

  await tapShare(tester);
  await evaluateFeedback(tester);
}

/// The "must be …" row of the current step for [label].
void _expectRequiredValue(String label, String value) {
  final step = findAddStep(0);
  expect(find.descendant(of: step, matching: find.text(label)), findsOneWidget);
  expect(
    find.descendant(of: step, matching: find.text("must be $value")),
    findsOneWidget,
  );
}

/// The "You added" / "Needed" box of the current step: its [label] above
/// [value].
void _expectCompare(String label, String value) {
  final step = findAddStep(0);
  final labelFinder = find.descendant(of: step, matching: find.text(label));
  expect(labelFinder, findsOneWidget);
  expect(
    find.descendant(
      of: find
          .ancestor(of: labelFinder, matching: find.byType(Container))
          .first,
      matching: find.text(value),
    ),
    findsOneWidget,
  );
}
