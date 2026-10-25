import "package:flutter/widgets.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart" show DocumentType;

import "../models/log_entry.dart";
import "../models/mrz.dart";
import "../models/translated_value.dart";
import "../providers/email_issuance_provider.dart";
import "../providers/ocr_processor_provider.dart";

/// The path segment of each document in the document routes
/// (`/mrz/reader/id_card`, `/nfc/passport`, …).
const documentPaths = {
  DocumentType.passport: "passport",
  DocumentType.identityCard: "id_card",
  DocumentType.drivingLicence: "driving_licence",
};

extension RoutingHelpers on BuildContext {
  void pushErrorScreen({required String message}) {
    push("/error", extra: message);
  }

  void pushReplacementErrorScreen({required String message}) {
    pushReplacement("/error", extra: message);
  }

  Future<bool?> pushModalPin() async {
    return await push("/modal_pin");
  }

  void pushResetPinScreen() {
    push("/reset_pin");
  }

  void pushSmsIssuanceScreen() {
    push("/issue_mobilenumber");
  }

  void pushEmailIssuanceScreen({
    EmailIssuancePurpose purpose = EmailIssuancePurpose.addCredential,
  }) {
    push("/issue_email", extra: purpose);
  }

  void popToWizardScreen() {
    Navigator.of(this).popUntil(ModalRoute.withName("/issue_wizard"));
  }

  /// Pops back to the nearest session screen below the current one.
  ///
  /// Treats the first route as a floor, so it can never empty the navigator.
  /// Callers decide there is an underlying session from repository state
  /// (`hasActiveSessions`), which can disagree with the actual stack — a stale
  /// session left in `requestPermission` is enough. Without the floor, that
  /// mismatch pops every page and trips go_router's "you have popped the last
  /// page off of the stack" assertion, which corrupts the widget tree for good.
  /// Landing on the first route instead matches what
  /// [popToUnderlyingSessionOrHome] would have done without an underlying
  /// session.
  void popToUnderlyingSession() {
    final navigator = Navigator.of(this);
    // We have to at least do one pop in case the current screen is already a
    // session — unless it is the only screen left.
    if (!navigator.canPop()) return;
    navigator.pop();
    navigator.popUntil((route) {
      if (route.isFirst) return true;
      final name = route.settings.name;
      // GoRouter sets the route name to the full URI (including query params),
      // so we match on the path prefix rather than an exact name.
      return name != null && name.startsWith("/session");
    });
  }

  void popToUnderlyingSessionOrHome({required bool hasUnderlyingSession}) {
    if (hasUnderlyingSession) {
      popToUnderlyingSession();
    } else {
      goHomeScreen();
    }
  }

  void goHomeScreenWithoutTransition() {
    TransitionStyleProvider.performInstantTransitionToHomeScreen(this);
  }

  void goHomeScreen() {
    go("/home");
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

  void pushFeatureFlagsScreen() {
    push("/home/debug/feature_flags");
  }

  void goNotificationsScreen() {
    go("/home/notifications");
  }

  void goEnrollmentScreen() {
    go("/enrollment");
  }

  void pushBackToWebsiteScreen() {
    push("/back_to_website");
  }

  void goIssueWizardSuccessScreen({
    TranslatedValue? headerTranslation,
    TranslatedValue? contentTranslation,
  }) {
    go("/issue_wizard_success", extra: (headerTranslation, contentTranslation));
  }

  void pushLanguageSettingsScreen() {
    push("/home/settings/change_language");
  }

  void pushChangePinScreen() {
    push("/change_pin");
  }

  void pushActivityDetailsScreen({required LogInfo logInfo}) {
    push("/home/activity_details", extra: logInfo);
  }

  /// Opens the full-screen detail view of one card (credential instance).
  /// Call [WalletTransition.begin] first when it opens from a card on screen.
  /// [found]: the field (a claim path key) a search found the card by; the
  /// card opens on it.
  void pushCredentialDetailScreen(String hash, {String? found}) {
    final uri = Uri(
      path: "/home/credential",
      queryParameters: {"hash": hash, "found": ?found},
    );
    push(uri.toString());
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

  void pushDocumentInstructionScreen(DocumentType documentType) {
    final uri = Uri(path: "/mrz/instructions/${documentType.name}");
    push(uri.toString());
  }

  /// Opens the MRZ camera, or manual entry when the build has no
  /// [ocrProcessor].
  void pushDocumentCapture(
    DocumentType documentType, {
    required OcrProcessor? ocrProcessor,
  }) {
    final screen = ocrProcessor != null ? "reader" : "manual_entry";
    push("/mrz/$screen/${documentPaths[documentType]}");
  }

  void pushDocumentManualEntry(DocumentType documentType) {
    push("/mrz/manual_entry/${documentPaths[documentType]}");
  }

  /// The chip reading of [documentType] with [queryParameters] (what the MRZ
  /// says), unless it is already the current page.
  void _pushNfcReadingScreen(
    DocumentType documentType,
    Map<String, String> queryParameters,
  ) {
    final uri = Uri(
      path: "/nfc/${documentPaths[documentType]}",
      queryParameters: queryParameters,
    ).toString();

    final current = GoRouter.of(this).state.uri.toString();

    if (current != uri) {
      push(uri);
    }
  }

  /// Opens the chip reading for what the camera or the manual entry read.
  void pushNfcReadingScreenFor(ScannedMrz mrz) {
    final countryCode = mrz.countryCode.isEmpty ? null : mrz.countryCode;
    switch (mrz) {
      case ScannedPassportMrz():
        _pushNfcReadingScreen(
          .passport,
          PassportNfcReadingRouteParams(
            documentNumber: mrz.documentNumber,
            dateOfBirth: mrz.dateOfBirth,
            dateOfExpiry: mrz.dateOfExpiry,
            countryCode: countryCode,
          ).toQueryParams(),
        );
      case ScannedIdCardMrz():
        _pushNfcReadingScreen(
          .identityCard,
          PassportNfcReadingRouteParams(
            documentNumber: mrz.documentNumber,
            dateOfBirth: mrz.dateOfBirth,
            dateOfExpiry: mrz.dateOfExpiry,
            countryCode: countryCode,
          ).toQueryParams(),
        );
      case ScannedDrivingLicenceMrz():
        _pushNfcReadingScreen(
          .drivingLicence,
          DrivingLicenceNfcReadingRouteParams(
            documentNumber: mrz.documentNumber,
            version: mrz.version,
            randomData: mrz.randomData,
            configuration: mrz.configuration,
            countryCode: mrz.countryCode,
          ).toQueryParams(),
        );
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
  final String credentialTypeId;

  CredentialsDetailsRouteParams({required this.credentialTypeId});

  Map<String, String> toQueryParams() {
    return {"credential_type_id": credentialTypeId};
  }

  static CredentialsDetailsRouteParams fromQueryParams(
    Map<String, String> params,
  ) {
    return CredentialsDetailsRouteParams(
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
      "country_code": ?countryCode,
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
  final int sessionId;
  final bool hasUnderlyingSession;

  SessionRouteParams({
    required this.sessionId,
    this.hasUnderlyingSession = false,
  });

  Map<String, String> toQueryParams() {
    return {
      "session_id": "$sessionId",
      if (hasUnderlyingSession) "has_underlying_session": "true",
    };
  }

  static SessionRouteParams fromQueryParams(Map<String, String> params) {
    return SessionRouteParams(
      sessionId: int.parse(params["session_id"]!),
      hasUnderlyingSession: params["has_underlying_session"] == "true",
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
    // Without the provider (e.g. in a test) home opens as usual.
    state?._shouldPerformInstantTransitionToHomeScreen = true;
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
