import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/irma_configuration.dart";
import "package:yivi_core/src/models/translated_value.dart";

class _FakeBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}

  void receive(Event event) => addEvent(event);
}

CredentialType _credentialType(String fullId, Map<String, String> issueUrl) {
  final [scheme, issuer, id] = fullId.split(".");
  return CredentialType(
    id: id,
    name: TranslatedValue.fromString(id),
    issuerId: issuer,
    schemeManagerId: scheme,
    isSingleton: false,
    description: const TranslatedValue.empty(),
    issueUrl: TranslatedValue(issueUrl),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The schemes bundled with the app are older than the VOG credential, so
  // these tests hand the repository a configuration of their own.
  Future<List<String>> externalBrowserUrls(
    Map<String, Map<String, String>> issueUrls,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await IrmaPreferences.fromInstance(
      mostRecentTermsUrlNl: "",
      mostRecentTermsUrlEn: "",
    );
    final bridge = _FakeBridge();
    final repository = IrmaRepository(client: bridge, preferences: preferences);
    addTearDown(repository.close);

    bridge.receive(
      IrmaConfigurationEvent(
        irmaConfiguration: IrmaConfiguration(
          schemeManagers: const {},
          requestorSchemes: const {},
          requestors: const {},
          issuers: const {},
          credentialTypes: {
            for (final entry in issueUrls.entries)
              entry.key: _credentialType(entry.key, entry.value),
          },
          attributeTypes: const {},
          issueWizards: const {},
          path: "",
        ),
      ),
    );
    return repository.getExternalBrowserURLs().first;
  }

  group("getExternalBrowserURLs", () {
    test("opens the VOG issuer in the external browser", () async {
      final urls = await externalBrowserUrls({
        "pbdf.pbdf.vog": {
          "en": "https://vog.yivi.app/en",
          "nl": "https://vog.yivi.app/nl",
        },
        "pbdf-staging.pbdf.vog": {
          "en": "https://vog.staging.yivi.app/en",
          "nl": "https://vog.staging.yivi.app/nl",
        },
      });

      expect(
        urls,
        unorderedEquals([
          "https://vog.yivi.app/en",
          "https://vog.yivi.app/nl",
          "https://vog.staging.yivi.app/en",
          "https://vog.staging.yivi.app/nl",
        ]),
      );
    });

    test("leaves other credentials in the in-app browser", () async {
      final urls = await externalBrowserUrls({
        "pbdf.pbdf.surfnet-2": {"en": "https://surfconext-issuer.yivi.app/"},
      });

      expect(urls, isEmpty);
    });
  });
}
