import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/data/schemaless_credentials_details_screen.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/sections/card_sections.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "helpers/helpers.dart";
import "helpers/issuance_helpers.dart";
import "irma_binding.dart";
import "util.dart";

/// The "Show as list" card option: an identity credential's card switches
/// from its card sections to the plain list of every attribute, stays that
/// way when the screen is opened again, and switches back.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("raw-list-card", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("switch-to-list-and-back", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await issueMunicipalityPersonalData(tester, irmaBinding);
      await tester.tapAndSettle(find.text("OK"));

      final card = find.byType(YiviCredentialCard);

      Future<void> openDetails() async {
        await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
        final tile = find
            .byKey(const Key("irma-demo.gemeente.personalData_tile"))
            .hitTestable();
        await tester.scrollUntilVisible(tile, 75);
        await tester.tapAndSettle(tile);
        expect(find.byType(SchemalessCredentialsDetailsScreen), findsOneWidget);
        expect(card, findsOneWidget);
      }

      Future<void> chooseOption(String label) async {
        await tester.tapAndSettle(
          find.descendant(
            of: card,
            matching: find.byIcon(Icons.more_horiz_sharp),
          ),
        );
        await tester.tapAndSettle(find.text(label));
      }

      Future<void> expectList() async {
        expect(find.byType(CardSections), findsNothing);
        await evaluateCredentialCard(
          tester,
          card,
          attributes: [
            ("Full name", "W.L. de Bruijn"),
            ("Initials", "W.L."),
            ("First names", "Willeke Liselotte"),
            ("Prefix", "de"),
            ("Surname", "de Bruijn"),
            ("Family name", "Bruijn"),
            ("Gender", "V"),
            ("Date of birth", "10-04-1965"),
            ("Over 12", "Yes"),
            ("Over 16", "Yes"),
            ("Over 18", "Yes"),
            ("Over 21", "Yes"),
            ("Over 65", "No"),
            ("Dutch nationality", "Yes"),
            ("City of birth", "Arnhem"),
            ("Country of birth", "Arnhem"),
            ("BSN", "999999990"),
            ("Assurance level", "Substantieel"),
          ],
        );
      }

      await openDetails();
      expect(find.byType(CardSections), findsOneWidget);

      await chooseOption("Show as list");
      await expectList();

      // Remembered for the credential type.
      await tester.tapAndSettle(find.byKey(const Key("irma_app_bar_leading")));
      await openDetails();
      await expectList();

      await chooseOption("Show as card");
      expect(find.byType(CardSections), findsOneWidget);
      evaluateCardSections(
        tester,
        card,
        titles: ["PERSON", "NAME", "REGISTRATION"],
      );
    });
  });
}
