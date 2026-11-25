import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/irma_configuration.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/providers/digital_credentials_registry_provider.dart";

// The platform only routes a Digital Credentials API request to Yivi when it
// matches a registered entry, so what is registered decides which credentials a
// website can ask for at all. It follows the scheme: every credential type of
// pbdf, the same for every user.

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

class _RecordingRegistry implements DigitalCredentialsRegistry {
  final registrations = <List<DigitalCredentialsRegistryEntry>>[];

  @override
  Future<void> register(List<DigitalCredentialsRegistryEntry> entries) async {
    registrations.add(entries);
  }
}

class _FailingRegistry implements DigitalCredentialsRegistry {
  @override
  Future<void> register(List<DigitalCredentialsRegistryEntry> entries) =>
      Future.error(StateError("no Play services"));
}

TranslatedValue _name(String en, [String? nl]) =>
    TranslatedValue({"en": en, "nl": ?nl});

CredentialType _credentialType(
  String scheme,
  String issuer,
  String id, {
  TranslatedValue? name,
  String? logo,
}) => CredentialType(
  id: id,
  name: name ?? _name(id),
  issuerId: issuer,
  schemeManagerId: scheme,
  isSingleton: false,
  description: const TranslatedValue.empty(),
  logo: logo,
);

AttributeType _attribute(
  String scheme,
  String issuer,
  String credentialType,
  String id, {
  required int index,
  TranslatedValue? name,
}) => AttributeType(
  id: id,
  index: index,
  credentialTypeId: credentialType,
  issuerId: issuer,
  schemeManagerId: scheme,
  name: name ?? _name(id),
);

Issuer _issuer(String scheme, String id, TranslatedValue name) => Issuer(
  id: id,
  name: name,
  schemeManagerId: scheme,
  contactAddress: "",
  contactEmail: "",
);

IrmaConfiguration _configuration({
  List<Issuer> issuers = const [],
  List<CredentialType> credentialTypes = const [],
  List<AttributeType> attributeTypes = const [],
}) => IrmaConfiguration(
  schemeManagers: const {},
  requestorSchemes: const {},
  requestors: const {},
  issuers: {for (final issuer in issuers) issuer.fullId: issuer},
  credentialTypes: {for (final type in credentialTypes) type.fullId: type},
  attributeTypes: {for (final type in attributeTypes) type.fullId: type},
  issueWizards: const {},
  path: "",
);

/// pbdf's email credential, next to the same credential in the demo scheme.
IrmaConfiguration _emailConfiguration() => _configuration(
  issuers: [
    _issuer(
      "pbdf",
      "sidn-pbdf",
      _name(
        "Privacy by Design Foundation via SIDN",
        "Stichting Privacy by Design via SIDN",
      ),
    ),
    _issuer("irma-demo", "sidn-pbdf", _name("Demo issuer")),
  ],
  credentialTypes: [
    _credentialType(
      "pbdf",
      "sidn-pbdf",
      "email",
      name: _name("Email address", "E-mailadres"),
      logo: "/schemes/pbdf/sidn-pbdf/Issues/email/logo.png",
    ),
    _credentialType("irma-demo", "sidn-pbdf", "email"),
  ],
  attributeTypes: [
    // Out of order on purpose: the map the core sends has no order.
    _attribute(
      "pbdf",
      "sidn-pbdf",
      "email",
      "domain",
      index: 1,
      name: _name("Email domain name", "E-maildomeinnaam"),
    ),
    _attribute(
      "pbdf",
      "sidn-pbdf",
      "email",
      "email",
      index: 0,
      name: _name("Email address", "E-mailadres"),
    ),
    _attribute("irma-demo", "sidn-pbdf", "email", "email", index: 0),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Digital Credentials registry entries", () {
    test("a credential type is registered under its full id, with its "
        "attributes as claims", () {
      final entries = digitalCredentialsRegistryEntries(
        _emailConfiguration(),
        language: "en",
      );

      expect(entries, hasLength(1));
      final email = entries.single;
      // What a request's vct_values has to name.
      expect(email.credentialType, "pbdf.sidn-pbdf.email");
      expect(email.name, "Email address");
      expect(email.issuerName, "Privacy by Design Foundation via SIDN");
      expect(email.logoPath, "/schemes/pbdf/sidn-pbdf/Issues/email/logo.png");
      // What a request's claim paths have to name, in the scheme's order.
      expect(email.claims.map((claim) => claim.id), ["email", "domain"]);
      expect(email.claims.map((claim) => claim.name), [
        "Email address",
        "Email domain name",
      ]);
    });

    test("only the credential types of pbdf are registered", () {
      final entries = digitalCredentialsRegistryEntries(
        _emailConfiguration(),
        language: "en",
      );

      expect(
        entries.map((entry) => entry.credentialType),
        everyElement(startsWith("pbdf.")),
      );
    });

    test("names follow the app language, falling back to English", () {
      final dutch = digitalCredentialsRegistryEntries(
        _emailConfiguration(),
        language: "nl",
      ).single;
      expect(dutch.name, "E-mailadres");
      expect(dutch.issuerName, "Stichting Privacy by Design via SIDN");
      expect(dutch.claims.map((claim) => claim.name), [
        "E-mailadres",
        "E-maildomeinnaam",
      ]);

      final german = digitalCredentialsRegistryEntries(
        _emailConfiguration(),
        language: "de",
      ).single;
      expect(german.name, "Email address");
    });

    test("a revocation attribute is not a claim", () {
      final entries = digitalCredentialsRegistryEntries(
        _configuration(
          credentialTypes: [_credentialType("pbdf", "pbdf", "passport")],
          attributeTypes: [
            _attribute("pbdf", "pbdf", "passport", "firstnames", index: 0),
            // The core sends a revocation attribute without a name.
            _attribute(
              "pbdf",
              "pbdf",
              "passport",
              "revocation",
              index: 1,
              name: const TranslatedValue.empty(),
            ),
          ],
        ),
        language: "en",
      );

      expect(entries.single.claims.map((claim) => claim.id), ["firstnames"]);
    });

    test("a credential type without attributes is left out", () {
      final entries = digitalCredentialsRegistryEntries(
        _configuration(
          credentialTypes: [_credentialType("pbdf", "pbdf", "empty")],
        ),
        language: "en",
      );

      expect(entries, isEmpty);
    });

    test("a credential type without a logo or a known issuer is still "
        "registered", () {
      final entry = digitalCredentialsRegistryEntries(
        _configuration(
          credentialTypes: [_credentialType("pbdf", "gone", "diploma")],
          attributeTypes: [
            _attribute("pbdf", "gone", "diploma", "degree", index: 0),
          ],
        ),
        language: "en",
      ).single;

      expect(entry.logoPath, isNull);
      expect(entry.issuerName, "");
    });

    test("the order does not depend on the order of the configuration", () {
      List<String> registered(List<String> ids) =>
          digitalCredentialsRegistryEntries(
            _configuration(
              credentialTypes: [
                for (final id in ids) _credentialType("pbdf", "pbdf", id),
              ],
              attributeTypes: [
                for (final id in ids)
                  _attribute("pbdf", "pbdf", id, "value", index: 0),
              ],
            ),
            language: "en",
          ).map((entry) => entry.credentialType).toList();

      expect(registered(["mobilenumber", "email"]), [
        "pbdf.pbdf.email",
        "pbdf.pbdf.mobilenumber",
      ]);
      expect(
        registered(["mobilenumber", "email"]),
        registered(["email", "mobilenumber"]),
      );
    });

    test("an entry is sent to native under the keys the registrar reads", () {
      final entry = digitalCredentialsRegistryEntries(
        _emailConfiguration(),
        language: "en",
      ).single;

      expect(entry.toJson(), {
        "credential_type": "pbdf.sidn-pbdf.email",
        "name": "Email address",
        "issuer_name": "Privacy by Design Foundation via SIDN",
        "logo_path": "/schemes/pbdf/sidn-pbdf/Issues/email/logo.png",
        "claims": [
          {"id": "email", "name": "Email address"},
          {"id": "domain", "name": "Email domain name"},
        ],
      });
    });
  });

  group("Digital Credentials registration", () {
    Future<IrmaRepository> repository(
      DigitalCredentialsRegistry? registry,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = IrmaRepository(
        client: _SilentBridge(),
        preferences: await IrmaPreferences.fromInstance(
          mostRecentTermsUrlNl: "",
          mostRecentTermsUrlEn: "",
        ),
        digitalCredentialsRegistry: registry,
      );
      addTearDown(repo.close);
      return repo;
    }

    test("nothing is registered before the scheme is known", () async {
      final registry = _RecordingRegistry();
      await repository(registry);
      await pumpEventQueue();

      expect(registry.registrations, isEmpty);
    });

    test("the scheme is registered once the core has loaded it", () async {
      final registry = _RecordingRegistry();
      final repo = await repository(registry);

      repo.dispatch(
        IrmaConfigurationEvent(irmaConfiguration: _emailConfiguration()),
      );
      await pumpEventQueue();

      expect(registry.registrations, hasLength(1));
      expect(
        registry.registrations.single.map((entry) => entry.credentialType),
        ["pbdf.sidn-pbdf.email"],
      );
    });

    test("an updated scheme is registered again", () async {
      final registry = _RecordingRegistry();
      final repo = await repository(registry);

      repo.dispatch(
        IrmaConfigurationEvent(irmaConfiguration: _emailConfiguration()),
      );
      repo.dispatch(
        IrmaConfigurationEvent(
          irmaConfiguration: _configuration(
            credentialTypes: [_credentialType("pbdf", "pbdf", "mobilenumber")],
            attributeTypes: [
              _attribute(
                "pbdf",
                "pbdf",
                "mobilenumber",
                "mobilenumber",
                index: 0,
              ),
            ],
          ),
        ),
      );
      await pumpEventQueue();

      expect(registry.registrations.last.map((entry) => entry.credentialType), [
        "pbdf.pbdf.mobilenumber",
      ]);
    });

    test("a change of app language registers the names again", () async {
      final registry = _RecordingRegistry();
      final repo = await repository(registry);
      repo.dispatch(
        IrmaConfigurationEvent(irmaConfiguration: _emailConfiguration()),
      );
      await pumpEventQueue();
      expect(registry.registrations.last.single.name, "Email address");

      await repo.preferences.setPreferredLanguageCode("nl");
      await pumpEventQueue();

      expect(registry.registrations.last.single.name, "E-mailadres");
    });

    test("a registry that fails is reported and does not break loading the "
        "scheme", () async {
      final reported = <Object>[];
      final onError = FlutterError.onError;
      FlutterError.onError = (details) => reported.add(details.exception);
      addTearDown(() => FlutterError.onError = onError);

      final repo = await repository(_FailingRegistry());
      repo.dispatch(
        IrmaConfigurationEvent(irmaConfiguration: _emailConfiguration()),
      );
      await pumpEventQueue();

      expect(reported, [isA<StateError>()]);
      expect(repo.irmaConfiguration.credentialTypes, isNotEmpty);
    });

    test("a build without a registry registers nothing", () async {
      final repo = await repository(null);

      repo.dispatch(
        IrmaConfigurationEvent(irmaConfiguration: _emailConfiguration()),
      );
      await pumpEventQueue();

      expect(repo.irmaConfiguration.credentialTypes, isNotEmpty);
    });
  });
}
