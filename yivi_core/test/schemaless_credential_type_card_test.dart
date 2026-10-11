import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";

import "helpers/data_tab_fixtures.dart";

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  // Regression for the IrmaAvatar assert crash: a credential whose display name
  // could not be resolved (empty) and that has no logo must still render. The
  // avatar falls back to the issuer's initial.
  testWidgets("renders with an empty credential name and no image", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SchemalessYiviCredentialTypeCard(
          credentialId: "some.cred",
          credentialName: "",
          issuerName: "Acme",
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Avatar falls back to the issuer's first letter.
    expect(find.text("A"), findsOneWidget);
  });

  // Belt-and-suspenders: even with no name and no issuer name, the card renders
  // a neutral glyph rather than tripping the assert.
  testWidgets("renders when both name and issuer name are empty", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SchemalessYiviCredentialTypeCard(
          credentialId: "some.cred",
          credentialName: "",
          issuerName: "",
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("?"), findsOneWidget);
  });

  group("expired", () {
    Future<void> pumpCard(WidgetTester tester, ExpireState state) async {
      // FileTranslationLoader reads the locale JSON with real IO, which the
      // test framework's fake clock does not drive.
      await tester.runAsync(() async {
        await tester.pumpWidget(
          dataTabApp(
            overrides: const [],
            home: Scaffold(
              body: SchemalessYiviCredentialTypeCard(
                credentialId: "pbdf.pbdf.passport",
                credentialName: "Passport",
                issuerName: "Issuer",
                expireState: state,
              ),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
    }

    final faded = find.byWidgetPredicate(
      (widget) => widget is Opacity && widget.opacity < 1,
    );

    testWidgets("is faded, badged, and says Expired in red", (tester) async {
      await pumpCard(tester, ExpireState.expired);

      final card = find.byType(SchemalessYiviCredentialTypeCard);
      final red = IrmaTheme.of(tester.element(card)).error;
      expect(tester.widget<Text>(find.text("Expired")).style?.color, red);
      expect(tester.widget<Icon>(find.byIcon(Icons.error)).color, red);
      expect(find.text("Issuer"), findsNothing);
      expect(faded, findsOneWidget);
      // The badge keeps its full colour.
      expect(
        find.descendant(of: faded, matching: find.byIcon(Icons.error)),
        findsNothing,
      );
    });

    testWidgets("reads as the name followed by expired", (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, ExpireState.expired);

      expect(find.bySemanticsLabel("Passport, expired"), findsOneWidget);
      expect(find.bySemanticsLabel("Passport"), findsNothing);

      semantics.dispose();
    });

    for (final state in [ExpireState.notExpired, ExpireState.almostExpired]) {
      testWidgets("${state.name} looks like a normal card", (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpCard(tester, state);

        expect(find.text("Issuer"), findsOneWidget);
        expect(find.text("Expired"), findsNothing);
        expect(find.byIcon(Icons.error), findsNothing);
        expect(faded, findsNothing);
        expect(find.bySemanticsLabel("Passport, expired"), findsNothing);

        semantics.dispose();
      });
    }
  });
}
