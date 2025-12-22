import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:go_router/go_router.dart";

import "../models/irma_configuration.dart";
import "../models/log_entry.dart";
import "../models/protocol.dart";
import "../models/translated_value.dart";

extension RoutingHelpers on BuildContext {
  void pushScannerScreen({required bool requireAuthBeforeSession}) {
    final uri = Uri(
      path: "/scanner",
      queryParameters: {
        "require_auth_before_session": requireAuthBeforeSession.toString(),
      },
    );
    push(uri.toString());
  }

  void pushErrorScreen({required String message}) {
    push("/error", extra: message);
  }

  void pushReplacementErrorScreen({required String message}) {
    pushReplacement("/error", extra: message);
  }

  Future<bool?> pushModalPin() async {
    return await push("/modal_pin");
  }

  bool isScannerTopRoute() {
    return GoRouter.of(this).state.uri.path == "/scanner";
  }

  void pushAddDataScreen() {
    push("/home/add_data");
  }

  void pushResetPinScreen() {
    push("/reset_pin");
  }

  void popToWizardScreen() {
    Navigator.of(this).popUntil(ModalRoute.withName("/issue_wizard"));
  }

  void popToUnderlyingSession() {
    // we have to at least do one pop in case the current screen is already a session
    Navigator.of(this).pop();
    Navigator.of(this).popUntil(ModalRoute.withName("/session"));
  }

  void goHomeScreenWithoutTransition() {
    TransitionStyleProvider.performInstantTransitionToHomeScreen(this);
  }

  void goHomeScreen() {
    go("/home");
  }

  void goPinScreen() {
    go("/pin");
  }

  void goSettingsScreen() {
    go("/home/settings");
  }

  void goHelpScreen() {
    go("/home/help");
  }

  void goDebugScreen() {
    go("/home/debug");
  }

  void goNotificationsScreen() {
    go("/home/notifications");
  }

  void goEnrollmentScreen() {
    go("/enrollment");
  }

  void goIssueWizardSuccessScreen({
    TranslatedValue? headerTranslation,
    TranslatedValue? contentTranslation,
  }) {
    go("/issue_wizard_success", extra: (headerTranslation, contentTranslation));
  }

  void pushDataDetailsScreen(CredentialType credentialType) {
    push("/home/add_data/details", extra: credentialType);
  }

  void pushLanguageSettingsScreen() {
    push("/home/settings/change_language");
  }

  void pushChangePinScreen() {
    push("/change_pin");
  }

  void pushActivityDetailsScreen({
    required LogInfo logInfo,
    required IrmaConfiguration config,
  }) {
    push("/home/activity_details", extra: (logInfo, config));
  }

  void pushCredentialsDetailsScreen(CredentialsDetailsRouteParams params) {
    final uri = Uri(
      path: "/home/credentials_details",
      queryParameters: params.toQueryParams(),
    );
    push(uri.toString());
  }

  void pushReplacementSessionScreen(SessionRouteParams args) {
    final uri = Uri(path: "/session", queryParameters: args.toQueryParams());
    pushReplacement(uri.toString());
  }

  void pushSessionScreen(SessionRouteParams args) {
    final uri = Uri(path: "/session", queryParameters: args.toQueryParams());
    push(uri.toString());
  }

  void pushReplacementUnknownSessionScreen(SessionRouteParams args) {
    final uri = Uri(
      path: "/unknown_session",
      queryParameters: args.toQueryParams(),
    );
    pushReplacement(uri.toString());
  }

  void pushUnknownSessionScreen(SessionRouteParams args) {
    final uri = Uri(
      path: "/unknown_session",
      queryParameters: args.toQueryParams(),
    );
    push(uri.toString());
  }

  void pushReplacementIssueWizardScreen(IssueWizardRouteParams params) {
    final uri = Uri(
      path: "/issue_wizard",
      queryParameters: params.toQueryParams(),
    );
    pushReplacement(uri.toString());
  }

  void pushPassportMrzReaderScreen() {
    final uri = Uri(path: "/mrz/reader/passport");
    push(uri.toString());
  }

  void pushIdCardMrzReaderScreen() {
    final uri = Uri(path: "/mrz/reader/id_card");
    push(uri.toString());
  }

  void pushDrivingLicenceMrzReaderScreen() {
    final uri = Uri(path: "/mrz/reader/driving_licence");
    push(uri.toString());
  }

  void pushPassportManualEntryScreen() {
    final uri = Uri(path: "/mrz/manual_entry/passport");
    push(uri.toString());
  }

  void pushIdCardManualEntryScreen() {
    final uri = Uri(path: "/mrz/manual_entry/id_card");
    push(uri.toString());
  }

  void pushDrivingLicenceManualEntryScreen() {
    final uri = Uri(path: "/mrz/manual_entry/driving_licence");
    push(uri.toString());
  }

  void pushPassportNfcReadingScreen(PassportNfcReadingRouteParams params) {
    final uri = Uri(
      path: "/nfc/passport",
      queryParameters: params.toQueryParams(),
    ).toString();

    final current = GoRouter.of(this).state.uri.toString();

    if (current != uri) {
      push(uri);
    }
  }

  void pushIdCardNfcReadingScreen(PassportNfcReadingRouteParams params) {
    final uri = Uri(
      path: "/nfc/id_card",
      queryParameters: params.toQueryParams(),
    ).toString();

    final current = GoRouter.of(this).state.uri.toString();

    if (current != uri) {
      push(uri);
    }
  }

  void pushDrivingLicenceNfcReadingScreen(
    DrivingLicenceNfcReadingRouteParams params,
  ) {
    final uri = Uri(
      path: "/nfc/driving_licence",
      queryParameters: params.toQueryParams(),
    ).toString();

    final current = GoRouter.of(this).state.uri.toString();

    if (current != uri) {
      push(uri);
    }
  }

  Future<void> pushIssueWizardScreen(IssueWizardRouteParams params) async {
    final uri = Uri(
      path: "/issue_wizard",
      queryParameters: params.toQueryParams(),
    );
    await push(uri.toString());
  }
}

// =============================================================================================

class CredentialsDetailsRouteParams {
  final String categoryName;
  final String credentialTypeId;

  CredentialsDetailsRouteParams({
    required this.categoryName,
    required this.credentialTypeId,
  });

  Map<String, String> toQueryParams() {
    return {
      "category_name": categoryName,
      "credential_type_id": credentialTypeId,
    };
  }

  static CredentialsDetailsRouteParams fromQueryParams(
    Map<String, String> params,
  ) {
    return CredentialsDetailsRouteParams(
      categoryName: params["category_name"]!,
      credentialTypeId: params["credential_type_id"]!,
    );
  }
}

// =============================================================================================

class IssueWizardRouteParams {
  final String wizardID;
  final int? sessionID;

  IssueWizardRouteParams({required this.wizardID, required this.sessionID});

  Map<String, String> toQueryParams() {
    return {
      "wizard_id": wizardID,
      if (sessionID != null) "session_id": "$sessionID",
    };
  }

  static IssueWizardRouteParams fromQueryParams(Map<String, String> params) {
    return IssueWizardRouteParams(
      wizardID: params["wizard_id"]!,
      sessionID: params.containsKey("session_id")
          ? int.parse(params["session_id"]!)
          : null,
    );
  }
}

// =============================================================================================

class DrivingLicenceNfcReadingRouteParams {
  final String documentNumber;
  final String countryCode;

  final String version;
  final String randomData;
  final String configuration;

  DrivingLicenceNfcReadingRouteParams({
    required this.documentNumber,
    required this.version,
    required this.randomData,
    required this.configuration,
    required this.countryCode,
  });

  Map<String, String> toQueryParams() {
    return {
      "document_number": documentNumber,
      "version": version,
      "random_data": randomData,
      "configuration": configuration,
      "country_code": countryCode,
    };
  }

  static DrivingLicenceNfcReadingRouteParams fromQueryParams(
    Map<String, String> params,
  ) {
    return DrivingLicenceNfcReadingRouteParams(
      documentNumber: params["document_number"]!,
      countryCode: params["country_code"]!,
      version: params["version"]!,
      randomData: params["random_data"]!,
      configuration: params["configuration"]!,
    );
  }
}

// =============================================================================================

class PassportNfcReadingRouteParams {
  final String documentNumber;
  final DateTime dateOfBirth;
  final DateTime dateOfExpiry;
  final String? countryCode;

  PassportNfcReadingRouteParams({
    required this.documentNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.countryCode,
  });

  Map<String, String> toQueryParams() {
    return {
      "document_number": documentNumber,
      "date_of_birth": dateOfBirth.toIso8601String(),
      "date_of_expiry": dateOfExpiry.toIso8601String(),
      if (countryCode != null) "country_code": countryCode!,
    };
  }

  static PassportNfcReadingRouteParams fromQueryParams(
    Map<String, String> params,
  ) {
    return PassportNfcReadingRouteParams(
      documentNumber: params["document_number"]!,
      dateOfBirth: DateTime.parse(params["date_of_birth"]!),
      dateOfExpiry: DateTime.parse(params["date_of_expiry"]!),
      countryCode: params["country_code"],
    );
  }
}

// =============================================================================================

class SessionRouteParams {
  final int sessionID;
  final Protocol protocol;
  final String sessionType;
  final bool hasUnderlyingSession;
  final bool wizardActive;
  final String? wizardCred;

  SessionRouteParams({
    required this.sessionID,
    required this.protocol,
    required this.sessionType,
    required this.hasUnderlyingSession,
    required this.wizardActive,
    this.wizardCred,
  });

  Map<String, String> toQueryParams() {
    return {
      "session_id": "$sessionID",
      "protocol": protocolToString(protocol),
      "session_type": sessionType,
      "has_underlying_session": "$hasUnderlyingSession",
      "wizard_active": "$wizardActive",
      if (wizardCred != null) "wizard_cred": "$wizardCred",
    };
  }

  static SessionRouteParams fromQueryParams(Map<String, String> params) {
    return SessionRouteParams(
      sessionID: int.parse(params["session_id"]!),
      protocol: stringToProtocol(params["protocol"]!),
      sessionType: params["session_type"]!,
      hasUnderlyingSession: bool.parse(params["has_underlying_session"]!),
      wizardActive: bool.parse(params["wizard_active"]!),
      wizardCred: params["wizard_cred"],
    );
  }
}

// =============================================================================================

/// The transition to the home page should be instant in some cases and
/// "normal" in other cases. For example coming from the pin screen should be an instant transition,
/// while coming back from the add_data page should be a native sliding transition.
/// This is a hard problem, as during page building in GoRouter there is no way to detect whether
/// you're coming from a subpage or not. Passing parameters together with the context.go() call also doesn't
/// work as it remembers the parameters passed to the initial transition, so coming back from a subpage still has the
/// parameters from coming from the pin screen.
/// The (kind of hacky, ugly) solution we made up for this is to set a flag when going to the home screen
/// and resetting it when the home screen is built. This way we only have the instant transition once and
/// normal transitions for all subsequent navigation actions.
class TransitionStyleProvider extends StatefulWidget {
  final Widget child;

  const TransitionStyleProvider({required this.child});

  static void performInstantTransitionToHomeScreen(BuildContext context) {
    var state = context.findAncestorStateOfType<TransitionStyleProviderState>();
    state!._shouldPerformInstantTransitionToHomeScreen = true;
    context.goHomeScreen();
  }

  static bool shouldPerformInstantTransitionToHome(BuildContext context) {
    final state = context
        .findAncestorStateOfType<TransitionStyleProviderState>();
    return state!._shouldPerformInstantTransitionToHomeScreen;
  }

  static void resetInstantTransitionToHomeMark(BuildContext context) {
    var state = context.findAncestorStateOfType<TransitionStyleProviderState>();
    state!._shouldPerformInstantTransitionToHomeScreen = false;
  }

  @override
  State<StatefulWidget> createState() {
    return TransitionStyleProviderState();
  }
}

class TransitionStyleProviderState extends State<TransitionStyleProvider> {
  bool _shouldPerformInstantTransitionToHomeScreen = false;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
