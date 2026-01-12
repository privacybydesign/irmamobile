import "dart:async";
import "dart:convert";

import "package:flutter/services.dart";

import "../models/session.dart";
import "../models/session_events.dart";
import "../models/session_state.dart";
import "../sentry/sentry.dart";
import "irma_repository.dart";

/// Handles Digital Credentials API requests from browsers via Android Credential Manager.
/// This enables web pages to request credentials via navigator.identity.get() API.
class DigitalCredentialsHandler {
  static const MethodChannel _channel = MethodChannel(
    "irma.app/digital_credentials",
  );

  final IrmaRepository _repository;
  StreamSubscription<SessionState>? _sessionSubscription;
  int? _currentSessionId;

  DigitalCredentialsHandler(this._repository) {
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case "handleDigitalCredentialRequest":
          return await _handleCredentialRequest(call.arguments as String);
        default:
          throw PlatformException(
            code: "METHOD_NOT_IMPLEMENTED",
            message: "Method ${call.method} not implemented",
          );
      }
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _returnError("Error handling ${call.method}: $e");
      return null;
    }
  }

  Future<void> _handleCredentialRequest(String requestJson) async {
    try {
      final requestData = jsonDecode(requestJson) as Map<String, dynamic>;
      final url = requestData["url"] as String;
      // Future use: track calling app for security/audit
      // final callingPackage = requestData["callingPackage"] as String?;
      // final callingOrigin = requestData["callingOrigin"] as String?;

      // Parse the URL into a SessionPointer
      final pointer = Pointer.fromString(url);

      if (pointer is! SessionPointer) {
        _returnError("Invalid OpenID4VP URL: not a session pointer");
        return;
      }

      if (pointer.protocol != "openid4vp") {
        _returnError("Unsupported protocol: ${pointer.protocol}");
        return;
      }

      // Create the NewSessionEvent with ReturnMode enabled for Digital Credentials API
      // This tells irmago to return the vp_token instead of POSTing it
      final event = NewSessionEvent(
        request: pointer,
        previouslyLaunchedCredentials: {},
        returnMode: true, // Enable return mode for Digital Credentials API
      );

      // Store the sessionID for tracking
      _currentSessionId = event.sessionID;

      // Start the OpenID4VP session using the existing repository
      // The session will follow the normal disclosure flow
      _repository.dispatch(event);

      // Listen for session state changes for this specific session
      _sessionSubscription = _repository.sessionRepository
          .getSessionState(event.sessionID)
          .listen(
            (sessionState) {
              _handleSessionStateChange(sessionState);
            },
            onError: (error, stackTrace) {
              reportError(error, stackTrace);
              _returnError("Session error: $error");
            },
          );
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _returnError("Failed to process credential request: $e");
    }
  }

  void _handleSessionStateChange(SessionState sessionState) {
    // Handle different session states
    if (sessionState.status == SessionStatus.success) {
      // Session completed successfully - extract and return the response
      _handleSuccessfulSession(sessionState);
    } else if (sessionState.status == SessionStatus.canceled) {
      // User canceled the session
      _cancelRequest();
    } else if (sessionState.status == SessionStatus.error) {
      // Session ended with an error
      _returnError(sessionState.error?.toString() ?? "Unknown session error");
    }
  }

  void _handleSuccessfulSession(SessionState sessionState) {
    try {
      // The vp_token response is now available in sessionState.vpTokenResponse
      // This is provided by irmago when ReturnMode is enabled

      // Extract the vp_token from the session result
      // With ReturnMode enabled, irmago returns the vp_token via the Success handler
      // instead of POSTing it to the response_uri
      final vpTokenResponse = sessionState.vpTokenResponse;

      if (vpTokenResponse == null || vpTokenResponse.isEmpty) {
        _returnError("Session completed but vp_token response not available");
        return;
      }

      // The vpTokenResponse already contains the formatted JSON response from irmago
      // It includes: protocol, state, vp_token/response, and response_mode
      // We just pass it through to Chrome via the Digital Credentials API
      _returnCredential(vpTokenResponse);
    } catch (e, stackTrace) {
      reportError(e, stackTrace);
      _returnError("Failed to process session result: $e");
    }
  }

  void _returnCredential(String responseJson) {
    _channel
        .invokeMethod("returnCredential", {"responseJson": responseJson})
        .catchError((error) {
          reportError(error, StackTrace.current);
        });
    _cleanup();
  }

  void _returnError(String message) {
    _channel.invokeMethod("returnError", {"message": message}).catchError((
      error,
    ) {
      reportError(error, StackTrace.current);
    });
    _cleanup();
  }

  void _cancelRequest() {
    _channel.invokeMethod("cancelRequest").catchError((error) {
      reportError(error, StackTrace.current);
    });
    _cleanup();
  }

  void _cleanup() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    _currentSessionId = null;
  }

  void dispose() {
    _cleanup();
  }
}
