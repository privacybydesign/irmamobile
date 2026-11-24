// Where an issue URL opens: the issuer's website in the in-app browser, a
// universal link or an issuer whose website breaks in the in-app browser
// outside the app, Yivi's own flows not at all. Other links open in the app.
import "package:flutter/foundation.dart" show defaultTargetPlatform;
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/data/issuance_launcher.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/scheme_rules.dart";
import "package:yivi_core/src/providers/contact_issuer_api_provider.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";

import "support/onboarding_v2_harness.dart";

const _ulType = "irma-demo.digidproef.personalData";
const _ulUrl = "https://example.com/digidproef";
const _plainType = "irma-demo.example.plain";
const _plainUrl = "https://example.com/plain";
const _pubHubsUrl = "https://pubhubs.example.com/issue";
const _demoPubHubsUrl = "https://demo-pubhubs.example.com/issue";

/// What Go sends after loading the schemes, as JSON: which credential types
/// have a universal link as their issue URL.
final Event _rules = SchemeRulesEvent.fromJson({
  "minimum_app_version": {"android": 0, "ios": 0},
  "ul_issue_credential_ids": [_ulType],
});

/// One url_launcher call: the URL and whether it asked for a web view in the
/// app (false: an application outside it, such as the browser).
typedef _Launch = ({String url, bool inApp});

void main() {
  late RecordingBridge bridge;
  late IrmaRepository repo;
  late List<_Launch> launches;

  setUp(() async {
    bridge = RecordingBridge();
    repo = IrmaRepository(
      client: bridge,
      preferences: await freshPreferences(),
    );
    launches = [];
  });
  tearDown(() => repo.close());

  /// Pumps a widget for its context and ref, records url_launcher's calls
  /// (its default platform channel; no platform plugin is registered in
  /// tests) and delivers the scheme rules.
  Future<({BuildContext context, WidgetRef ref})> setUpApp(
    WidgetTester tester,
  ) async {
    const channel = MethodChannel("plugins.flutter.io/url_launcher");
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != "launch") return false;
      final arguments = call.arguments as Map<Object?, Object?>;
      launches.add((
        url: arguments["url"]! as String,
        inApp: arguments["useWebView"]! as bool,
      ));
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    late BuildContext context;
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          irmaRepositoryProvider.overrideWithValue(repo),
          preferencesProvider.overrideWithValue(repo.preferences),
        ],
        child: Consumer(
          builder: (c, r, _) {
            context = c;
            ref = r;
            return const SizedBox();
          },
        ),
      ),
    );
    bridge.deliver(_rules);
    await settle(tester);
    return (context: context, ref: ref);
  }

  Future<void> openIssue(
    WidgetTester tester,
    String credentialId,
    String? url,
  ) async {
    final app = await setUpApp(tester);
    await tester.runAsync(
      () => app.ref.read(issuanceLauncherProvider).open(credentialId, url),
    );
  }

  group("IssuanceLauncher.open", () {
    testWidgets("10. a universal-link type opens outside the app", (
      tester,
    ) async {
      await openIssue(tester, _ulType, _ulUrl);
      expect(launches, [(url: _ulUrl, inApp: false)]);
    });

    testWidgets(
      "11b. the VOG opens outside the app: its page has to survive the trip "
      "to Yivi and back",
      (tester) async {
        const vogUrl = "https://vog.example.com/issue";
        final app = await setUpApp(tester);
        for (final type in ["pbdf.pbdf.vog", "pbdf-staging.pbdf.vog"]) {
          await tester.runAsync(
            () => app.ref.read(issuanceLauncherProvider).open(type, vogUrl),
          );
        }
        expect(launches, [
          (url: vogUrl, inApp: false),
          (url: vogUrl, inApp: false),
        ]);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );

    testWidgets(
      "11. PubHubs accounts open outside the app",
      (tester) async {
        final app = await setUpApp(tester);
        for (final (type, url) in [
          ("pbdf.PubHubs.account", _pubHubsUrl),
          ("irma-demo.PubHubs.account", _demoPubHubsUrl),
        ]) {
          await tester.runAsync(
            () => app.ref.read(issuanceLauncherProvider).open(type, url),
          );
        }
        expect(launches, [
          (url: _pubHubsUrl, inApp: false),
          (url: _demoPubHubsUrl, inApp: false),
        ]);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );

    testWidgets(
      "gemeente opens outside the app on iOS, in the app on Android",
      (tester) async {
        final app = await setUpApp(tester);
        const url = "https://gemeente.example.com/issue";
        for (final type in [
          "pbdf.gemeente.address",
          "pbdf.gemeente.personalData",
        ]) {
          await tester.runAsync(
            () => app.ref.read(issuanceLauncherProvider).open(type, url),
          );
        }
        final inApp = defaultTargetPlatform != TargetPlatform.iOS;
        expect(launches, [(url: url, inApp: inApp), (url: url, inApp: inApp)]);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );

    testWidgets(
      "iDIN and age limits open outside the app on Android, in the app on iOS",
      (tester) async {
        final app = await setUpApp(tester);
        // Both are issued on the same website.
        const url = "https://idin-issuer.example.com/";
        for (final type in ["pbdf.pbdf.idin", "pbdf.pbdf.ageLimits"]) {
          await tester.runAsync(
            () => app.ref.read(issuanceLauncherProvider).open(type, url),
          );
        }
        final inApp = defaultTargetPlatform != TargetPlatform.android;
        expect(launches, [(url: url, inApp: inApp), (url: url, inApp: inApp)]);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );

    testWidgets("12. a plain type opens in the app", (tester) async {
      await openIssue(tester, _plainType, _plainUrl);
      expect(launches, [(url: _plainUrl, inApp: true)]);
    });

    testWidgets("13. a type in no list opens in the app", (tester) async {
      const url = "https://example.com/unknown";
      await openIssue(tester, "irma-demo.example.unknown", url);
      expect(launches, [(url: url, inApp: true)]);
    });

    testWidgets("14. an embedded type (e-mail) launches nothing", (
      tester,
    ) async {
      final app = await setUpApp(tester);
      // The e-mail address is added in the sheet, which never comes here:
      // in debug builds the call asserts after pointing the flow at the
      // issuer.
      await expectLater(
        () => app.ref
            .read(issuanceLauncherProvider)
            .open(
              "pbdf.sidn-pbdf.email",
              "https://email.example.com/start/path",
            ),
        throwsA(isA<AssertionError>()),
      );
      expect(launches, isEmpty);
      expect(app.ref.read(emailIssuerUrlProvider), "https://email.example.com");
    });

    testWidgets("15. an empty issue URL is unsupported", (tester) async {
      final app = await setUpApp(tester);
      for (final url in [null, ""]) {
        await expectLater(
          () => app.ref.read(issuanceLauncherProvider).open(_plainType, url),
          throwsA(isA<UnsupportedError>()),
        );
      }
      expect(launches, isEmpty);
    });
  });

  group("Browser.openLink", () {
    testWidgets("16b. only an https link opens in the app", (tester) async {
      final app = await setUpApp(tester);
      for (final url in ["http://example.com", "mailto:support@yivi.app"]) {
        await tester.runAsync(() => app.ref.read(browserProvider).openLink(url));
      }
      expect(launches, [
        (url: "http://example.com", inApp: false),
        (url: "mailto:support@yivi.app", inApp: false),
      ]);
    });

    testWidgets("16. a link opens in the app", (tester) async {
      final app = await setUpApp(tester);
      await tester.runAsync(
        () => app.ref.read(browserProvider).openLink(_plainUrl),
      );
      expect(launches, [(url: _plainUrl, inApp: true)]);
    });

    testWidgets(
      "17. a link equal to an issue URL that opens outside the app still "
      "opens in the app",
      (tester) async {
        final app = await setUpApp(tester);
        await tester.runAsync(
          () => app.ref.read(browserProvider).openLink(_pubHubsUrl),
        );
        expect(launches, [(url: _pubHubsUrl, inApp: true)]);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  });
}
