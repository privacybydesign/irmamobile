// The required-update redirect: which build the schemes ask for, read from
// what the bridge sends, and where the router sends the user.
import "dart:math";

import "package:flutter/foundation.dart" show defaultTargetPlatform;
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:yivi_core/routing.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/enrollment_status.dart";
import "package:yivi_core/src/models/error_event.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/scheme_rules.dart";
import "package:yivi_core/src/models/version_information.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";
import "package:yivi_core/src/providers/rooted_device_detector_provider.dart";
import "package:yivi_core/src/screens/rooted_warning/rooted_device_detector.dart";

import "support/onboarding_v2_harness.dart";

class _NotRooted implements RootedDeviceDetector {
  @override
  Future<bool> isDeviceRooted() async => false;
}

/// The minimum app build one scheme asks for, per platform.
typedef _Minimum = ({int android, int ios});

/// What Go sends after loading the schemes, as JSON: the highest minimum
/// per platform over the scheme managers (Go's schemes_test checks that it
/// takes the highest).
Event _schemes(List<_Minimum> minimums) => SchemeRulesEvent.fromJson({
  "minimum_app_version": {
    "android": minimums.map((m) => m.android).fold(0, max),
    "ios": minimums.map((m) => m.ios).fold(0, max),
  },
  "ul_issue_credential_ids": <String>[],
});

_Minimum _both(int build) => (android: build, ios: build);

final _enrolled = EnrollmentStatusEvent.fromJson({
  "enrolled_scheme_manager_ids": ["pbdf"],
  "unenrolled_scheme_manager_ids": <String>[],
});

final _unenrolled = EnrollmentStatusEvent.fromJson({
  "enrolled_scheme_manager_ids": <String>[],
  "unenrolled_scheme_manager_ids": ["pbdf"],
});

void _installedBuild(String buildNumber) => PackageInfo.setMockInitialValues(
  appName: "Yivi",
  packageName: "app.yivi",
  version: "8.4.0",
  buildNumber: buildNumber,
  buildSignature: "",
);

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;

  setUp(() async {
    _installedBuild("100");
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    // Not part of these tests: the redirect to the name change comes first.
    await repo.preferences.showNameChangedNotification.set(false);
  });
  tearDown(() => repo.close());

  /// The app's router, built as the app builds it, and a way to ask its
  /// top-level redirect where a visit to the home screen goes.
  Future<String? Function()> pumpRouter(WidgetTester tester) async {
    late GoRouter router;
    late BuildContext routerContext;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          irmaRepositoryProvider.overrideWithValue(repo),
          preferencesProvider.overrideWithValue(repo.preferences),
          rootedDeviceDetectorProvider.overrideWithValue(_NotRooted()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            routerContext = context;
            router = createRouter(context, ref);
            return const SizedBox();
          },
        ),
      ),
    );
    addTearDown(router.dispose);
    await settle(tester);
    return () =>
        router.configuration.topRedirect(
              routerContext,
              GoRouterState(
                router.configuration,
                uri: Uri.parse("/home"),
                matchedLocation: "/home",
                fullPath: "/home",
                pathParameters: const {},
                pageKey: const ValueKey("home"),
              ),
            )
            as String?;
  }

  /// Sends [event] as the bridge would and lets it reach every stream.
  Future<void> deliver(WidgetTester tester, Event event) async {
    bridge.deliver(event);
    await settle(tester);
    await settle(tester);
  }

  /// The redirect triggers, followed from now on.
  RedirectionListenable triggers() {
    final listenable = RedirectionListenable(repo, _NotRooted());
    addTearDown(listenable.dispose);
    return listenable;
  }

  testWidgets(
    "1. before the first scheme event the triggers keep their defaults",
    (tester) async {
      final redirect = await pumpRouter(tester);
      final listenable = triggers();
      await deliver(tester, _unenrolled);

      expect(listenable.value, RedirectionTriggers.withDefaults());
      expect(redirect(), isNull);

      // The scheme event opens the gate: enrollment status and all.
      await deliver(tester, _schemes([_both(101)]));
      expect(listenable.value.enrollmentStatus, EnrollmentStatus.unenrolled);
      expect(redirect(), "/enrollment");
    },
  );

  testWidgets("2. a minimum above the installed build requires the update", (
    tester,
  ) async {
    final redirect = await pumpRouter(tester);
    final listenable = triggers();
    await deliver(tester, _enrolled);
    await deliver(tester, _schemes([_both(101)]));

    expect(
      listenable.value.versionInformation,
      VersionInformation(
        availableVersion: 101,
        requiredVersion: 101,
        currentVersion: 100,
      ),
    );
    expect(listenable.value.versionInformation!.updateRequired(), isTrue);
    expect(redirect(), "/update_required");
  });

  for (final minimum in [100, 99]) {
    testWidgets("3. minimum $minimum with build 100 needs no update", (
      tester,
    ) async {
      final redirect = await pumpRouter(tester);
      final listenable = triggers();
      await deliver(tester, _enrolled);
      await deliver(tester, _schemes([_both(minimum)]));

      expect(listenable.value.versionInformation!.requiredVersion, minimum);
      expect(listenable.value.versionInformation!.updateRequired(), isFalse);
      expect(redirect(), isNull);
    });
  }

  testWidgets("4. the highest minimum over all schemes counts", (tester) async {
    final redirect = await pumpRouter(tester);
    final listenable = triggers();
    await deliver(tester, _enrolled);
    await deliver(tester, _schemes([_both(90), _both(101)]));

    expect(listenable.value.versionInformation!.requiredVersion, 101);
    expect(redirect(), "/update_required");
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    "4. each platform reads its own minimum",
    (tester) async {
      final redirect = await pumpRouter(tester);
      final listenable = triggers();
      await deliver(tester, _enrolled);
      await deliver(tester, _schemes([(android: 101, ios: 90)]));

      final android = defaultTargetPlatform == TargetPlatform.android;
      expect(
        listenable.value.versionInformation!.requiredVersion,
        android ? 101 : 90,
      );
      expect(redirect(), android ? "/update_required" : isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets("5. unenrolled goes to enrollment before the update", (
    tester,
  ) async {
    final redirect = await pumpRouter(tester);
    await deliver(tester, _unenrolled);
    await deliver(tester, _schemes([_both(101)]));

    expect(redirect(), "/enrollment");
  });

  testWidgets("6. a build number that is no number needs no update", (
    tester,
  ) async {
    _installedBuild("abc");
    final redirect = await pumpRouter(tester);
    final listenable = triggers();
    await deliver(tester, _enrolled);
    await deliver(tester, _schemes([_both(101)]));

    expect(
      listenable.value.versionInformation,
      VersionInformation(
        availableVersion: 101,
        requiredVersion: 101,
        currentVersion: 101,
      ),
    );
    expect(redirect(), isNull);
  });

  testWidgets(
    "7. a fatal error before the schemes leaves no version; enrollment "
    "still redirects",
    (tester) async {
      final redirect = await pumpRouter(tester);
      final listenable = triggers();
      await deliver(
        tester,
        ErrorEvent(exception: "start-up failed", stack: "", fatal: true),
      );
      await deliver(tester, _unenrolled);

      expect(listenable.value.versionInformation, isNull);
      expect(listenable.value.enrollmentStatus, EnrollmentStatus.unenrolled);
      expect(redirect(), "/enrollment");
    },
  );

  testWidgets("8. first launch after an update, then a scheme update", (
    tester,
  ) async {
    // The new build starts with the schemes the old build left on disk.
    _installedBuild("200");
    final redirect = await pumpRouter(tester);
    final listenable = triggers();
    await deliver(tester, _enrolled);
    await deliver(tester, _schemes([_both(150)]));

    expect(listenable.value.versionInformation!.currentVersion, 200);
    expect(listenable.value.versionInformation!.updateRequired(), isFalse);
    expect(redirect(), isNull, reason: "home, no update screen");

    // A scheme update while the app runs raises the minimum.
    await deliver(tester, _schemes([_both(201)]));

    expect(listenable.value.versionInformation!.requiredVersion, 201);
    expect(redirect(), "/update_required", reason: "without a restart");
  });

  testWidgets("9. without scheme managers no update is needed", (tester) async {
    final redirect = await pumpRouter(tester);
    final listenable = triggers();
    await deliver(tester, _enrolled);
    await deliver(tester, _schemes([]));

    expect(listenable.value.versionInformation!.requiredVersion, 0);
    expect(redirect(), isNull);
  });
}
