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

Future<void> filledSpecificAttributeValuesMatchTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);
  await issueDemoCredentials(tester, irmaBinding);

  // Address from municipality where city hast to be Arnhem AND
  // Email address where domain has to be test.com
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street" , "irma-demo.gemeente.address.houseNumber", { "type" : "irma-demo.gemeente.address.city", "value": "Arnhem" }  ]
            ],
            [
              [ "irma-demo.sidn-pbdf.email.email" , { "type" : "irma-demo.sidn-pbdf.email.domain" , "value" : "test.com"} ]
            ]
          ]
        }
      ''';
  await irmaBinding.repository.startTestSession(sessionRequest);

  // The e-mail address is missing: one step, which says what the domain
  // must be.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsNothing);
  _expectRequiredValue("Email domain name", "test.com");
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
  _expectCompare("Needed", "test.com");
  expect(addButtonTexts(tester).first, "Add again");

  // Now the issuer adds the right one: the share screen follows by itself.
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.sidn-pbdf.email.email": "test@test.com",
    "irma-demo.sidn-pbdf.email.domain": "test.com",
  });
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);
  expect(find.byType(SessionRequestorHeader), findsOneWidget);

  final cardsFinder = findCredentialCards();
  expect(cardsFinder, findsNWidgets(2));
  await evaluateCredentialCard(
    tester,
    cardsFinder.first,
    credentialName: "Demo Address",
    issuerName: "Demo Municipality",
    attributes: [
      ("Street", "Meander"),
      ("House number", "501"),
      ("City", "Arnhem"),
    ],
    style: IrmaCardStyle.normal,
  );

  await evaluateCredentialCard(
    tester,
    cardsFinder.at(1),
    credentialName: "Demo Email address",
    issuerName: "Demo Privacy by Design Foundation via SIDN",
    attributes: [
      ("Email address", "test@test.com"),
      ("Email domain name", "test.com"),
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
