import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/arrow_back_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

// Regression test for #638: on iOS this screen hands the user back to the
// browser they came from, but the control it points at is the status bar back
// link owned by iOS, which the app cannot label. The screen replaces the
// session body instead of pushing a route, so VoiceOver announces nothing on
// its own — the outcome and the instruction have to be one live region.

/// Every node in [root]'s subtree that is exposed to a screen reader as an
/// image.
List<SemanticsNode> _imageNodes(SemanticsNode root) {
  final found = <SemanticsNode>[];
  if (root.getSemanticsData().flagsCollection.isImage) found.add(root);
  root.visitChildren((child) {
    found.addAll(_imageNodes(child));
    return true;
  });
  return found;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpArrowBack(
    WidgetTester tester,
    ArrowBackType type, {
    Locale locale = const Locale("en", "US"),
  }) async {
    final widget = IrmaTheme(
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
        home: ArrowBack(type: type),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive: without runAsync plus a real
    // delay, Localizations never rebuilds and the tree stays empty. Dutch
    // loads two files (nl.json plus the en.json fallback).
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  final announcement = find.byKey(const Key("arrow_back_semantics"));

  testWidgets("announces the outcome and the instruction as one live region", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpArrowBack(tester, ArrowBackType.disclosure);

    expect(
      tester.getSemantics(announcement),
      matchesSemantics(
        label:
            "Success, your data has been shared\n"
            "Tap on the name of the application (such as Safari, Chrome, "
            "Firefox) in the top left corner to return to the previous "
            "application.",
        isLiveRegion: true,
      ),
    );

    handle.dispose();
  });

  testWidgets("the announced outcome follows the session type", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpArrowBack(tester, ArrowBackType.error);

    expect(tester.getSemantics(announcement).label, startsWith("Cancelled\n"));

    handle.dispose();
  });

  testWidgets("the decorative arrow is not announced", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpArrowBack(tester, ArrowBackType.disclosure);

    expect(
      _imageNodes(tester.binding.rootElement!.renderObject!.debugSemantics!),
      isEmpty,
      reason:
          "the arrow repeats the instruction visually, so it should not add a "
          "nameless image node a screen reader stops on",
    );

    handle.dispose();
  });

  testWidgets("the announcement is localized", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpArrowBack(
      tester,
      ArrowBackType.issuance,
      locale: const Locale("nl", "NL"),
    );

    expect(
      tester.getSemantics(announcement).label,
      "Gelukt, de gegevens zijn toegevoegd\n"
      "Tik bovenin op de naam van het programma (bijvoorbeeld Safari, Chrome, "
      "Firefox) om terug te gaan naar het programma waar je mee bezig was.",
    );

    handle.dispose();
  });
}
