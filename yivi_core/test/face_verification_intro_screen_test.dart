import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_step_in_sheet.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/face_frame_illustration.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/adaptive_layout.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "helpers/test_translation_loader.dart";
import "support/pump_translated.dart";

Widget _wrap({
  required VoidCallback onStart,
  required VoidCallback onCancel,
  bool inWideSheet = false,
}) {
  final screen = FaceVerificationIntroScreen(
    onStart: onStart,
    onCancel: onCancel,
  );
  // TestContext disables the intro animation's repeating ticker so
  // pumpAndSettle does not hang.
  return TestContext(
    child: IrmaTheme(
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
        home: inWideSheet
            ? DocumentStepInSheet(
                child: SheetWidthScope(width: 874, child: screen),
              )
            : screen,
      ),
    ),
  );
}

void main() {
  testWidgets("shows the guidance tips", (tester) async {
    await pumpTranslated(tester, _wrap(onStart: () {}, onCancel: () {}));
    await tester.pumpAndSettle();

    // Title appears only in the app bar, not duplicated in the body.
    expect(find.text("Face verification"), findsOneWidget);
    expect(
      find.textContaining("confirm you're the person shown in the document"),
      findsOneWidget,
    );
    expect(find.text("Point the selfie camera at your face."), findsOneWidget);
    expect(find.text("Make sure there's enough light."), findsOneWidget);
    expect(find.text("Look straight into the camera."), findsOneWidget);
    expect(find.text("Remove glasses, hats, etc."), findsOneWidget);
  });

  testWidgets("start button invokes onStart", (tester) async {
    var started = 0;
    await pumpTranslated(
      tester,
      _wrap(onStart: () => started++, onCancel: () {}),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    expect(started, 1);
  });

  testWidgets("the back button invokes onCancel", (tester) async {
    var cancelled = 0;
    await pumpTranslated(
      tester,
      _wrap(onStart: () {}, onCancel: () => cancelled++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("irma_app_bar_leading")));
    await tester.pumpAndSettle();

    expect(cancelled, 1);
  });

  testWidgets("in a sheet held sideways: the words at the left, the face at "
      "the right", (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(874, 402);
    addTearDown(tester.view.reset);
    await pumpTranslated(
      tester,
      _wrap(onStart: () {}, onCancel: () {}, inWideSheet: true),
    );
    await tester.pumpAndSettle();

    final words = tester.getRect(
      find.textContaining("confirm you're the person shown in the document"),
    );
    final face = tester.getRect(find.byType(FaceFrameIllustration));
    expect(words.right, lessThan(face.left));
  });
}
