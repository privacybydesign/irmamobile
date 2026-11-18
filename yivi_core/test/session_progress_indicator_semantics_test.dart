import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/session_progress_indicator.dart";

import "helpers/test_translation_loader.dart";

// Regression test for #728: the progress bar on the collect data screen was
// announced by its numeric value ("50.0, 50, ..., progress bar") on top of the
// "Step 1 of 2" text that already says the same.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpIndicator(WidgetTester tester) async {
    final widget = IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: TestTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: SessionProgressIndicator(
            step: 1,
            stepCount: 2,
            contentTranslationKey: "disclosure_permission.overview.explanation",
            contentTranslationParams: const {"requestorName": "Verifier"},
          ),
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive: without runAsync plus a real
    // delay, Localizations never rebuilds and the tree stays empty.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets("keeps the step text and hides the progress bar", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpIndicator(tester);

    expect(find.bySemanticsLabel(RegExp("Step 1 of 2")), findsOneWidget);

    // The bar announces itself as a progress bar with a numeric value.
    expect(
      find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.role == SemanticsRole.progressBar || data.value.isNotEmpty;
      }),
      findsNothing,
    );

    handle.dispose();
  });
}
