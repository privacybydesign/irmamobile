import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:yivi/screens/face_verification_entery_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

const String _dummyImage1Path = "integration_test/dummy_images/fake_person_1.jpg";
const String _dummyImage2Path = "integration_test/dummy_images/fake_person_2.jpg";

Future<Uint8List> _loadAssetBytes(String assetPath) async {
  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    if (bytes.isEmpty) {
      throw StateError("Asset exists but is empty: $assetPath");
    }

    return bytes;
  } catch (error) {
    throw StateError(
      "Could not load test asset: $assetPath\n"
      "Check that the file exists under yivi_fdroid/$assetPath and that "
      "yivi_fdroid/pubspec.yaml contains:\n\n"
      "flutter:\n"
      "  assets:\n"
      "    - integration_test/dummy_images/\n\n"
      "Original error: $error",
    );
  }
}

class _FaceVerificationTestApp extends StatelessWidget {
  final Uint8List nfcImageBytes;
  final Uint8List selfieImageBytes;
  final VoidCallback onVerified;

  const _FaceVerificationTestApp({
    required this.nfcImageBytes,
    required this.selfieImageBytes,
    required this.onVerified,
  });

  @override
  Widget build(BuildContext context) {
    return IrmaTheme(
      builder: (context) {
        final irmaTheme = IrmaTheme.of(context);

        return MaterialApp(
          theme: irmaTheme.themeData,
          localizationsDelegates: [
            FlutterI18nDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale("en"), Locale("nl")],
          home: FaceVerificationEntryScreen.withImageTest(
            nfcImageBytes: nfcImageBytes,
            selfieImageBytes: selfieImageBytes,
            photoIssueDate: DateTime.now(),
            onBackPressed: () {},
            onVerified: onVerified,
          ),
        );
      },
    );
  }
}

Future<void> _pumpFaceVerificationTestApp(
  WidgetTester tester, {
  required Uint8List nfcImageBytes,
  required Uint8List selfieImageBytes,
  required VoidCallback onVerified,
}) async {
  await tester.pumpWidget(
    _FaceVerificationTestApp(nfcImageBytes: nfcImageBytes, selfieImageBytes: selfieImageBytes, onVerified: onVerified),
  );

  await tester.pumpAndSettle();
}

Future<void> _tapContinue(WidgetTester tester) async {
  final continueButton = find.byKey(const Key("face_verification_continue_button"));

  expect(continueButton, findsOneWidget);

  await tester.ensureVisible(continueButton);
  await tester.pumpAndSettle();

  await tester.tap(continueButton);
  await tester.pump();

  // Let the verification screen be built.
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group("F-Droid face verification", () {
    testWidgets("passes when NFC image and selfie image are the same", (tester) async {
      var verified = false;

      final image = await _loadAssetBytes(_dummyImage1Path);

      await _pumpFaceVerificationTestApp(
        tester,
        nfcImageBytes: image,
        selfieImageBytes: image,
        onVerified: () {
          verified = true;
        },
      );

      await _tapContinue(tester);

      // Wait for:
      // - image test comparison delay
      // - result screen delay
      // - onVerified callback
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key("face_verification_result_passed")), findsOneWidget);
      expect(verified, isTrue);
    });

    testWidgets("fails when NFC image and selfie image are different", (tester) async {
      var verified = false;

      final nfcImage = await _loadAssetBytes(_dummyImage1Path);
      final selfieImage = await _loadAssetBytes(_dummyImage2Path);

      await _pumpFaceVerificationTestApp(
        tester,
        nfcImageBytes: nfcImage,
        selfieImageBytes: selfieImage,
        onVerified: () {
          verified = true;
        },
      );

      await _tapContinue(tester);

      // Wait for:
      // - image test comparison delay
      // - rejected result screen
      // - transition to failed screen
      await tester.pump(const Duration(seconds: 2));

      expect(find.byKey(const Key("face_verification_failed_screen")), findsOneWidget);
      expect(verified, isFalse);
    });
  });
}
