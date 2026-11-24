import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";

import "../models/authentication_events.dart";
import "../models/change_pin_events.dart";
import "../models/client_preferences.dart";
import "../models/credential.dart";
import "../models/credential_store.dart";
import "../models/enrollment_events.dart";
import "../models/error_event.dart";
import "../models/eudi_configuration.dart";
import "../models/event.dart";
import "../models/handle_url_event.dart";
import "../models/log_entry.dart";
import "../models/native_events.dart";
import "../models/scheme_rules.dart";
import "../models/session_preview.dart";
import "../models/session_state.dart";
import "../models/support_directory.dart";
import "../screens/debug/debug_schemes.dart";
import "../sentry/sentry.dart";
import "irma_bridge.dart";

typedef EventUnmarshaller = Event Function(Map<String, dynamic>);

class IrmaClientBridge extends IrmaBridge {
  final bool debugLogging;
  final MethodChannel _methodChannel;

  /// What Go and the native plugins send, by the name it has on the bridge
  /// channel. The names are fixed strings: they must not follow a renamed
  /// Dart class.
  static final Map<String, EventUnmarshaller> _eventUnmarshallers = {
    "SchemeRulesEvent": SchemeRulesEvent.fromJson,
    "DebugSchemesEvent": DebugSchemesEvent.fromJson,
    "SupportDirectoryEvent": SupportDirectoryEvent.fromJson,
    "EudiConfigurationEvent": EudiConfigurationEvent.fromJson,
    "CredentialsEvent": CredentialsEvent.fromJson,
    "CredentialStoreEvent": CredentialStoreEvent.fromJson,
    "SessionStateEvent": SessionStateEvent.fromJson,
    "SessionPreviewEvent": SessionPreviewEvent.fromJson,
    "EnrollmentStatusEvent": EnrollmentStatusEvent.fromJson,
    "LogPageEvent": LogPageEvent.fromJson,
    "PartiesEvent": PartiesEvent.fromJson,
    "LogCountsEvent": LogCountsEvent.fromJson,
    "HandleURLEvent": HandleURLEvent.fromJson,
    "AppReadyAckEvent": AppReadyAckEvent.fromJson,
    "EnrollmentSuccessEvent": EnrollmentSuccessEvent.fromJson,
    "EnrollmentFailureEvent": EnrollmentFailureEvent.fromJson,
    "AuthenticationSuccessEvent": AuthenticationSuccessEvent.fromJson,
    "AuthenticationFailedEvent": AuthenticationFailedEvent.fromJson,
    "AuthenticationErrorEvent": AuthenticationErrorEvent.fromJson,
    "ChangePinSuccessEvent": ChangePinSuccessEvent.fromJson,
    "ChangePinFailedEvent": ChangePinFailedEvent.fromJson,
    "ChangePinErrorEvent": ChangePinErrorEvent.fromJson,
    "ClientPreferencesEvent": ClientPreferencesEvent.fromJson,
    "ErrorEvent": ErrorEvent.fromJson,
  };

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
      final unmarshaller = _eventUnmarshallers[call.method];

      if (unmarshaller == null) {
        // Don't send 'call.arguments' to Sentry; it might contain personal data.
        reportError("Unrecognized bridge event received: ${call.method}", null);
        return;
      }

      if (debugLogging) {
        // These payloads are large (the credentials, a page of activity, the
        // schemes for the debug screens) and bloat the log, so only their
        // name is printed.
        const nonPrinting = {
          "DebugSchemesEvent",
          "CredentialsEvent",
          "CredentialStoreEvent",
          "LogPageEvent",
          "PartiesEvent",
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
  void dispatch(BridgeEvent event) {
    final encodedEvent = jsonEncode(event);
    if (debugLogging && kDebugMode) {
      printLongString("Sending ${event.wireName} to bridge: $encodedEvent");
    }

    _methodChannel.invokeMethod(event.wireName, encodedEvent);
  }
}
