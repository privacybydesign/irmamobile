import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "support/pump_translated.dart";

Widget _wrap({
  required DocumentType documentType,
  required VoidCallback onStart,
  required VoidCallback onCancel,
  Locale locale = const Locale("en", "US"),
}) {
  // TestContext disables the instruction animation's repeating ticker so
  // pumpAndSettle does not hang.
  return TestContext(
    child: IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: locale,
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: DocumentInstructionScreen(
          documentType: documentType,
          onStart: onStart,
          onCancel: onCancel,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets("passport: open on the photo page, with a glare tip", (
    tester,
  ) async {
    await pumpTranslated(
      tester,
      _wrap(
        documentType: DocumentType.passport,
        onStart: () {},
        onCancel: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Scan passport"), findsOneWidget);
    expect(find.text("Open your passport on the photo page"), findsOneWidget);
    expect(find.textContaining("Then press Start to begin."), findsOneWidget);
    expect(find.textContaining("directly under a lamp"), findsOneWidget);
  });

  testWidgets("passport texts are in Dutch for the nl locale", (tester) async {
    await pumpTranslated(
      tester,
      _wrap(
        documentType: DocumentType.passport,
        onStart: () {},
        onCancel: () {},
        locale: const Locale("nl", "NL"),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("Open je paspoort op de pagina met je pasfoto"),
      findsOneWidget,
    );
    expect(find.text("Start"), findsOneWidget);
    expect(find.text("Annuleren"), findsOneWidget);
  });

  for (final (documentType, title) in [
    (DocumentType.identityCard, "Use the back of your ID-card"),
    (DocumentType.drivingLicence, "Use the back of your driving licence"),
  ]) {
    testWidgets("$documentType: use the back of the card", (tester) async {
      await pumpTranslated(
        tester,
        _wrap(documentType: documentType, onStart: () {}, onCancel: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
      expect(find.textContaining("whole back"), findsOneWidget);
    });
  }

  testWidgets("Start and Cancel call their callbacks", (tester) async {
    var started = 0;
    var cancelled = 0;
    await pumpTranslated(
      tester,
      _wrap(
        documentType: DocumentType.passport,
        onStart: () => started++,
        onCancel: () => cancelled++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();
    expect(started, 1);
    expect(cancelled, 0);

    await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
    await tester.pumpAndSettle();
    expect(cancelled, 1);
  });

  testWidgets("the animation is hidden from assistive technology", (
    tester,
  ) async {
    await pumpTranslated(
      tester,
      _wrap(
        documentType: DocumentType.passport,
        onStart: () {},
        onCancel: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byType(CustomPaint),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });
}
