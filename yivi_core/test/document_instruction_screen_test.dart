import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";

import "helpers/document_flow_test_app.dart";

Future<void> _pump(
  WidgetTester tester, {
  DocumentType documentType = DocumentType.passport,
  VoidCallback? onStart,
  VoidCallback? onCancel,
  Locale locale = const Locale("en", "US"),
  Ticker ticker = Ticker.stopped,
}) => pumpDocumentFlow(
  tester,
  DocumentInstructionScreen(
    documentType: documentType,
    onStart: onStart ?? () {},
    onCancel: onCancel ?? () {},
  ),
  locale: locale,
  ticker: ticker,
);

void main() {
  testWidgets("passport: open on the photo page, with a glare tip", (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text("Scan passport"), findsOneWidget);
    expect(find.text("Open your passport on the photo page"), findsOneWidget);
    expect(find.textContaining("Then press Start to begin."), findsOneWidget);
    expect(find.textContaining("directly under a lamp"), findsOneWidget);
  });

  testWidgets("passport texts are in Dutch for the nl locale", (tester) async {
    await _pump(tester, locale: const Locale("nl", "NL"));

    expect(
      find.text("Open je paspoort op de pagina met je pasfoto"),
      findsOneWidget,
    );
    expect(find.text("Start"), findsOneWidget);
    expect(find.text("Annuleer"), findsOneWidget);
  });

  for (final (documentType, scanTitle, title) in [
    (DocumentType.identityCard, "Scan ID-card", "Use the back of your ID-card"),
    (
      DocumentType.residencePermit,
      "Scan residence permit",
      "Use the back of your residence permit",
    ),
    (
      DocumentType.drivingLicence,
      "Scan driving licence",
      "Use the back of your driving licence",
    ),
  ]) {
    testWidgets("$documentType: use the back of the card", (tester) async {
      await _pump(tester, documentType: documentType);

      expect(find.text(scanTitle), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining("whole back"), findsOneWidget);
    });
  }

  testWidgets("Start and Cancel call their callbacks", (tester) async {
    var started = 0;
    var cancelled = 0;
    await _pump(tester, onStart: () => started++, onCancel: () => cancelled++);

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
    await _pump(tester);

    expect(
      find.ancestor(
        of: find.byType(CustomPaint),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });

  group("the loop", () {
    testWidgets("keeps running by default", (tester) async {
      await _pump(tester, ticker: Ticker.running);
      await tester.pump(const Duration(seconds: 1));

      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets("stands still when the system asks for less motion", (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pump(tester, ticker: Ticker.running);
      await tester.pump(const Duration(seconds: 1));

      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}
