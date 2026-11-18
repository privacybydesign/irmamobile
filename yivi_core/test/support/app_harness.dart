import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/scheme_rules.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/rooted_device_detector_provider.dart";
import "package:yivi_core/src/screens/rooted_warning/rooted_device_detector.dart";
import "package:yivi_core/yivi_core.dart" show YiviApp;

import "onboarding_v2_harness.dart";
import "pump_translated.dart";

class _Detector implements RootedDeviceDetector {
  _Detector(this.rooted);
  final bool rooted;

  @override
  Future<bool> isDeviceRooted() async => rooted;
}

/// The whole app, as `runYiviApp` starts it (without the scanner, OCR and
/// review services), over a fake bridge: its router,
/// lock overlay and app-wide effects.
class AppHarness {
  AppHarness._(this.bridge, this.repo);

  final RecordingBridge bridge;
  final IrmaRepository repo;

  /// What the app asked the privacy screen channel, in order.
  final privacyScreenCalls = <String>[];

  /// A fresh repository over a clean preference store, with build [build]
  /// installed. Call in `setUp`; closes itself after the test.
  static Future<AppHarness> create({String build = "100"}) async {
    PackageInfo.setMockInitialValues(
      appName: "Yivi",
      packageName: "app.yivi",
      version: "8.4.0",
      buildNumber: build,
      buildSignature: "",
    );
    final bridge = RecordingBridge();
    final harness = AppHarness._(
      bridge,
      IrmaRepository(client: bridge, preferences: await freshPreferences()),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel("privacy_screen"), (
          call,
        ) async {
          harness.privacyScreenCalls.add(call.method);
          return true;
        });
    addTearDown(() async {
      await harness.repo.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel("privacy_screen"),
            null,
          );
    });
    return harness;
  }

  /// Pumps the app on a phone-sized window.
  Future<void> pump(
    WidgetTester tester, {
    bool rooted = false,
    Duration? idleLockThreshold,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: [
          irmaRepositoryProvider.overrideWithValue(repo),
          preferencesProvider.overrideWithValue(repo.preferences),
          rootedDeviceDetectorProvider.overrideWithValue(_Detector(rooted)),
        ],
        child: YiviApp(
          defaultLanguage: const Locale("en", "US"),
          idleLockThreshold: idleLockThreshold,
        ),
      ),
    );
    await run(tester);
  }

  /// Lets events, preference writes and navigation settle.
  Future<void> run(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await settle(tester);
    }
  }

  /// Takes the app down and lets its timers run out, so the test ends with
  /// none pending.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // A notifications reload that was queued behind another starts its
    // timer only once the first is done.
    for (var i = 0; i < 3; i++) {
      await settle(tester);
      await tester.pump(const Duration(seconds: 6));
    }
  }

  GoRouter get router => GoRouter.of(rootNavigatorKey.currentContext!);

  /// Where the router is, as it went there (`go`, a redirect).
  String get location => router.routerDelegate.currentConfiguration.uri.path;

  void enrolled() => bridge.deliver(
    EnrollmentStatusEvent(
      enrolledSchemeManagerIds: ["pbdf"],
      unenrolledSchemeManagerIds: [],
    ),
  );

  void unenrolled() => bridge.deliver(
    EnrollmentStatusEvent(
      enrolledSchemeManagerIds: [],
      unenrolledSchemeManagerIds: ["pbdf"],
    ),
  );

  /// The scheme rules Go sends after loading the schemes.
  void schemes({int minimumBuild = 0}) => bridge.deliver(
    SchemeRulesEvent.fromJson({
      "minimum_app_version": {"android": minimumBuild, "ios": minimumBuild},
      "ul_issue_credential_ids": <String>[],
    }),
  );

  /// The app goes to the background, as the platform reports it.
  void background(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  /// The app comes back to the foreground.
  void foreground(WidgetTester tester) {
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }
}
