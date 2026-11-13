import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/app_integrity/app_integrity.dart";
import "package:yivi_core/src/screens/app_integrity/app_integrity_blocked_screen.dart";
import "package:yivi_core/src/screens/rooted_warning/rooted_warning_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

import "helpers/test_translation_loader.dart";

class _FakeAppIntegrity implements AppIntegrity {
  IntegrityReport report;
  int checks = 0;

  _FakeAppIntegrity(this.report);

  @override
  Future<IntegrityReport> check() async {
    checks++;
    return report;
  }
}

/// The value [stream] holds now. Listens and pumps instead of awaiting
/// `stream.first`: the test's fake clock only moves when it is pumped.
Future<T> _current<T>(WidgetTester tester, Stream<T> stream) async {
  final values = <T>[];
  final subscription = stream.listen(values.add);
  await tester.pump();
  subscription.cancel();
  return values.last;
}

Future<IntegrityReport> _firstReport(
  WidgetTester tester,
  AppIntegrityGuard guard,
) => _current(tester, guard.firstReport.asStream());

Future<void> _pumpLocalized(WidgetTester tester, Widget child) async {
  final widget = IrmaTheme(
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
      home: child,
    ),
  );
  // The translation loader does real IO, which the fake clock does not drive.
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

void main() {
  group("IntegrityReport", () {
    test("a debugger or an instrumentation tool is tampering", () {
      expect(const IntegrityReport(debugger: true).tampering, isTrue);
      expect(const IntegrityReport(instrumentation: true).tampering, isTrue);
      expect(IntegrityReport.clean.tampering, isFalse);
    });

    test("an emulator, a container or a hooking framework is an untrusted "
        "environment, not tampering", () {
      for (final report in const [
        IntegrityReport(emulator: true),
        IntegrityReport(virtualized: true),
        IntegrityReport(hookingFramework: true),
      ]) {
        expect(report.untrustedEnvironment, isTrue);
        expect(report.tampering, isFalse);
      }
      expect(IntegrityReport.clean.untrustedEnvironment, isFalse);
    });

    test("reads the map the native side sends, treating anything missing or "
        "malformed as not detected", () {
      final report = IntegrityReport.fromMap({
        "debugger": true,
        "emulator": "yes",
        "virtualized": null,
      });
      expect(report.debugger, isTrue);
      expect(report.emulator, isFalse);
      expect(report.virtualized, isFalse);
      expect(report.instrumentation, isFalse);
    });
  });

  group("AppIntegrityGuard", () {
    testWidgets("blocks when a debugger is attached", (tester) async {
      final guard = AppIntegrityGuard(
        _FakeAppIntegrity(const IntegrityReport(debugger: true)),
        enforce: true,
      );
      await tester.pump();

      expect(await _current(tester, guard.blocked), isTrue);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      guard.dispose();
    });

    testWidgets("does not block in a clean environment", (tester) async {
      final guard = AppIntegrityGuard(
        _FakeAppIntegrity(IntegrityReport.clean),
        enforce: true,
      );
      await tester.pump();

      expect(await _current(tester, guard.blocked), isFalse);
      expect((await _firstReport(tester, guard)).untrustedEnvironment, isFalse);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      guard.dispose();
    });

    testWidgets("does not block on an emulator, but reports it for the "
        "warning", (tester) async {
      final guard = AppIntegrityGuard(
        _FakeAppIntegrity(const IntegrityReport(emulator: true)),
        enforce: true,
      );
      await tester.pump();

      expect(await _current(tester, guard.blocked), isFalse);
      expect((await _firstReport(tester, guard)).untrustedEnvironment, isTrue);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      guard.dispose();
    });

    testWidgets("never looks at the environment when it does not enforce, as "
        "in a debug build", (tester) async {
      final integrity = _FakeAppIntegrity(
        const IntegrityReport(debugger: true, emulator: true),
      );
      final guard = AppIntegrityGuard(integrity, enforce: false);
      await tester.pump(const Duration(minutes: 2));

      expect(integrity.checks, 0);
      expect(await _current(tester, guard.blocked), isFalse);
      expect(await _firstReport(tester, guard), IntegrityReport.clean);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      guard.dispose();
    });

    testWidgets("ignores every signal when the app itself is a debuggable "
        "build", (tester) async {
      final guard = AppIntegrityGuard(
        _FakeAppIntegrity(
          const IntegrityReport(
            debuggable: true,
            debugger: true,
            emulator: true,
          ),
        ),
        enforce: true,
      );
      await tester.pump();

      expect(await _current(tester, guard.blocked), isFalse);
      expect((await _firstReport(tester, guard)).untrustedEnvironment, isFalse);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      guard.dispose();
    });

    testWidgets("notices a tool that attaches later, at the next recheck", (
      tester,
    ) async {
      final integrity = _FakeAppIntegrity(IntegrityReport.clean);
      final guard = AppIntegrityGuard(
        integrity,
        enforce: true,
        recheckInterval: const Duration(seconds: 30),
      );
      final values = <bool>[];
      final subscription = guard.blocked.listen(values.add);
      await tester.pump();
      expect(values, [false]);

      integrity.report = const IntegrityReport(instrumentation: true);
      await tester.pump(const Duration(seconds: 31));

      expect(values, [false, true]);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      subscription.cancel();
      guard.dispose();
    });

    testWidgets("checks again when the app resumes", (tester) async {
      final integrity = _FakeAppIntegrity(IntegrityReport.clean);
      final guard = AppIntegrityGuard(integrity, enforce: true);
      await tester.pump();
      final checksAtStart = integrity.checks;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(integrity.checks, checksAtStart + 1);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      guard.dispose();
    });

    testWidgets("stays blocked after the tool detaches", (tester) async {
      final integrity = _FakeAppIntegrity(
        const IntegrityReport(debugger: true),
      );
      final guard = AppIntegrityGuard(
        integrity,
        enforce: true,
        recheckInterval: const Duration(seconds: 30),
      );
      await tester.pump();

      integrity.report = IntegrityReport.clean;
      await tester.pump(const Duration(seconds: 31));

      expect(await _current(tester, guard.blocked), isTrue);

      // Not in a tear-down: the periodic recheck must be gone before the
      // test body returns.
      guard.dispose();
    });
  });

  group("RealAppIntegrity", () {
    const channel = MethodChannel("yivi.app/app_integrity");
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(TestWidgetsFlutterBinding.ensureInitialized);
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test("reads the report from the native plugin", () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, "check");
        return {"debugger": false, "instrumentation": true, "emulator": true};
      });

      final report = await RealAppIntegrity().check();

      expect(report.instrumentation, isTrue);
      expect(report.emulator, isTrue);
      expect(report.debugger, isFalse);
    });

    test("does not lock the user out when the plugin is missing or "
        "fails", () async {
      expect(await RealAppIntegrity().check(), IntegrityReport.clean);

      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: "app_integrity_failed");
      });
      expect(await RealAppIntegrity().check(), IntegrityReport.clean);
    });
  });

  group("screens", () {
    testWidgets("the blocked screen explains itself and offers no way "
        "past", (tester) async {
      await _pumpLocalized(tester, const AppIntegrityBlockedScreen());

      expect(find.text("Yivi cannot be used right now"), findsOneWidget);
      expect(find.byType(ButtonStyleButton), findsNothing);
    });

    testWidgets("the warning explains an emulator or a cloned app in its own "
        "words", (tester) async {
      await _pumpLocalized(
        tester,
        const RootedWarningScreen(
          explanationTranslationKey: "rooted_warning.explanation_environment",
        ),
      );

      expect(find.textContaining("emulator"), findsOneWidget);
      expect(find.textContaining("Rooted/Jailbreak"), findsNothing);
    });
  });
}
