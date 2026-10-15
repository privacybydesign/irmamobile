import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_share_screen.dart";

import "../../helpers/helpers.dart";
import "../../helpers/issuance_helpers.dart";
import "../../irma_binding.dart";
import "../../util.dart";
import "../disclosure_helpers.dart";

Future<void> choiceMixedTest(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
) async {
  await pumpAndUnlockApp(tester, irmaBinding.repository);

  // Session requesting:
  // Address from multiplicity OR address from iDIN
  // AND your AGB code (from Nuts)
  const sessionRequest = '''
        {
          "@context": "https://irma.app/ld/request/disclosure/v2",
          "disclose": [
            [
              [ "irma-demo.gemeente.address.street", "irma-demo.gemeente.address.houseNumber", "irma-demo.gemeente.address.city" ],
              [ "irma-demo.idin.idin.address", "irma-demo.idin.idin.city"]
            ],
            [
              [ "irma-demo.nuts.agb.agbcode"]
            ]
          ]
        }
      ''';

  // Start session without the credential being present.
  await irmaBinding.repository.startTestSession(sessionRequest);

  // Two steps to add: first the address (a choice), then the AGB code.
  await tester.waitFor(findAddScreen());
  expect(findAddStep(0), findsOneWidget);
  expect(findAddStep(1), findsOneWidget);
  expect(find.text("Which one do you want to add?"), findsOneWidget);

  // The address can come from the municipality or from iDIN, each saying
  // where it is added. The municipality starts selected.
  _expectOption(0, 0, "Demo Address", "Demo Municipality");
  _expectOption(0, 1, "Demo iDIN", "Demo iDIN");
  expectAddButtonFor(tester, "Demo Address");

  // Pick iDIN: the button follows.
  await pickSource(tester, 0, 1);
  expectAddButtonFor(tester, "Demo iDIN");

  // The button opens the issuer's website; the test issues the card the
  // way that website would.
  await issueIdin(tester, irmaBinding);

  // The first step is done, the AGB code is next.
  await tester.waitFor(
    find.descendant(of: findAddStep(0), matching: find.text("Added")),
  );
  expect(
    find.descendant(of: findAddStep(0), matching: find.text("Demo iDIN")),
    findsOneWidget,
  );
  expectAddButtonFor(tester, "Demo Vektis agb by Nuts");

  // Obtain the data from Nuts
  await issueCredentials(tester, irmaBinding, {
    "irma-demo.nuts.agb.agbcode": "7722255556",
  });

  // Everything is added: the share screen follows by itself.
  await tester.waitFor(find.byType(DisclosureShareScreen));
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
