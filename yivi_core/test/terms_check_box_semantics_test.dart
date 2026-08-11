import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/widgets/terms_check_box.dart";
import "package:yivi_core/src/theme/theme.dart";

// Regression test for #638: the terms acceptance checkbox had no accessible
// name of its own, so a screen reader announced only its role and state.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<IrmaPreferences> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "https://example.test/nl",
      mostRecentTermsUrlEn: "https://example.test/en",
    );
  }

  Future<void> pumpCheckBox(
    WidgetTester tester, {
    required bool isAccepted,
    required IrmaPreferences preferences,
    Locale locale = const Locale("en", "US"),
    void Function(bool)? onToggleAccepted,
  }) async {
    final widget = ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: IrmaTheme(
        builder: (_) => MaterialApp(
          localizationsDelegates: [
            FlutterI18nDelegate(
              translationLoader: FileTranslationLoader(
                basePath: "assets/locales",
                forcedLocale: locale,
              ),
            ),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: TermsCheckBox(
              isAccepted: isAccepted,
              onToggleAccepted: onToggleAccepted ?? (_) {},
            ),
          ),
        ),
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

  final checkbox = find.byKey(const Key("accept_terms_checkbox"));

  testWidgets("announces its label, checkbox role and unchecked state", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpCheckBox(tester, isAccepted: false, preferences: await prefs());

    expect(
      tester.getSemantics(checkbox),
      matchesSemantics(
        // The visible label is markdown linking to the terms; the link syntax
        // is stripped so the label reads as plain text.
        label: "Yes, I accept the terms and conditions",
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });

  testWidgets("announces the checked state once accepted", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCheckBox(tester, isAccepted: true, preferences: await prefs());

    expect(
      tester.getSemantics(checkbox),
      matchesSemantics(
        label: "Yes, I accept the terms and conditions",
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );

    handle.dispose();
  });

  testWidgets("label is localized", (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCheckBox(
      tester,
      isAccepted: false,
      preferences: await prefs(),
      locale: const Locale("nl", "NL"),
    );

    expect(
      tester.getSemantics(checkbox).label,
      "Ja, ik ga akkoord met de algemene voorwaarden",
    );

    handle.dispose();
  });

  testWidgets("the semantics tap action toggles acceptance", (tester) async {
    final handle = tester.ensureSemantics();
    bool? toggled;
    await pumpCheckBox(
      tester,
      isAccepted: false,
      preferences: await prefs(),
      onToggleAccepted: (value) => toggled = value,
    );

    // Drive the semantics action itself, not a pointer tap: this is the path a
    // screen reader takes, and it goes through the merged node the label lives
    // on rather than the Checkbox's own hit box.
    tester.semantics.tap(
      find.semantics.byLabel("Yes, I accept the terms and conditions"),
    );
    await tester.pumpAndSettle();

    expect(toggled, isTrue);

    handle.dispose();
  });

  testWidgets("the terms link stays reachable next to the checkbox", (
    tester,
  ) async {
    await pumpCheckBox(tester, isAccepted: false, preferences: await prefs());

    // The markdown text is not merged into the checkbox, so its link is still
    // rendered and tappable on its own.
    expect(find.textContaining("terms and conditions"), findsOneWidget);
  });
}
