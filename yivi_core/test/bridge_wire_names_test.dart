// The names events have on the bridge channel. Go and the native plugins
// match on these strings, so they may not change when a Dart class is
// renamed or moved.
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart" show FlutterError;
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/data/irma_client_bridge.dart";
import "package:yivi_core/src/models/authentication_events.dart";
import "package:yivi_core/src/models/certificate_events.dart";
import "package:yivi_core/src/models/change_pin_events.dart";
import "package:yivi_core/src/models/clear_all_data_event.dart";
import "package:yivi_core/src/models/client_preferences.dart";
import "package:yivi_core/src/models/credential_events.dart";
import "package:yivi_core/src/models/delete_keyshare_tokens_event.dart";
import "package:yivi_core/src/models/enrollment_events.dart";
import "package:yivi_core/src/models/error_event.dart";
import "package:yivi_core/src/models/event.dart";
import "package:yivi_core/src/models/handle_url_event.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/native_events.dart";
import "package:yivi_core/src/models/refresh_credential_statuses_event.dart";
import "package:yivi_core/src/models/scheme_events.dart";
import "package:yivi_core/src/models/session.dart";
import "package:yivi_core/src/models/session_events.dart";
import "package:yivi_core/src/models/session_preview.dart";
import "package:yivi_core/src/models/session_user_interaction.dart";
import "package:yivi_core/src/models/support_directory.dart";
import "package:yivi_core/src/models/update_schemes_event.dart";
import "package:yivi_core/src/screens/debug/debug_schemes.dart";

const _channel = MethodChannel("irma.app/irma_mobile_bridge");

/// What the app sends, by the method name it has on the channel today.
final _outgoing = <String, BridgeEvent Function()>{
  "AppReadyEvent": () => AppReadyEvent(locale: "en"),
  "SetLocaleEvent": () => SetLocaleEvent(locale: "nl"),
  "EnrollEvent": () =>
      EnrollEvent(email: "", pin: "12345", language: "en", schemeId: "pbdf"),
  "AuthenticateEvent": () => AuthenticateEvent(pin: "12345", schemeId: "pbdf"),
  "ChangePinEvent": () => ChangePinEvent(oldPin: "12345", newPin: "54321"),
  "NewSessionEvent": () => NewSessionEvent(sessionId: 1, request: _pointer()),
  "PreviewSessionEvent": () =>
      PreviewSessionEvent(key: "k", request: _pointer()),
  "SessionUserInteractionEvent": () =>
      SessionUserInteractionEvent.dismiss(sessionId: 1),
  "ClearAllDataEvent": ClearAllDataEvent.new,
  "DeleteKeyshareTokensEvent": DeleteKeyshareTokensEvent.new,
  "DeleteCredentialEvent": () =>
      DeleteCredentialEvent(hashByFormat: {CredentialFormat.idemix: "h"}),
  "UpdateSchemesEvent": UpdateSchemesEvent.new,
  "RefreshCredentialStatusesEvent": RefreshCredentialStatusesEvent.new,
  "QueryLogsEvent": () => QueryLogsEvent("r", const LogQuery()),
  "CountLogsEvent": () => CountLogsEvent("r", const [LogFilter()]),
  "ListPartiesEvent": () => ListPartiesEvent("r", const LogFilter()),
  "ClientPreferencesEvent": () => ClientPreferencesEvent(
    clientPreferences: ClientPreferences(developerMode: true),
  ),
  "InstallSchemeEvent": () => InstallSchemeEvent(url: "u", publicKey: "k"),
  "RemoveSchemeEvent": () => RemoveSchemeEvent(schemeId: "s"),
  "RemoveRequestorSchemeEvent": () => RemoveRequestorSchemeEvent(schemeId: "s"),
  "RequestDebugSchemesEvent": RequestDebugSchemesEvent.new,
  "RequestSupportDirectoryEvent": RequestSupportDirectoryEvent.new,
  "InstallCertificateEvent": () =>
      InstallCertificateEvent(type: "ca", pemContent: "pem"),
  "RemoveCertificateEvent": () =>
      RemoveCertificateEvent(type: "ca", thumbprint: "t"),
  // Handled by the Android plugin, not by Go.
  "AndroidSendToBackgroundEvent": AndroidSendToBackgroundEvent.new,
};

/// What Go and the native plugins send, by the method name they use.
const _incoming = [
  "SchemeRulesEvent",
  "DebugSchemesEvent",
  "SupportDirectoryEvent",
  "EudiConfigurationEvent",
  "CredentialsEvent",
  "CredentialStoreEvent",
  "SessionStateEvent",
  "SessionPreviewEvent",
  "EnrollmentStatusEvent",
  "LogPageEvent",
  "PartiesEvent",
  "LogCountsEvent",
  "HandleURLEvent",
  "AppReadyAckEvent",
  "EnrollmentSuccessEvent",
  "EnrollmentFailureEvent",
  "AuthenticationSuccessEvent",
  "AuthenticationFailedEvent",
  "AuthenticationErrorEvent",
  "ChangePinSuccessEvent",
  "ChangePinFailedEvent",
  "ChangePinErrorEvent",
  "ClientPreferencesEvent",
  "ErrorEvent",
];

SessionPointer _pointer() =>
    Pointer.fromString(
          '{"u":"https://example.com/irma/session/abc","irmaqr":"disclosing"}',
        )
        as SessionPointer;

/// The event names Go's bridge handles (`case "…":` in receive_event.go).
Set<String> _goCases() {
  final source = File("irmagobridge/receive_event.go").readAsStringSync();
  return RegExp(
    r'case "(\w+)":',
  ).allMatches(source).map((m) => m.group(1)!).toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late IrmaClientBridge bridge;
  late List<Event> received;
  late List<Object> reported;

  setUp(() {
    bridge = IrmaClientBridge();
    received = [];
    bridge.events.listen(received.add);
    reported = [];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => reported.add(details.exception);
    addTearDown(() => FlutterError.onError = previous);
  });
  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  /// Sends a method call to the app as Go or the native plugin would.
  Future<void> send(String method, String payload) async {
    await messenger.handlePlatformMessage(
      _channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, payload)),
      (_) {},
    );
    await pumpEventQueue();
  }

  group("29. outgoing", () {
    test("each event goes out under its wire name, as JSON", () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(_channel, (call) async {
        calls.add(call);
        return null;
      });

      for (final make in _outgoing.values) {
        bridge.dispatch(make());
      }
      await pumpEventQueue();

      expect(calls.map((c) => c.method), _outgoing.keys);
      for (final call in calls) {
        expect(
          jsonDecode(call.arguments as String),
          isA<Map<String, dynamic>>(),
        );
      }
      for (final entry in _outgoing.entries) {
        expect(entry.value().wireName, entry.key);
        // The names are those of the Dart classes, as before they were
        // fixed strings.
        expect(entry.value().runtimeType.toString(), entry.key);
      }
    });

    test("Go handles every name the app sends, and no other", () {
      final sentToGo = _outgoing.keys.toSet()
        ..remove("AndroidSendToBackgroundEvent");
      expect(_goCases(), sentToGo);
    });
  });

  group("30. incoming", () {
    for (final name in _incoming) {
      test("$name is recognised", () async {
        // An empty payload: parsing may fail, but on the payload, not on
        // the name.
        await send(name, "{}");

        expect(
          reported.map((e) => "$e"),
          isNot(contains(startsWith("Unrecognized bridge event"))),
        );
        if (received.isNotEmpty) {
          expect(received.single.runtimeType.toString(), name);
        } else {
          expect(reported, isNotEmpty);
        }
      });
    }

    test("an unknown name is reported and dropped", () async {
      await send("NoSuchEvent", "{}");

      expect(received, isEmpty);
      expect("${reported.single}", contains("NoSuchEvent"));
    });

    test("what the native plugins send, with their payloads", () async {
      await send("HandleURLEvent", '{"url": "https://open.yivi.app/-/x"}');
      await send("AppReadyAckEvent", "{}");
      await send(
        "ErrorEvent",
        '{"exception": "e", "stack": "s", "fatal": true}',
      );

      expect(reported, isEmpty);
      expect(received, [
        isA<HandleURLEvent>().having(
          (e) => e.url,
          "url",
          "https://open.yivi.app/-/x",
        ),
        isA<AppReadyAckEvent>(),
        isA<ErrorEvent>().having((e) => e.fatal, "fatal", isTrue),
      ]);
    });

    test("an answer to a log question arrives as its event", () async {
      await send("LogCountsEvent", '{"request_id": "r", "counts": [3]}');

      expect(received.single, isA<LogCountsEvent>());
    });
  });
}
