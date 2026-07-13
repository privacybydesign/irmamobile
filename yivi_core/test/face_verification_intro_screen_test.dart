import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";

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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FaceVerificationIntroScreen(onStart: onStart, onCancel: onCancel),
      ),
    ),
  );
}

void main() {
  testWidgets("shows the guidance tips", (tester) async {
    await tester.pumpWidget(_wrap(onStart: () {}, onCancel: () {}));
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
    expect(find.text("Remove facial accessories, hats, etc."), findsOneWidget);
  });

  testWidgets("start button invokes onStart", (tester) async {
    var started = 0;
    await tester.pumpWidget(_wrap(onStart: () => started++, onCancel: () {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    expect(started, 1);
  });

  testWidgets("cancel button invokes onCancel", (tester) async {
    var cancelled = 0;
    await tester.pumpWidget(
      _wrap(onStart: () {}, onCancel: () => cancelled++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("bottom_bar_secondary")));
    await tester.pumpAndSettle();

    expect(cancelled, 1);
  });
}
