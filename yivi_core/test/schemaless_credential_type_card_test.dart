import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "package:yivi_core/src/widgets/data_tab_icon.dart";
import "package:yivi_core/src/widgets/irma_avatar.dart";

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
    Future<void> pumpCard(
      WidgetTester tester,
      ExpireState state, {
      CredentialCardLayout layout = CredentialCardLayout.standard,
    }) async {
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
                layout: layout,
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
    final badge = find.text("!");
    const w600 = FontWeight.w600;

    Color? badgeColor(WidgetTester tester) {
      final box = tester.widget<Container>(
        find.ancestor(of: badge, matching: find.byType(Container)).first,
      );
      return (box.decoration as BoxDecoration).color;
    }

    testWidgets("is faded, badged, and says Expired in red", (tester) async {
      await pumpCard(tester, ExpireState.expired);

      final card = find.byType(SchemalessYiviCredentialTypeCard);
      final red = IrmaTheme.of(tester.element(card)).error;
      expect(tester.widget<Text>(find.text("Expired")).style?.color, red);
      expect(tester.widget<Text>(find.text("Expired")).style?.fontWeight, w600);
      expect(badgeColor(tester), red);
      expect(find.text("Issuer"), findsNothing);
      expect(faded, findsOneWidget);
      // The badge keeps its full colour.
      expect(find.descendant(of: faded, matching: badge), findsNothing);
    });

    testWidgets("is faded to 0.45 on a warm grey surface", (tester) async {
      await pumpCard(tester, ExpireState.expired);

      expect(tester.widget<Opacity>(faded).opacity, 0.45);
      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(SchemalessYiviCredentialTypeCard),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.color, const Color(0xFFF7F5F4));
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
        expect(badge, findsNothing);
        expect(faded, findsNothing);
        expect(find.bySemanticsLabel("Passport, expired"), findsNothing);

        semantics.dispose();
      });
    }
  });

  group("compact layout", () {
    Future<void> pumpCompact(
      WidgetTester tester, {
      CredentialCardLayout layout = CredentialCardLayout.compact,
      IconData? trailingIcon,
      String issuerName = "Issuer",
    }) async {
      await tester.pumpWidget(
        _wrap(
          // A Column, as the card has the height of its content in the lists.
          Column(
            children: [
              SizedBox(
                width: 390,
                child: SchemalessYiviCredentialTypeCard(
                  credentialId: "pbdf.pbdf.passport",
                  credentialName: "Passport",
                  issuerName: issuerName,
                  layout: layout,
                  trailingIcon: trailingIcon,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    final tile = find.byKey(const Key("pbdf.pbdf.passport_tile"));

    testWidgets("is 72 high with a 44 logo", (tester) async {
      await pumpCompact(tester);

      expect(tester.getSize(tile).height, 72);
      expect(tester.getSize(find.byType(IrmaAvatar)), const Size(44, 44));
    });

    testWidgets("stays 72 high when the issuer wraps to a second line", (
      tester,
    ) async {
      await pumpCompact(tester, issuerName: "Stichting Privacy by Design");

      expect(tester.getSize(tile).height, 72);
    });

    testWidgets("the standard layout keeps its 52 logo and 84 height", (
      tester,
    ) async {
      await pumpCompact(tester, layout: CredentialCardLayout.standard);

      expect(tester.getSize(tile).height, 84);
      expect(tester.getSize(find.byType(IrmaAvatar)), const Size(52, 52));
    });

    testWidgets("ends in a 20 px chevron", (tester) async {
      await pumpCompact(tester);

      final chevron = tester.widget<DataTabIcon>(find.byType(DataTabIcon));
      expect(chevron.glyph, DataTabGlyph.chevronRight);
      expect(chevron.size, 20);
    });

    testWidgets("ends in a 26 px plus when it adds", (tester) async {
      await pumpCompact(tester, trailingIcon: Icons.add_circle_sharp);

      final plus = tester.widget<DataTabIcon>(find.byType(DataTabIcon));
      expect(plus.glyph, DataTabGlyph.plusCircle);
      expect(plus.size, 26);
    });
  });
}
