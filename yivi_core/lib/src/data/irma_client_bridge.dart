import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

import "../models/authentication_events.dart";
import "../models/certificate_events.dart";
import "../models/change_pin_events.dart";
import "../models/clear_all_data_event.dart";
import "../models/client_preferences.dart";
import "../models/credential_events.dart";
import "../models/delete_keyshare_tokens_event.dart";
import "../models/enrollment_events.dart";
import "../models/error_event.dart";
import "../models/eudi_configuration.dart";
import "../models/event.dart";
import "../models/handle_url_event.dart";
import "../models/irma_configuration.dart";
import "../models/log_entry.dart";
import "../models/native_events.dart";
import "../models/refresh_credential_statuses_event.dart";
import "../models/schemaless/credential_store.dart";
import "../models/schemaless/schemaless_events.dart" as schemaless;
import "../models/schemaless/session_state.dart";
import "../models/schemaless/session_user_interaction.dart";
import "../models/scheme_events.dart";
import "../models/session_events.dart";
import "../models/update_schemes_event.dart";
import "../sentry/sentry.dart";
import "irma_bridge.dart";

typedef EventUnmarshaller = Event Function(Map<String, dynamic>);

class IrmaClientBridge extends IrmaBridge {
  final bool debugLogging;
  final MethodChannel _methodChannel;

  // The bridge protocol names an event by a string, which the native side and the Go
  // bridge switch on. Both tables below spell the names out instead of deriving them
  // from the Dart class names: a release build is obfuscated, which renames the
  // classes, so `runtimeType.toString()` no longer gives the name the other side
  // of the bridge expects.

  /// Events received from the native side or the Go bridge, by their name.
  static final Map<String, EventUnmarshaller> _eventUnmarshallerLookup = {
    "IrmaConfigurationEvent": (j) => IrmaConfigurationEvent.fromJson(j),
    "EudiConfigurationEvent": (j) => EudiConfigurationEvent.fromJson(j),
    "SchemalessCredentialsEvent": (j) =>
        schemaless.SchemalessCredentialsEvent.fromJson(j),
    "SchemalessCredentialStoreEvent": (j) =>
        SchemalessCredentialStoreEvent.fromJson(j),
    "SessionStateEvent": (j) => SessionStateEvent.fromJson(j),
    "EnrollmentStatusEvent": (j) => EnrollmentStatusEvent.fromJson(j),
    "LogsEvent": (j) => LogsEvent.fromJson(j),
    "HandleURLEvent": (j) => HandleURLEvent.fromJson(j),
    "AppReadyAckEvent": (j) => AppReadyAckEvent.fromJson(j),
    "EnrollmentSuccessEvent": (j) => EnrollmentSuccessEvent.fromJson(j),
    "EnrollmentFailureEvent": (j) => EnrollmentFailureEvent.fromJson(j),
    "AuthenticationSuccessEvent": (j) => AuthenticationSuccessEvent.fromJson(j),
    "AuthenticationFailedEvent": (j) => AuthenticationFailedEvent.fromJson(j),
    "AuthenticationErrorEvent": (j) => AuthenticationErrorEvent.fromJson(j),
    "ChangePinSuccessEvent": (j) => ChangePinSuccessEvent.fromJson(j),
    "ChangePinFailedEvent": (j) => ChangePinFailedEvent.fromJson(j),
    "ChangePinErrorEvent": (j) => ChangePinErrorEvent.fromJson(j),
    "ClientPreferencesEvent": (j) => ClientPreferencesEvent.fromJson(j),
    "ErrorEvent": (j) => ErrorEvent.fromJson(j),
  };

  /// Events sent to the native side and the Go bridge, with the name they are
  /// sent under (see `DispatchFromNative` in irmagobridge/receive_event.go).
  @visibleForTesting
  static const Map<Type, String> outboundEventNames = {
    AppReadyEvent: "AppReadyEvent",
    SetLocaleEvent: "SetLocaleEvent",
    AndroidSendToBackgroundEvent: "AndroidSendToBackgroundEvent",
    EnrollEvent: "EnrollEvent",
    AuthenticateEvent: "AuthenticateEvent",
    ChangePinEvent: "ChangePinEvent",
    NewSessionEvent: "NewSessionEvent",
    SessionUserInteractionEvent: "SessionUserInteractionEvent",
    ClearAllDataEvent: "ClearAllDataEvent",
    DeleteKeyshareTokensEvent: "DeleteKeyshareTokensEvent",
    DeleteCredentialEvent: "DeleteCredentialEvent",
    UpdateSchemesEvent: "UpdateSchemesEvent",
    RefreshCredentialStatusesEvent: "RefreshCredentialStatusesEvent",
    LoadLogsEvent: "LoadLogsEvent",
    ClientPreferencesEvent: "ClientPreferencesEvent",
    InstallSchemeEvent: "InstallSchemeEvent",
    RemoveSchemeEvent: "RemoveSchemeEvent",
    RemoveRequestorSchemeEvent: "RemoveRequestorSchemeEvent",
    InstallCertificateEvent: "InstallCertificateEvent",
    RemoveCertificateEvent: "RemoveCertificateEvent",
  };

  /// The names of the events the bridge can receive.
  @visibleForTesting
  static Iterable<String> get inboundEventNames =>
      _eventUnmarshallerLookup.keys;

  /// The name [event] is sent under. Throws for an event that is not listed in
  /// [outboundEventNames]: sending it under its obfuscated class name would be
  /// silently ignored by the Go bridge.
  @visibleForTesting
  static String outboundEventName(Event event) {
    final name = outboundEventNames[event.runtimeType];
    if (name == null) {
      throw StateError(
        "Event ${event.runtimeType} cannot be sent over the bridge: it has no "
        "name in IrmaClientBridge.outboundEventNames",
      );
    }
    return name;
  }

  IrmaClientBridge({this.debugLogging = false})
    : _methodChannel = const MethodChannel("irma.app/irma_mobile_bridge") {
    // Start listening to method calls from the native side
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  // Matches "base64" (logos) as well as "base64_image" (attribute values).
  static final _base64Pattern = RegExp(r'"(base64\w*)"\s*:\s*"[^"]*"');

  void printLongString(String text) {
    final sanitized = text.replaceAllMapped(
      _base64Pattern,
      (m) => '"${m[1]}": "<omitted>"',
    );
    final RegExp pattern = RegExp(".{1,800}"); // 800 is the size of each chunk
    pattern
        .allMatches(sanitized)
        .forEach((RegExpMatch match) => debugPrint(match.group(0)));
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == "GoLog") {
      if (kDebugMode) {
        printLongString("[GO]: ${call.arguments}");
      }
      return;
    }
    try {
      final data = jsonDecode(call.arguments as String) as Map<String, dynamic>;
      final unmarshaller = _eventUnmarshallerLookup[call.method];

      if (unmarshaller == null) {
        // Don't send 'call.arguments' to Sentry; it might contain personal data.
        reportError("Unrecognized bridge event received: ${call.method}", null);
        return;
      }

      if (debugLogging) {
        // the irma config event has so much data in its payload it bloats all logs,
        // therefore we explicitly don't print the payload
        const nonPrinting = {
          "IrmaConfigurationEvent",
          "SchemalessCredentialsEvent",
          "SchemalessCredentialStoreEvent",
          "LogsEvent",
        };
        if (nonPrinting.contains(call.method)) {
          if (kDebugMode) {
            printLongString(
              "Received bridge event: ${call.method} -- payload omitted",
            );
          }
        } else {
          if (kDebugMode) {
            printLongString(
              "Received bridge event: ${call.method} with payload ${call.arguments}",
            );
          }
        }
      }

      final Event event = unmarshaller(data);
      addEvent(event);
    } catch (e, stacktrace) {
      reportError(e, stacktrace);
    }

    return;
  }

  @override
  void dispatch(Event event) {
    final eventName = outboundEventName(event);
    final encodedEvent = jsonEncode(event);
    if (debugLogging && kDebugMode) {
      printLongString("Sending $eventName to bridge: $encodedEvent");
    }

    _methodChannel.invokeMethod(eventName, encodedEvent);
  }
}
