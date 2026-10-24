import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/document_face.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/document_instruction_illustration.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/document_scan_scene.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";

void main() {
  Future<void> pump(
    WidgetTester tester,
    DocumentType type, {
    bool still = true,
    ThemeMode mode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      IrmaTheme(
        builder: (context) => MaterialApp(
          theme: IrmaTheme.variantsOf(context).data.themeData,
          darkTheme: IrmaTheme.variantsOf(context).darkData.themeData,
          themeMode: mode,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 844),
              disableAnimations: still,
            ),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  height: 256,
                  child: DocumentInstructionIllustration(documentType: type),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  for (final type in DocumentType.values) {
    testWidgets("$type: the scene fills the picture, the document on the "
        "table and on the phone's screen", (tester) async {
      await pump(tester, type);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(DocumentScanScene)),
        DocumentScanScene.size,
      );
      final faces = tester.widgetList<DocumentFace>(find.byType(DocumentFace));
      expect(faces.length, 2);
      // One sweep for both, so the two bands move together.
      expect(faces.first.sweep, same(faces.last.sweep));
      expect(
        find.descendant(
          of: find.byKey(const Key("document_scan_screen")),
          matching: find.byType(DocumentFace),
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets("still when motion is reduced: nothing keeps ticking", (
    tester,
  ) async {
    await pump(tester, DocumentType.identityCard);
    final phone = tester.getRect(find.byKey(const Key("document_scan_phone")));
    // pumpAndSettle would time out on a repeating animation.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.getRect(find.byKey(const Key("document_scan_phone"))), phone);
  });

  testWidgets("the phone hovers: up at half its loop, back down after", (
    tester,
  ) async {
    await pump(tester, DocumentType.identityCard, still: false);
    await tester.pump();
    final low = tester.getRect(find.byKey(const Key("document_scan_phone")));
    await tester.pump(const Duration(milliseconds: 1600));
    final high = tester.getRect(find.byKey(const Key("document_scan_phone")));
    expect(high.top, lessThan(low.top - 5));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(
      tester.getRect(find.byKey(const Key("document_scan_phone"))).top,
      moreOrLessEquals(low.top, epsilon: 0.5),
    );
  });

  testWidgets("dark mode: the phone's screen is the app's dark background", (
    tester,
  ) async {
    await pump(tester, DocumentType.passport, mode: ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ColoredBox>(find.byKey(const Key("document_scan_screen")))
          .color,
      YiviPalette.dark.background,
    );
  });
}
