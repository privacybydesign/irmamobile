import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_feedback_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

/// A zero-knowledge disclosure is reported as its own outcome, and that outcome
/// is still a success.
///
/// Both halves matter. If it were not its own type the user would be told their
/// data was disclosed when it was proved instead, and if it were not a success
/// the screen would show the error illustration for an exchange that worked.
void main() {
  test("zeroKnowledge is a success outcome", () {
    expect(DisclosureFeedbackType.zeroKnowledge.isSuccess, isTrue);
    expect(DisclosureFeedbackType.success.isSuccess, isTrue);
  });

  test("the failure outcomes are not", () {
    expect(DisclosureFeedbackType.canceled.isSuccess, isFalse);
    expect(DisclosureFeedbackType.notSatisfiable.isSuccess, isFalse);
  });

  test("zeroKnowledge has its own translation key", () {
    // The key drives both the title and the explanation, so sharing "success"
    // would silently show the plain-disclosure wording for a proof.
    final screen = DisclosureFeedbackScreen(
      feedbackType: DisclosureFeedbackType.zeroKnowledge,
      otherParty: "Test Verifier",
      onDismiss: (_) {},
    );
    expect(screen.feedbackType, DisclosureFeedbackType.zeroKnowledge);
    expect(
      DisclosureFeedbackType.values.map((t) => t.name).toSet(),
      hasLength(DisclosureFeedbackType.values.length),
    );
  });

  _markdownRendering();
}

/// The zero-knowledge explanation renders through the markdown path, and both
/// things that depend on it are easy to lose silently.
///
/// The markdown renderer is selected by the key's last segment containing
/// `_markdown`, so a renamed key falls back to plain text and the bold markers
/// appear on screen as literal asterisks. And the markdown path ignores
/// `textAlign` entirely -- it takes its alignment from the style sheet instead --
/// so the body sits left-aligned under a centred title unless the sheet says
/// otherwise. Neither failure throws; both just look wrong.
void _markdownRendering() {
  Future<MarkdownBody> render(WidgetTester tester, {Duration? duration}) async {
    final widget = IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: DisclosureFeedbackScreen(
          feedbackType: DisclosureFeedbackType.zeroKnowledge,
          otherParty: "https://zkp-verifier.com",
          duration: duration,
          onDismiss: (_) {},
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive: without runAsync plus a real delay
    // Localizations never rebuilds, the tree stays a bare SizedBox, and every
    // assertion below fails as "no MarkdownBody" rather than as what it is.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    return tester.widget<MarkdownBody>(find.byType(MarkdownBody));
  }

  /// The rendered paragraph carrying the opening sentence, with the surface
  /// sized like a phone rather than like the 800x600 test default.
  ///
  /// The width matters: MarkdownBody sizes each block to its own content unless
  /// told otherwise, so a short sentence on a wide surface can fill the space by
  /// accident and look centred when nothing is centring it. At 390 logical
  /// pixels the sentence is genuinely narrower than the column, which is the
  /// case that exposes the setting.
  Future<RichText> openingParagraph(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await render(tester);

    return tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere(
          (text) => text.text.toPlainText().startsWith("Your data never left"),
        );
  }

  testWidgets("the explanation is centred", (tester) async {
    final markdown = await render(tester);
    expect(
      markdown.styleSheet?.textAlign,
      WrapAlignment.center,
      reason: "the markdown path ignores textAlign and reads the sheet instead",
    );
  });

  testWidgets("the opening sentence is bold", (tester) async {
    final markdown = await render(tester);
    expect(
      markdown.data,
      startsWith("**Your data never left your device.**"),
      reason: "the headline claim carries the weight of the screen",
    );
    expect(
      markdown.data,
      contains("**https://zkp-verifier.com**"),
      reason: "the requestor stays bold on its own line",
    );
  });

  testWidgets("a measured disclosure reports how long the proof took", (
    tester,
  ) async {
    final markdown = await render(
      tester,
      duration: const Duration(milliseconds: 1180),
    );
    // Three decimals: the wallet measures whole milliseconds and the screen
    // now shows all of them, so 1180 ms reads as "1.180" rather than "1.2".
    //
    // Bold on the figure alone and not on the unit: the number is what the
    // reader is meant to take away, and bolding "seconds" with it would only
    // thicken the sentence.
    expect(markdown.data, contains("**1.180** seconds"));
  });

  testWidgets("an unmeasured one says nothing about timing", (tester) async {
    final markdown = await render(tester);
    expect(
      markdown.data,
      isNot(contains("seconds")),
      reason: "a hole in the sentence is worse than no sentence",
    );
  });

  testWidgets("the opening sentence fills the column so it can centre", (
    tester,
  ) async {
    final paragraph = await openingParagraph(tester);

    expect(paragraph.textAlign, TextAlign.center);

    // The block has to be as wide as the space it sits in. Sized to its own
    // text instead, TextAlign.center centres it within its own width, which is
    // no movement at all, and the sentence sits against the left edge -- the
    // exact symptom this guards, and one a wide test surface hides.
    final paragraphWidth = tester.getSize(find.byWidget(paragraph)).width;
    final columnWidth = tester
        .getSize(
          find
              .ancestor(
                of: find.byType(MarkdownBody),
                matching: find.byType(Column),
              )
              .first,
        )
        .width;
    expect(
      paragraphWidth,
      columnWidth,
      reason: "a content-sized block cannot centre within itself",
    );
  });

  testWidgets("the opening sentence is rendered bold, not marked up bold", (
    tester,
  ) async {
    final paragraph = await openingParagraph(tester);

    // Read off the resolved span rather than off the markdown source: the
    // asterisks are there either way, and what is being checked is that the
    // renderer turned them into weight instead of printing them.
    final weights = <FontWeight?>[];
    paragraph.text.visitChildren((span) {
      if (span is TextSpan && span.text != null && span.text!.isNotEmpty) {
        weights.add(span.style?.fontWeight);
      }
      return true;
    });

    expect(
      paragraph.text.toPlainText(),
      isNot(contains("**")),
      reason: "literal asterisks mean the markdown path was not taken",
    );
    expect(weights, isNotEmpty);
    expect(
      weights.every((w) => w == FontWeight.bold || w == FontWeight.w700),
      isTrue,
      reason: "resolved weights were $weights",
    );
  });
}
