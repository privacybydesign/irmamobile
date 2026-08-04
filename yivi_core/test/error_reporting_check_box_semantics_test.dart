import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/screens/enrollment/accept_terms/widgets/error_reporting_check_box.dart";
import "package:yivi_core/src/theme/theme.dart";

// Companion to terms_check_box_semantics_test.dart (#638): the error reporting
// checkbox has the same shape — its label lives in a sibling rich-text widget,
// so without a merged label a screen reader announces only role and state.

class _RecordingBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const englishLabel =
      "Optional: Share error messages and app status with Yivi";

  // The report-errors value must be seeded explicitly rather than left to
  // setMockInitialValues: the preference store is not rebuilt per test, so a
  // value written by one test is still there in the next. Without this, this
  // file passes test by test and fails when run as a whole.
  Future<IrmaRepository> repository({bool reportErrors = false}) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    await preferences.setReportErrors(reportErrors);
    return IrmaRepository(client: _RecordingBridge(), preferences: preferences);
  }

  Future<void> pumpCheckBox(
    WidgetTester tester, {
    required IrmaRepository repo,
    Locale locale = const Locale("en", "US"),
  }) async {
    final widget = IrmaRepositoryProvider(
      repository: repo,
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
          home: Scaffold(body: ErrorReportingCheckBox()),
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

  final checkbox = find.byKey(const Key("error_reporting_checkbox"));

  testWidgets("announces its label, checkbox role and unchecked state", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo);

    expect(
      tester.getSemantics(checkbox),
      matchesSemantics(
        // The visible label is three styled spans; the label joins them in
        // reading order so the spoken sentence matches the written one.
        label: englishLabel,
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

  testWidgets("announces the checked state once error reporting is on", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository(reportErrors: true);
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo);

    expect(
      tester.getSemantics(checkbox),
      matchesSemantics(
        label: englishLabel,
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
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo, locale: const Locale("nl", "NL"));

    expect(
      tester.getSemantics(checkbox).label,
      "Optioneel: Foutmeldingen en app status delen met Yivi",
    );

    handle.dispose();
  });

  testWidgets("the semantics tap action toggles error reporting", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo);

    // Drive the semantics action itself, not a pointer tap: this is the path a
    // screen reader takes, and it goes through the merged node the label lives
    // on rather than the Checkbox's own hit box. Match on the node id resolved
    // from the checkbox widget, because the merged text beside it carries the
    // same label and would make a label finder ambiguous.
    final checkboxNodeId = tester.getSemantics(checkbox).id;
    tester.semantics.tap(
      find.semantics.byPredicate(
        (node) => node.id == checkboxNodeId,
        describeMatch: (_) => "the error reporting checkbox node",
      ),
    );
    // Required: without a pump the write started by onChanged never progresses,
    // and the read below sees the old value.
    await tester.pumpAndSettle();

    // Read the preference back through runAsync: the write goes over the
    // shared_preferences channel and returns on a Preference stream, neither of
    // which the test framework's fake clock drives — awaiting outside runAsync
    // hangs until the test times out. firstWhere waits for the emission instead
    // of sampling once, and the timeout turns a tap that never lands into a
    // fast failure rather than a ten-minute one.
    //
    // Asserting the stored preference rather than the re-rendered checkbox
    // keeps this test to one question (did the screen reader's tap reach the
    // preference?). That the checkbox renders as checked when the preference is
    // on is covered above.
    final enabled = await tester.runAsync(
      () => repo.preferences
          .getReportErrors()
          .firstWhere((enabled) => enabled)
          .timeout(const Duration(seconds: 5), onTimeout: () => false),
    );
    expect(enabled, isTrue);

    handle.dispose();
  });

  testWidgets("the label beside the checkbox is one node, not three", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final repo = await repository();
    addTearDown(repo.close);
    await pumpCheckBox(tester, repo: repo);

    // RenderParagraph would otherwise split the sentence at the tappable span,
    // announcing "Optional:", "Share error messages and app status" and "with
    // Yivi" as three separate nodes. The checkbox carries the same label, so
    // exclude it by id to leave just the text's node.
    final checkboxNodeId = tester.getSemantics(checkbox).id;
    final labelNode = find.semantics.byPredicate(
      (node) => node.label == englishLabel && node.id != checkboxNodeId,
      describeMatch: (_) => "the merged error reporting label node",
    );
    expect(labelNode, findsOne);

    // No fragment survives as a node of its own.
    expect(find.semantics.byLabel("with Yivi"), findsNothing);
    expect(
      find.semantics.byLabel("Share error messages and app status"),
      findsNothing,
    );

    // The merge keeps the recognizer's tap action, so the info sheet is still
    // reachable from the merged node.
    expect(
      labelNode.evaluate().single.getSemanticsData().hasAction(
        SemanticsAction.tap,
      ),
      isTrue,
    );

    handle.dispose();
  });
}
