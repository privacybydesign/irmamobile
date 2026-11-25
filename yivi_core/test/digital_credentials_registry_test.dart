import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_bridge.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/data/irma_repository.dart";
import "package:yivi_core/src/models/digital_credentials.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/providers/digital_credentials_registry_provider.dart";

// The platform only routes a Digital Credentials API request to Yivi when it
// matches a registered entry, so what is registered decides which credentials a
// website can ask for at all. The Go core decides what that is
// (`GetDigitalCredentialsRegistry` in irmago, tested there); Dart only has to
// get the entries to the registry as they came.

class _SilentBridge extends IrmaBridge {
  @override
  void dispatch(Event event) {}
}

class _RecordingRegistry implements DigitalCredentialsRegistry {
  final registrations = <List<Map<String, dynamic>>>[];

  @override
  Future<void> register(List<Map<String, dynamic>> entries) async {
    registrations.add(entries);
  }
}

class _FailingRegistry implements DigitalCredentialsRegistry {
  @override
  Future<void> register(List<Map<String, dynamic>> entries) =>
      Future.error(StateError("no Play services"));
}

/// The event as the Go bridge sends it: a scheme credential type, and an mdoc
/// and a VCDM credential the wallet holds.
const _eventJson = """
{
  "entries": [
    {
      "id": "dc+sd-jwt:pbdf.sidn-pbdf.email",
      "format": "dc+sd-jwt",
      "type": "pbdf.sidn-pbdf.email",
      "name": "Email address",
      "issuer_name": "SIDN",
      "logo_path": "/schemes/pbdf/sidn-pbdf/Issues/email/logo.png",
      "claims": [
        {"path": ["email"], "name": "Email"},
        {"path": ["domain"], "name": "Domain"}
      ]
    },
    {
      "id": "mso_mdoc:org.iso.18013.5.1.mDL",
      "format": "mso_mdoc",
      "type": "org.iso.18013.5.1.mDL",
      "name": "Driving licence",
      "issuer_name": "",
      "logo": {"base64": "bG9nbw==", "mime_type": "image/png"},
      "claims": [
        {"path": ["org.iso.18013.5.1", "family_name"], "name": "Family name"}
      ]
    },
    {
      "id": "vc+sd-jwt:https://example.com/credentials/Diploma",
      "format": "vc+sd-jwt",
      "type": "https://example.com/credentials/Diploma",
      "name": "Diploma",
      "issuer_name": "University",
      "claims": [
        {"path": ["credentialSubject", "degree"], "name": "Degree"}
      ]
    }
  ]
}
""";

DigitalCredentialsRegistryEvent _event([String json = _eventJson]) =>
    DigitalCredentialsRegistryEvent.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("Digital Credentials registry event", () {
    test("the entries are kept as the core sent them", () {
      final sent = jsonDecode(_eventJson) as Map<String, dynamic>;

      expect(_event().entries, sent["entries"]);
    });

    test("the entries are sent on to native as the core wrote them", () {
      // What `MethodChannelDigitalCredentialsRegistry` hands the registrar:
      // the same keys, in the same order, so an unchanged registry is the same
      // string and is not registered twice.
      expect(
        jsonEncode(_event().entries),
        jsonEncode((jsonDecode(_eventJson) as Map<String, dynamic>)["entries"]),
      );
    });

    test("an empty registry, which the core sends as null, is no entries", () {
      expect(_event('{"entries": null}').entries, isEmpty);
      expect(_event('{"entries": []}').entries, isEmpty);
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

    test("nothing is registered before the core says what", () async {
      final registry = _RecordingRegistry();
      await repository(registry);
      await pumpEventQueue();

      expect(registry.registrations, isEmpty);
    });

    test("the entries of the core are registered, in every format", () async {
      final registry = _RecordingRegistry();
      final repo = await repository(registry);

      repo.dispatch(_event());
      await pumpEventQueue();

      expect(registry.registrations, hasLength(1));
      expect(registry.registrations.single.map((entry) => entry["id"]), [
        "dc+sd-jwt:pbdf.sidn-pbdf.email",
        "mso_mdoc:org.iso.18013.5.1.mDL",
        "vc+sd-jwt:https://example.com/credentials/Diploma",
      ]);
    });

    test("what the core sends later replaces what was registered", () async {
      final registry = _RecordingRegistry();
      final repo = await repository(registry);

      repo.dispatch(_event());
      repo.dispatch(_event('{"entries": []}'));
      await pumpEventQueue();

      expect(registry.registrations, hasLength(2));
      expect(registry.registrations.last, isEmpty);
    });

    test("a registry that fails is reported and does not break the "
        "repository", () async {
      final reported = <Object>[];
      final onError = FlutterError.onError;
      FlutterError.onError = (details) => reported.add(details.exception);
      addTearDown(() => FlutterError.onError = onError);

      final repo = await repository(_FailingRegistry());
      repo.dispatch(_event());
      await pumpEventQueue();

      expect(reported, [isA<StateError>()]);
    });

    test("a build without a registry registers nothing", () async {
      final repo = await repository(null);

      repo.dispatch(_event());
      await pumpEventQueue();
    });
  });
}
