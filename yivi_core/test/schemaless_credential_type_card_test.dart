import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";

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
}
