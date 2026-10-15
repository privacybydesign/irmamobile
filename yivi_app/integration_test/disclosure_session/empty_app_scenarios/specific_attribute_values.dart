import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> specificAttributeValuesTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Bank account number from iDeal. BIC has to be RABONL2U. AND
  // Initials, family name and city from iDIN. The city has to be Arnhem
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.idin.idin.initials", "irma-demo.idin.idin.familyname", { "type" : "irma-demo.idin.idin.city", "value" : "Arnhem" }]
            ],
            [
              [ "irma-demo.ideal.ideal.iban", { "type": "irma-demo.ideal.ideal.bic", "value": "RABONL2U" }]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Two steps to add: iDIN (the city must be Arnhem), then iDEAL (the BIC
  // must be RABONL2U).
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsOneWidget);
  expectAddButtonFor(tester, "Demo iDIN");

  // The current step says which value is needed, in green. The requested
  // attributes without a value are not listed.
  final palette = YiviPalette.of(tester.element(findAddScreen()));
  _expectRequired(tester, 0, "City", "Arnhem", palette.successText);
  for (final name in ["Initials", "Family name"]) {
    expect(
      find.descendant(of: findAddStep(0), matching: find.text(name)),
      findsNothing,
    );
  }

  // The button opens the issuer's website; the test issues the card the
  // way that website would. First the right iDIN credential.
  await issueIdin(tester, irmaBinding);

  // iDIN is in; iDEAL is current, with its required BIC.
  await tester.waitFor(
    find.descendant(of: findAddStep(0), matching: find.text("Added")),
  );
  expectAddButtonFor(tester, "Demo iDEAL");
  _expectRequired(tester, 1, "BIC", "RABONL2U", palette.successText);

  // Now obtain the iDEAL credential with the wrong BIC
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.ideal.ideal.fullname": "John Doe",
    "irma-demo.ideal.ideal.iban": "NL60RABO5614740864",
    "irma-demo.ideal.ideal.bic": "INGBNL2A",
  });

  // The step says so in place (no dialog): what was added next to what is
  // needed, and the button adds again.
  final wrongNoteFinder = find.byKey(const Key("add_wrong_note"));
  await tester.waitFor(wrongNoteFinder);
  expect(find.byType(Dialog), findsNothing);
  expect(
    find.descendant(of: findAddStep(1), matching: find.text("You added")),
    findsOneWidget,
  );
  final addedValue = find.descendant(
    of: findAddStep(1),
    matching: find.text("INGBNL2A"),
  );
  expect(addedValue, findsOneWidget);
  expect(tester.widget<Text>(addedValue).style?.color, palette.errorText);
  expect(
    find.descendant(of: findAddStep(1), matching: find.text("Needed")),
    findsOneWidget,
  );
  expect(addButtonTexts(tester).first, "Add again");

  // Now issue the credential with requested BIC
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.ideal.ideal.fullname": "John Doe",
    "irma-demo.ideal.ideal.iban": "NL82RABO9763136946",
    "irma-demo.ideal.ideal.bic": "RABONL2U",
  });

  // Everything is added: the share screen follows by itself, without the
  // note.
  await tester.waitFor(find.byType(DisclosureShareScreen));
  expect(wrongNoteFinder, findsNothing);
  expect(find.byKey(const Key("share_added_banner")), findsOneWidget);
  await tapShare(tester);
  await evaluateFeedback(tester);
}

/// Checks that step [step] on the add screen lists [label] with "must be
/// [value]" in [color].
void _expectRequired(
  WidgetTester tester,
  int step,
  String label,
  String value,
  Color color,
) {
  expect(
    find.descendant(of: findAddStep(step), matching: find.text(label)),
    findsOneWidget,
  );
  final mustBe = find.descendant(
    of: findAddStep(step),
    matching: find.text("must be $value"),
  );
  expect(mustBe, findsOneWidget);
  expect(tester.widget<Text>(mustBe).style?.color, color);
}
