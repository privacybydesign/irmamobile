import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

Widget _wrap({required VoidCallback onStart, required VoidCallback onCancel}) {
  // TestContext disables the intro animation's repeating ticker so
  // pumpAndSettle does not hang.
  return TestContext(
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
        home: FaceVerificationIntroScreen(onStart: onStart, onCancel: onCancel),
      ),
    ),
  );
}

/// Pumps [widget] and waits for the locale files to load.
///
/// FileTranslationLoader reads the locale JSON with real IO, and past 50 KB
/// Flutter decodes the asset on a background isolate; the test framework's
/// fake clock drives neither, so without runAsync plus a real delay
/// Localizations never rebuilds and the tree stays empty.
Future<void> _pumpLocalized(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("shows the guidance tips", (tester) async {
    await _pumpLocalized(tester, _wrap(onStart: () {}, onCancel: () {}));

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
    await _pumpLocalized(
      tester,
      _wrap(onStart: () => started++, onCancel: () {}),
    );

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    expect(started, 1);
  });

  testWidgets("cancel button invokes onCancel", (tester) async {
    var cancelled = 0;
    await _pumpLocalized(
      tester,
      _wrap(onStart: () {}, onCancel: () => cancelled++),
    );

    await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
    await tester.pumpAndSettle();

    expect(cancelled, 1);
  });
}
