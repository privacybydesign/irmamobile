// Where an issue URL opens: the issuer's website in the in-app browser, a
// universal link or an opted-out issuer outside the app, Yivi's own flows
// not at all.
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/irma_configuration.dart";
import "package:yivi_core/src/models/scheme_rules.dart";
import "package:yivi_core/src/providers/contact_issuer_api.dart";
import "package:yivi_core/src/providers/irma_repository_provider.dart";
import "package:yivi_core/src/providers/preferences_provider.dart";

import "support/onboarding_v2_harness.dart";

const _ulType = "irma-demo.digidproef.personalData";
const _ulUrl = "https://example.com/digidproef";
const _plainType = "irma-demo.example.plain";
const _plainUrl = "https://example.com/plain";
const _pubHubsUrl = "https://pubhubs.example.com/issue";
const _demoPubHubsUrl = "https://demo-pubhubs.example.com/issue";

Map<String, dynamic> _credentialType(String fullId, String issueUrl) {
  final [scheme, issuer, id] = fullId.split(".");
  return {
    "ID": id,
    "Name": {"en": id},
    "IssuerID": issuer,
    "SchemeManagerID": scheme,
    "IsSingleton": false,
    "Description": {"en": ""},
    "IssueURL": {"en": issueUrl, "nl": issueUrl},
  };
}

/// What Go sends after loading the schemes, as JSON: which credential types
/// have a universal link as their issue URL.
final Event _rules = SchemeRulesEvent.fromJson({
  "minimum_app_version": {"android": 0, "ios": 0},
  "ul_issue_credential_ids": [_ulType],
});

/// The configuration Go also still sends, as JSON: here only the credential
/// types and their issue URLs matter.
final Event _schemes = IrmaConfigurationEvent.fromJson({
  "irma_configuration": {
    "SchemeManagers": <String, dynamic>{},
    "RequestorSchemes": <String, dynamic>{},
    "Requestors": <String, dynamic>{},
    "Issuers": <String, dynamic>{},
    "CredentialTypes": {
      _ulType: _credentialType(_ulType, _ulUrl),
      _plainType: _credentialType(_plainType, _plainUrl),
      "pbdf.PubHubs.account": _credentialType(
        "pbdf.PubHubs.account",
        _pubHubsUrl,
      ),
      "irma-demo.PubHubs.account": _credentialType(
        "irma-demo.PubHubs.account",
        _demoPubHubsUrl,
      ),
    },
    "AttributeTypes": <String, dynamic>{},
    "Path": "",
  },
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
  /// tests) and delivers the scheme rules and the configuration.
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
    bridge.deliver(_schemes);
    await settle(tester);
    return (context: context, ref: ref);
  }

  Future<void> openIssueURL(
    WidgetTester tester,
    String credentialId,
    String? url,
  ) async {
    final app = await setUpApp(tester);
    await tester.runAsync(
      () => repo.openIssueURL(app.context, credentialId, url, app.ref),
    );
  }

  group("openIssueURL", () {
    testWidgets("10. a universal-link type opens outside the app", (
      tester,
    ) async {
      await openIssueURL(tester, _ulType, _ulUrl);
      expect(launches, [(url: _ulUrl, inApp: false)]);
    });

    testWidgets("11. PubHubs accounts open outside the app", (tester) async {
      final app = await setUpApp(tester);
      for (final (type, url) in [
        ("pbdf.PubHubs.account", _pubHubsUrl),
        ("irma-demo.PubHubs.account", _demoPubHubsUrl),
      ]) {
        await tester.runAsync(
          () => repo.openIssueURL(app.context, type, url, app.ref),
        );
      }
      expect(launches, [
        (url: _pubHubsUrl, inApp: false),
        (url: _demoPubHubsUrl, inApp: false),
      ]);
    });

    testWidgets("12. a plain type opens in the app", (tester) async {
      await openIssueURL(tester, _plainType, _plainUrl);
      expect(launches, [(url: _plainUrl, inApp: true)]);
    });

    testWidgets("13. a type the schemes do not know opens in the app", (
      tester,
    ) async {
      const url = "https://example.com/unknown";
      await openIssueURL(tester, "irma-demo.example.unknown", url);
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
        () => repo.openIssueURL(
          app.context,
          "pbdf.sidn-pbdf.email",
          "https://email.example.com/start/path",
          app.ref,
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
          () => repo.openIssueURL(app.context, _plainType, url, app.ref),
          throwsA(isA<UnsupportedError>()),
        );
      }
      expect(launches, isEmpty);
    });
  });

  group("openURL", () {
    testWidgets("16. a URL that is no opted-out issue URL opens in the app", (
      tester,
    ) async {
      await setUpApp(tester);
      await tester.runAsync(() => repo.openURL(_plainUrl));
      expect(launches, [(url: _plainUrl, inApp: true)]);
    });

    testWidgets("17. PubHubs' issue URL opens outside the app", (tester) async {
      await setUpApp(tester);
      await tester.runAsync(() => repo.openURL(_pubHubsUrl));
      expect(launches, [(url: _pubHubsUrl, inApp: false)]);
    });
  });
}
