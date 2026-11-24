import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/platform/privacy_screen.dart";

import "helpers/test_translation_loader.dart";

/// Records what the `privacy_screen` channel is asked to do, so the balance of
/// suspend/resume calls is observable from a unit test.
List<String> _recordChannelCalls() {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel("privacy_screen"), (
        call,
      ) async {
        calls.add(call.method);
        return true;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel("privacy_screen"), null),
  );
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("suspendDuring brackets the action and returns its value", () async {
    final calls = _recordChannelCalls();

    final result = await PrivacyScreen.suspendDuring(() async {
      expect(calls, ["suspendPrivacyScreen"]);
      return 42;
    });

    expect(result, 42);
    expect(calls, ["suspendPrivacyScreen", "resumePrivacyScreen"]);
  });

  test("suspendDuring resumes when the action throws", () async {
    final calls = _recordChannelCalls();

    await expectLater(
      PrivacyScreen.suspendDuring(() async => throw StateError("boom")),
      throwsStateError,
    );

    expect(calls, ["suspendPrivacyScreen", "resumePrivacyScreen"]);
  });

  test("suspendDuring nests: the inner flow does not resume early", () async {
    final calls = _recordChannelCalls();

    await PrivacyScreen.suspendDuring(() async {
      await PrivacyScreen.suspendDuring(() async {});
      // The outer flow is still running, so the privacy screen must still be
      // held back — the native side counts suspensions for exactly this.
      expect(calls, [
        "suspendPrivacyScreen",
        "suspendPrivacyScreen",
        "resumePrivacyScreen",
      ]);
    });

    expect(calls, [
      "suspendPrivacyScreen",
      "suspendPrivacyScreen",
      "resumePrivacyScreen",
      "resumePrivacyScreen",
    ]);
  });

  test("enable and disable leave the suspension count alone", () async {
    final calls = _recordChannelCalls();

    await PrivacyScreen.enablePrivacyScreen();
    await PrivacyScreen.disablePrivacyScreen();

    expect(calls, ["enablePrivacyScreen", "disablePrivacyScreen"]);
  });

  group("the capture cover text", () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel("privacy_screen");

    List<Object?> recordCoverTexts() {
      final texts = <Object?>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == "setCaptureCoverText") texts.add(call.arguments);
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      return texts;
    }

    Future<void> pumpApp(WidgetTester tester, Locale locale) async {
      final widget = WidgetsApp(
        color: const Color(0xFF000000),
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: TestTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: locale,
            ),
          ),
        ],
        builder: (context, child) =>
            const CaptureCoverText(child: SizedBox.shrink()),
      );
      // The translation loader does real IO, which the fake clock does not
      // drive.
      await tester.runAsync(() async {
        await tester.pumpWidget(widget);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
    }

    testWidgets("is sent to iOS in the language the app is set to", (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final texts = recordCoverTexts();

      await pumpApp(tester, const Locale("nl", "NL"));

      expect(texts, [
        "Yivi is verborgen zolang je scherm wordt opgenomen of gedeeld.",
      ]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets("is not sent on Android, which has no cover", (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final texts = recordCoverTexts();

      await pumpApp(tester, const Locale("nl", "NL"));

      expect(texts, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
