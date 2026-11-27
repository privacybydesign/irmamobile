import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/face_frame_illustration.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "helpers/test_translation_loader.dart";

Widget _wrap(Widget home) {
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
        home: home,
      ),
    ),
  );
}

void main() {
  testWidgets("shows a still picture and the guidance tips", (tester) async {
    await tester.pumpWidget(_wrap(FaceVerificationIntroScreen(onStart: () {})));
    await tester.pumpAndSettle();

    // Title appears only in the app bar, not duplicated in the body.
    expect(find.text("Face verification"), findsOneWidget);
    expect(find.byType(FaceFrameIllustration), findsOneWidget);
    expect(
      find.textContaining("confirm you're the person shown in the document"),
      findsOneWidget,
    );
    expect(find.text("Point the selfie camera at your face."), findsOneWidget);
    expect(find.text("Make sure there's enough light."), findsOneWidget);
    expect(find.text("Look straight into the camera."), findsOneWidget);
    expect(find.text("Remove glasses, hats, etc."), findsOneWidget);
  });

  testWidgets("start button invokes onStart, and is the only button", (
    tester,
  ) async {
    var started = 0;
    await tester.pumpWidget(
      _wrap(FaceVerificationIntroScreen(onStart: () => started++)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("bottom_bar_secondary")), findsNothing);
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    expect(started, 1);
  });

  testWidgets("show resolves to true on start and false on the back arrow", (
    tester,
  ) async {
    final results = <bool>[];
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                results.add(await FaceVerificationIntroScreen.show(context)),
            child: const Text("open"),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key("irma_app_bar_leading")));
    await tester.pumpAndSettle();

    expect(results, [true, false]);
  });
}
