import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: FileTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
    ],
    home: Scaffold(body: child),
  ),
);

Widget _card({ExpireState expireState = ExpireState.notExpired}) =>
    SchemalessYiviCredentialTypeCard(
      credentialId: "pbdf.sidn-pbdf.email",
      credentialName: "E-mail",
      issuerName: "SIDN",
      expireState: expireState,
      onTap: () {},
    );

/// The label a screen reader gets for the card, which is what the tile's
/// semantics node merges from the card's text.
String _tileLabel(WidgetTester tester) => tester
    .getSemantics(find.byKey(const Key("pbdf.sidn-pbdf.email_tile")))
    .label;

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

  testWidgets("a valid card reads the name and the issuer", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(_card()));
    await tester.pumpAndSettle();

    expect(find.text("SIDN"), findsOneWidget);
    expect(find.byIcon(Icons.error), findsNothing);
    expect(_tileLabel(tester), "E-mail\nSIDN");

    handle.dispose();
  });

  testWidgets("an expired card shows Expired in red in place of the issuer", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card(expireState: ExpireState.expired)));
    await tester.pumpAndSettle();

    final theme = IrmaThemeData();
    expect(find.text("SIDN"), findsNothing);
    expect(tester.widget<Text>(find.text("Expired")).style?.color, theme.error);
    expect(find.text("E-mail"), findsOneWidget);
  });

  testWidgets("an expired card fades its logo and puts a badge on it", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_card(expireState: ExpireState.expired)));
    await tester.pumpAndSettle();

    final badge = find.byIcon(Icons.error);
    expect(badge, findsOneWidget);
    // The badge is not inside the faded part, so it keeps its colour.
    expect(
      find.ancestor(of: badge, matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.4);
  });

  testWidgets("an expired card reads the name and that it expired", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(_card(expireState: ExpireState.expired)));
    await tester.pumpAndSettle();

    expect(_tileLabel(tester), "E-mail, expired");
    // Still a tap target.
    expect(
      tester
          .getSemantics(find.byKey(const Key("pbdf.sidn-pbdf.email_tile")))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    handle.dispose();
  });

  testWidgets("a card about to expire looks like a valid one", (tester) async {
    await tester.pumpWidget(
      _wrap(_card(expireState: ExpireState.almostExpired)),
    );
    await tester.pumpAndSettle();

    expect(find.text("SIDN"), findsOneWidget);
    expect(find.byIcon(Icons.error), findsNothing);
  });
}
