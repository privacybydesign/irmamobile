import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/face_frame_illustration.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "helpers/test_translation_loader.dart";
import "support/document_screen_host.dart";
import "support/pump_translated.dart";

Widget _wrap({required VoidCallback onStart, bool inWideSheet = false}) {
  final screen = FaceVerificationIntroScreen(onStart: onStart);
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
        home: DocumentScreenHost(screen),
      ),
    ),
  );
}

/// A phone held upright.
void _phone(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets("shows the guidance tips", (tester) async {
    _phone(tester);
    await pumpTranslated(tester, _wrap(onStart: () {}));
    await tester.pumpAndSettle();

    // The page's heading (the sheet's bar has no title upright).
    expect(find.text("Quick face check"), findsOneWidget);
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
    _phone(tester);
    var started = 0;
    await pumpTranslated(tester, _wrap(onStart: () => started++));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    expect(started, 1);
  });

  testWidgets("in a sheet held sideways: the words at the left, the face at "
      "the right", (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(874, 402);
    addTearDown(tester.view.reset);
    await pumpTranslated(tester, _wrap(onStart: () {}, inWideSheet: true));
    await tester.pumpAndSettle();

    final words = tester.getRect(
      find.textContaining("confirm you're the person shown in the document"),
    );
    final face = tester.getRect(find.byType(FaceFrameIllustration));
    expect(words.right, lessThan(face.left));
  });
}
