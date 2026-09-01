import "package:flutter/semantics.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/pin/yivi_pin_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

// The PIN screen used to expose its whole body as ONE semantics node: the
// keyboard-focus GestureDetector in PinHardwareKeyboardListener wrapped the
// screen and, because the instruction and PIN-dots annotations were not
// containers, it swallowed both their labels. A screen reader announced
// "Enter your PIN\nNo pin code entered" as a single tappable header.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const instruction = "Enter your PIN";
  const emptyPin = "No pin code entered";

  Future<void> pumpPinScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final widget = ProviderScope(
      child: IrmaTheme(
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
          // Via the scaffold, not bare: YiviPinScreen needs a Material ancestor
          // (the forgot-PIN link's InkWell) and a bounded height.
          home: YiviPinScaffold(
            body: YiviPinScreen(
              instructionKey: "pin.subtitle",
              maxPinSize: 5,
              submitLabel: "pin.unlock",
              onSubmit: (_) {},
            ),
          ),
        ),
      ),
    );

    // FileTranslationLoader reads the locale JSON with real IO, which the test
    // framework's fake clock does not drive.
    await tester.runAsync(() async {
      await tester.pumpWidget(widget);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets("the instruction is its own node, flagged as a header", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPinScreen(tester);

    final node = find.semantics.byLabel(instruction);
    expect(node, findsOne);
    final data = node.evaluate().single.getSemanticsData();
    expect(data.flagsCollection.isHeader, isTrue);
    // The heading is not an affordance; the screen-wide focus detector used to
    // give it a tap action.
    expect(data.hasAction(SemanticsAction.tap), isFalse);

    handle.dispose();
  });

  testWidgets("the PIN entry state is announced separately from the heading", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPinScreen(tester);

    expect(find.semantics.byLabel(emptyPin), findsOne);

    // The regression itself: no single node carries both, which is what fused
    // the heading and the entry state into one announcement.
    expect(
      find.semantics.byPredicate(
        (node) =>
            node.label.contains(instruction) && node.label.contains(emptyPin),
        describeMatch: (_) => "a node fusing the heading and the entry state",
      ),
      findsNothing,
    );

    handle.dispose();
  });

  testWidgets("the keyboard-focus detector adds no screen-wide tap target", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPinScreen(tester);

    // Every remaining tap target is a real control (keypad key, Show PIN,
    // backspace, links), all far smaller than the screen.
    final screen =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      find.semantics.byPredicate(
        (node) =>
            node.getSemanticsData().hasAction(SemanticsAction.tap) &&
            node.rect.width >= screen,
        describeMatch: (_) => "a screen-wide tappable node",
      ),
      findsNothing,
    );

    handle.dispose();
  });
}
