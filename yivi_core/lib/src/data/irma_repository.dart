import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_web_auth_2/flutter_web_auth_2.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:rxdart/rxdart.dart";
import "package:url_launcher/url_launcher.dart";

import "../models/applifecycle_changed_event.dart";
import "../models/authentication_events.dart";
import "../models/change_pin_events.dart";
import "../models/clear_all_data_event.dart";
import "../models/client_preferences.dart";
import "../models/credentials.dart";
import "../models/enrollment_events.dart";
import "../models/enrollment_status.dart";
import "../models/error_event.dart";
import "../models/eudi_configuration.dart";
import "../models/event.dart";
import "../models/handle_url_event.dart";
import "../models/irma_configuration.dart";
import "../models/issue_wizard.dart";
import "../models/native_events.dart";
import "../models/schemaless/credential_store.dart";
import "../models/schemaless/schemaless_events.dart" as schemaless;
import "../models/schemaless/session_state.dart";
import "../models/schemaless/session_user_interaction.dart";
import "../models/session.dart";
import "../models/session_events.dart";
import "../models/translated_value.dart";
import "../models/version_information.dart";
import "../providers/email_issuance_provider.dart";
import "../providers/ocr_processor_provider.dart";
import "../providers/passport_issuer_provider.dart";
import "../providers/sms_issuance_provider.dart";
import "../sentry/sentry.dart";
import "../util/navigation.dart";
import "irma_bridge.dart";
import "irma_preferences.dart";
import "session_repository.dart";

class _CredentialObtainState {
  // Credential type IDs the user kicked off an in-app launch for (via
  // openIssueURL or authenticateOpenID4VCI), pending a session finish.
  // Used at finish time to decide whether to keep the user inside Yivi
  // or hand them off to clientReturnUrl / ArrowBack / send-to-background.
  final Set<String> inAppLaunchedCredentialTypes;

  _CredentialObtainState({
    this.inAppLaunchedCredentialTypes = const <String>{},
  });
}

class _ExternalBrowserCredtype {
  final String cred;
  final List<String> oses;

  const _ExternalBrowserCredtype({required this.cred, required this.oses});
}

class IrmaRepository {
  IrmaRepository({
    required IrmaBridge client,
    required this.preferences,
    this.defaultKeyshareScheme = "pbdf",
  }) : _bridge = client {
    _credentialObtainState.add(_CredentialObtainState());
    _eventSubject.listen(_eventListener);
    _sessionRepository = SessionRepository(
      repo: this,
      eventStream: _eventSubject.stream,
    );
    _credentialsSubject.forEach((creds) async {
      final event = await _issueWizardSubject.first;
      if (event != null) {
        _issueWizardSubject.add(
          await processIssueWizard(
            event.wizardData.id,
            event.wizardContents,
            creds,
          ),
        );
      }
    });
    // Listen for bridge events and send them to our event subject.
    _bridgeEventSubscription = _bridge.events.listen(
      (event) => _eventSubject.add(event),
    );
    bridgedDispatch(AppReadyEvent());
  }

  final IrmaPreferences preferences;
  final String defaultKeyshareScheme;

  final IrmaBridge _bridge;
  final _eventSubject = PublishSubject<Event>();

  // SessionRepository depends on a IrmaRepository instance, so therefore it must be late final.
  late final SessionRepository _sessionRepository;

  // Try to pipe events from the _eventSubject, otherwise you have to explicitly close the subject in close().
  final _irmaConfigurationSubject = BehaviorSubject<IrmaConfiguration>();
  final _eudiConfigurationSubject = BehaviorSubject<EudiConfiguration>();
  final _credentialsSubject = BehaviorSubject<Credentials>();
  final _schemalessCredentialsSubject =
      BehaviorSubject<List<schemaless.Credential>>();
  final _credentialStoreSubject = BehaviorSubject<List<CredentialStoreItem>>();

  final _enrollmentStatusEventSubject =
      BehaviorSubject<EnrollmentStatusEvent>();
  final _enrollmentStatusSubject = BehaviorSubject<EnrollmentStatus>.seeded(
    .undetermined,
  );
  final _enrollmentEventSubject = PublishSubject<EnrollmentEvent>();
  final _authenticationEventSubject = PublishSubject<AuthenticationEvent>();
  final _changePinEventSubject = PublishSubject<ChangePinBaseEvent>();
  final _lockedSubject = BehaviorSubject<bool>.seeded(true);
  final _blockedSubject = BehaviorSubject<DateTime?>();
  final _pendingPointerSubject = BehaviorSubject<Pointer?>.seeded(null);
  final _preferencesSubject = BehaviorSubject<ClientPreferencesEvent>();
  final _credentialObtainState = BehaviorSubject<_CredentialObtainState>();
  final _resumedWithURLSubject = BehaviorSubject<bool>.seeded(false);
  final _resumedFromBrowserSubject = BehaviorSubject<bool>.seeded(false);
  final _issueWizardSubject = BehaviorSubject<IssueWizardEvent?>.seeded(null);
  final _issueWizardActiveSubject = BehaviorSubject<bool>.seeded(false);
  final _fatalErrorSubject = BehaviorSubject<ErrorEvent>();

  late StreamSubscription<Event> _bridgeEventSubscription;

  Future<void> close() async {
    // First we have to cancel the bridge event subscription
    await _bridgeEventSubscription.cancel();

    // Then we can close all internal subjects
    await Future.wait([
      _eventSubject.close(),
      _irmaConfigurationSubject.close(),
      _eudiConfigurationSubject.close(),
      _credentialsSubject.close(),
      _schemalessCredentialsSubject.close(),
      _credentialStoreSubject.close(),
      _enrollmentStatusEventSubject.close(),
      _enrollmentStatusSubject.close(),
      _enrollmentEventSubject.close(),
      _authenticationEventSubject.close(),
      _changePinEventSubject.close(),
      _lockedSubject.close(),
      _blockedSubject.close(),
      _pendingPointerSubject.close(),
      _preferencesSubject.close(),
      _credentialObtainState.close(),
      _resumedWithURLSubject.close(),
      _resumedFromBrowserSubject.close(),
      _issueWizardSubject.close(),
      _issueWizardActiveSubject.close(),
      _sessionRepository.close(),
      _fatalErrorSubject.close(),
    ]);
  }

  Future<void> _eventListener(Event event) async {
    if (event is ErrorEvent) {
      if (event.fatal) {
        _fatalErrorSubject.add(event);
        _lockedSubject.add(false);
      } else {
        // Only fatal errors on start-up are caught at the moment, so we have to report other errors manually.
        reportError(event.exception, event.stack);
      }
    } else if (event is IrmaConfigurationEvent) {
      _irmaConfigurationSubject.add(event.irmaConfiguration);
    } else if (event is EudiConfigurationEvent) {
      _eudiConfigurationSubject.add(event.eudiConfiguration);
    } else if (event is schemaless.SchemalessCredentialsEvent) {
      _schemalessCredentialsSubject.add(event.credentials);
    } else if (event is SchemalessCredentialStoreEvent) {
      _credentialStoreSubject.add(event.credentials);
    } else if (event is AuthenticationEvent) {
      _authenticationEventSubject.add(event);
      if (event is AuthenticationSuccessEvent) {
        _lockedSubject.add(false);
        _blockedSubject.add(null);
      }
    } else if (event is ChangePinBaseEvent) {
      _changePinEventSubject.add(event);
    } else if (event is EnrollmentStatusEvent) {
      _enrollmentStatusEventSubject.add(event);
      if (event.unenrolledSchemeManagerIds.contains(defaultKeyshareScheme)) {
        _lockedSubject.add(false);
      } else if (!event.enrolledSchemeManagerIds.contains(
        defaultKeyshareScheme,
      )) {
        dispatch(
          ErrorEvent(
            exception:
                "Expected default keyshare scheme $defaultKeyshareScheme could not be found in configuration",
            stack: "",
            fatal: true,
          ),
        );
      }
    } else if (event is EnrollmentEvent) {
      _enrollmentEventSubject.add(event);
    } else if (event is HandleURLEvent) {
      try {
        if (event.url.startsWith("app.yivi.open://auth-callback") ||
            event.url.startsWith("https://open.yivi.app/-/auth-callback")) {
          await handleOpenID4VCIAuthCallback(event.url);
          return;
        }

        final pointer = Pointer.fromString(event.url);
        _pendingPointerSubject.add(pointer);
        _resumedWithURLSubject.add(true);
        closeInAppWebView();
      } on MissingPointer catch (e, stackTrace) {
        reportError(e, stackTrace);
      }
    } else if (event is NewSessionEvent) {
      _pendingPointerSubject.add(null);
    } else if (event is ClearAllDataEvent) {
      _credentialsSubject.add(Credentials({}));
      _enrollmentStatusSubject.add(EnrollmentStatus.unenrolled);
      _lockedSubject.add(false);
      _blockedSubject.add(null);
      preferences.clearAll();
    } else if (event is AppLifecycleChangedEvent) {
      if (event.state == AppLifecycleState.paused) {
        _resumedWithURLSubject.add(false);
      }
    } else if (event is ClientPreferencesEvent) {
      _preferencesSubject.add(event);
    }
  }

  Stream<Event> getEvents() {
    return _eventSubject.stream;
  }

  void dispatch(Event event) {
    _eventSubject.add(event);
  }

  void bridgedDispatch(Event event) {
    dispatch(event);
    _bridge.dispatch(event);
  }

  void removeInAppLaunched(Iterable<String> credentialTypeIds) {
    final state = _credentialObtainState.value;
    final updated = state.inAppLaunchedCredentialTypes
        .where((credTypeId) => !credentialTypeIds.contains(credTypeId))
        .toSet();

    _credentialObtainState.add(
      _CredentialObtainState(inAppLaunchedCredentialTypes: updated),
    );
  }

  void markInAppLaunched(Iterable<String> credentialTypeIds) {
    final current = _credentialObtainState.value.inAppLaunchedCredentialTypes;
    _credentialObtainState.add(
      _CredentialObtainState(
        inAppLaunchedCredentialTypes: {...current, ...credentialTypeIds},
      ),
    );
  }

  void clearInAppLaunches() {
    _credentialObtainState.add(_CredentialObtainState());
  }

  /// True when [session] is an issuance session that issued at least one
  /// credential the user launched in-app (via [openIssueURL] or
  /// [authenticateOpenID4VCI]). Used to keep in-app launches inside Yivi
  /// on finish instead of chasing `clientReturnUrl` or falling through
  /// to ArrowBack / send-to-background.
  ///
  /// Checks both [SessionState.offeredCredentialTypes] (populated for
  /// OpenID4VCI sessions before the issuance instances exist) and
  /// [SessionState.offeredCredentials] (populated for classic IRMA
  /// sessions, with the actual issued credentials).
  bool didIssueInAppLaunchedCredential(SessionState session) {
    if (session.type != SessionType.issuance) return false;
    final launched = _credentialObtainState.value.inAppLaunchedCredentialTypes;
    if (launched.isEmpty) return false;
    final fromTypes = session.offeredCredentialTypes?.any(
      (c) => launched.contains(c.credentialId),
    );
    if (fromTypes == true) return true;
    final fromCredentials = session.offeredCredentials?.any(
      (c) => launched.contains(c.credentialId),
    );
    return fromCredentials == true;
  }

  // -- Scheme manager, cert manager, issuer, credential and attribute definitions
  IrmaConfiguration get irmaConfiguration => _irmaConfigurationSubject.value;
  EudiConfiguration get eudiConfiguration => _eudiConfigurationSubject.value;

  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return _irmaConfigurationSubject.stream;
  }

  Stream<EudiConfiguration> getEudiConfiguration() {
    return _eudiConfigurationSubject.stream;
  }

  Stream<Map<String, Issuer>> getIssuers() {
    return _irmaConfigurationSubject.stream.map<Map<String, Issuer>>(
      (config) => config.issuers,
    );
  }

  // -- Credential instances
  Credentials get credentials => _credentialsSubject.hasValue
      ? _credentialsSubject.value
      : Credentials({});

  Stream<Credentials> getCredentials() {
    return _credentialsSubject.stream;
  }

  Stream<List<schemaless.Credential>> getSchemalessCredentials() {
    return _schemalessCredentialsSubject.stream;
  }

  Stream<List<CredentialStoreItem>> getCredentialStoreItems() {
    return _credentialStoreSubject.stream;
  }

  // -- Enrollment
  Future<EnrollmentEvent> enroll({
    required String email,
    required String pin,
    required String language,
  }) {
    _lockedSubject.add(false);
    _blockedSubject.add(null);

    bridgedDispatch(
      EnrollEvent(
        email: email,
        pin: pin,
        language: language,
        schemeId: defaultKeyshareScheme,
      ),
    );

    return _enrollmentEventSubject.where((event) {
      switch (event.runtimeType) {
        case const (EnrollmentSuccessEvent):
          preferences.setLongPin(pin.length != 5);
          return true;
        case const (EnrollmentFailureEvent):
          return true;
        default:
          return false;
      }
    }).first;
  }

  Stream<EnrollmentStatus> getEnrollmentStatus() async* {
    if (!_enrollmentStatusEventSubject.hasValue) {
      yield EnrollmentStatus.undetermined;
    }

    yield* _enrollmentStatusEventSubject.map((event) {
      if (event.enrolledSchemeManagerIds.contains(defaultKeyshareScheme)) {
        return EnrollmentStatus.enrolled;
      } else if (event.unenrolledSchemeManagerIds.contains(
        defaultKeyshareScheme,
      )) {
        return EnrollmentStatus.unenrolled;
      } else {
        return EnrollmentStatus.undetermined;
      }
    });
  }

  Stream<EnrollmentStatusEvent> getEnrollmentStatusEvent() =>
      _enrollmentStatusEventSubject.stream;

  // -- Authentication
  void lock({DateTime? unblockTime}) {
    // TODO: This should actually lock irmago up
    _lockedSubject.add(true);
    _blockedSubject.add(unblockTime);
  }

  void setDeveloperMode(bool enabled) {
    bridgedDispatch(
      ClientPreferencesEvent(
        clientPreferences: ClientPreferences(developerMode: enabled),
      ),
    );
  }

  Future<AuthenticationEvent> unlock(String pin) {
    bridgedDispatch(
      AuthenticateEvent(pin: pin, schemeId: defaultKeyshareScheme),
    );

    return _authenticationEventSubject.where((event) {
      switch (event.runtimeType) {
        case const (AuthenticationSuccessEvent):
          preferences.setLongPin(pin.length != 5);
          return true;
        case const (AuthenticationFailedEvent):
        case const (AuthenticationErrorEvent):
          return true;
        default:
          return false;
      }
    }).first;
  }

  Future<ChangePinBaseEvent> changePin(String oldPin, String newPin) {
    bridgedDispatch(ChangePinEvent(oldPin: oldPin, newPin: newPin));

    return _changePinEventSubject.where((event) {
      switch (event.runtimeType) {
        case const (ChangePinSuccessEvent):
          // Change pin length
          preferences.setLongPin(newPin.length != 5);
          return true;
        case const (ChangePinFailedEvent):
        case const (ChangePinErrorEvent):
          return true;
        default:
          return false;
      }
    }).first;
  }

  Stream<bool> getLocked() {
    return _lockedSubject.distinct().asBroadcastStream();
  }

  Stream<DateTime?> getBlockTime() {
    return _blockedSubject;
  }

  // -- Version information
  Stream<VersionInformation> getVersionInformation() async* {
    final packageInfo = await PackageInfo.fromPlatform();

    yield* _irmaConfigurationSubject
        .map((irmaConfiguration) {
          int minimumBuild = 0;
          for (final scheme in irmaConfiguration.schemeManagers.values) {
            int thisRequirement = 0;
            switch (Platform.operatingSystem) {
              case "android":
                thisRequirement = scheme.minimumAppVersion.android;
                break;
              case "ios":
                thisRequirement = scheme.minimumAppVersion.iOS;
                break;
              default:
                throw Exception("Unsupported Platform.operatingSystem");
            }
            if (thisRequirement > minimumBuild) {
              minimumBuild = thisRequirement;
            }
          }

          final currentBuild =
              int.tryParse(packageInfo.buildNumber) ?? minimumBuild;

          return VersionInformation(
            availableVersion: minimumBuild,
            requiredVersion: minimumBuild,
            currentVersion: currentBuild,
          );
        })
        // When a fatal error occurs, no new IrmaConfiguration will be found anymore. This means we can close the stream.
        .takeUntil(_fatalErrorSubject);
  }

  // -- Sessions
  Stream<SessionState> getSessionState(int sessionId) {
    return _sessionRepository.getSessionState(sessionId);
  }

  /// Whether [sessionId] has a user interaction dispatched to Go that's still
  /// waiting on a response state event. Cleared automatically when the next
  /// state arrives.
  Stream<bool> isSessionAwaitingInteraction(int sessionId) {
    return _sessionRepository.isAwaitingInteraction(sessionId);
  }

  /// Synchronous companion to [isSessionAwaitingInteraction]. Useful in the
  /// first build of a freshly-mounted screen, before the stream provider has
  /// delivered its seed value.
  bool isSessionAwaitingInteractionNow(int sessionId) {
    return _sessionRepository.isAwaitingInteractionNow(sessionId);
  }

  SessionState? getCurrentSessionStateByOpenID4VCIState(String sessionState) {
    return _sessionRepository.getCurrentSessionStateByOpenID4VCIState(
      sessionState,
    );
  }

  /// Stream that emits session IDs when a new session is first seen.
  Stream<int> getNewSessionIds() {
    return _sessionRepository.newSessionIds;
  }

  // Resets to 0 on Flutter hot-restart while Go still holds prior ids.
  // `sessionManager.NewSession` evicts the old entry but its goroutines may
  // linger until they observe the eviction. Dev-only nuisance, not a
  // production concern (production app starts from a clean Go state too).
  int _nextSessionId = 0;

  /// Allocates a session id for an outgoing [NewSessionEvent]. Dart owns id
  /// allocation so [SessionScreen] can be pushed synchronously, before Go has
  /// emitted the first session state.
  int allocateSessionId() => ++_nextSessionId;

  bool hasActiveSessions({int? excludeSessionId}) {
    return _sessionRepository.hasActiveSessions(
      excludeSessionId: excludeSessionId,
    );
  }

  /// Dismisses all sessions that are currently in the requestPermission state.
  void dismissAllActiveSessions() {
    final activeSessionIds = _sessionRepository.getActiveSessionIds();
    for (final sessionId in activeSessionIds) {
      bridgedDispatch(
        SessionUserInteractionEvent.dismiss(sessionId: sessionId),
      );
    }
  }

  // Returns a future whether the app was resumed by either
  // 1) coming back from the browser, or
  // 2) handling an incoming URL
  Future<bool> appResumedAutomatically() {
    return Rx.combineLatest2(
      _resumedFromBrowserSubject.stream,
      _resumedWithURLSubject.stream,
      (bool a, bool b) => a || b,
    ).first.then((result) {
      _resumedFromBrowserSubject.add(
        false,
      ); // App is resumed, so we have to reset the value
      return result;
    });
  }

  Stream<Pointer?> getPendingPointer() {
    return _pendingPointerSubject.stream;
  }

  Stream<bool> getDeveloperMode() {
    return _preferencesSubject.stream.map(
      (pref) => pref.clientPreferences.developerMode,
    );
  }

  BehaviorSubject<IssueWizardEvent?> getIssueWizard() {
    return _issueWizardSubject;
  }

  BehaviorSubject<bool> getIssueWizardActive() {
    return _issueWizardActiveSubject;
  }

  Future<IssueWizardEvent> processIssueWizard(
    String id,
    List<IssueWizardItem> contents,
    Credentials credentials,
  ) async {
    final conf = await _irmaConfigurationSubject.first;
    if (!conf.issueWizards.containsKey(id)) {
      throw UnsupportedError("Wizard id $id could not been found");
    }
    final wizardData = conf.issueWizards[id]!;
    final creds = Set.from(credentials.values.map((cred) => cred.info.fullId));
    return IssueWizardEvent(
      haveCredential:
          wizardData.issues != null && creds.contains(wizardData.issues),
      wizardData: wizardData,
      wizardContents: contents.map((item) {
        // The credential field may be non-nil for any wizard item type
        final haveCredential =
            item.credential != null && creds.contains(item.credential);
        if (item.type != "credential") {
          return item.copyWith(completed: haveCredential || item.completed);
        }
        // irmago does not allow wizard items with non-existing credentials, so we can safely ignore null values here.
        final credtype = conf.credentialTypes[item.credential]!;
        return item.copyWith(
          completed: haveCredential,
          header: item.header.isNotEmpty ? item.header : credtype.name,
          text: item.text.isNotEmpty ? item.text : credtype.faqSummary,
        );
      }).toList(),
    );
  }

  // https://api.flutter.dev/flutter/dart-io/Platform/operatingSystem.html
  static const List<String> allOperatingSystems = [
    "android",
    "fuchsia",
    "ios",
    "linux",
    "macos",
    "windows",
  ];

  final List<_ExternalBrowserCredtype> _externalBrowserCredtypes = const [
    _ExternalBrowserCredtype(cred: "pbdf.gemeente.address", oses: ["ios"]),
    _ExternalBrowserCredtype(cred: "pbdf.gemeente.personalData", oses: ["ios"]),
    _ExternalBrowserCredtype(cred: "pbdf.pbdf.idin", oses: ["android"]),
    _ExternalBrowserCredtype(
      cred: "pbdf.PubHubs.account",
      oses: allOperatingSystems,
    ),
    _ExternalBrowserCredtype(
      cred: "irma-demo.PubHubs.account",
      oses: allOperatingSystems,
    ),
  ];

  // TODO Remove when disclosure sessions can be started from custom tabs
  Stream<List<String>> getExternalBrowserURLs() {
    return _irmaConfigurationSubject.map(
      (irmaConfiguration) => _externalBrowserCredtypes
          .where((type) => type.oses.contains(Platform.operatingSystem))
          .map(
            (type) =>
                irmaConfiguration.credentialTypes[type.cred]?.issueUrl.values ??
                [],
          )
          .expand((v) => v)
          .toList(),
    );
  }

  Stream<ErrorEvent> getFatalErrors() {
    return _fatalErrorSubject.stream;
  }

  static const _iiabchannel = MethodChannel("irma.app/iiab");

  Future<Set<String>> getInAppLaunchedCredentialTypes() {
    return _credentialObtainState.first.then(
      (state) => state.inAppLaunchedCredentialTypes,
    );
  }

  // Passport issuance is a special case where we use the scanner built into the app as the issuer
  void _startPassportIssuance(BuildContext context, String url, WidgetRef ref) {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);

      final baseUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      );

      // Set the url to use for the issuance session to the issuer url in the scheme
      ref.read(passportIssuerUrlProvider.notifier).set(baseUri.toString());

      if (ref.read(ocrProcessorProvider) != null) {
        context.pushPassportMrzReaderScreen();
      } else {
        context.pushPassportManualEntryScreen();
      }
    }
  }

  void _startIdCardIssuance(BuildContext context, String url, WidgetRef ref) {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);

      final baseUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      );

      // Set the url to use for the issuance session to the issuer url in the scheme
      ref.read(passportIssuerUrlProvider.notifier).set(baseUri.toString());

      if (ref.read(ocrProcessorProvider) != null) {
        context.pushIdCardMrzReaderScreen();
      } else {
        context.pushIdCardManualEntryScreen();
      }
    }
  }

  void _startDrivingLicenceIssuance(
    BuildContext context,
    String url,
    WidgetRef ref,
  ) {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);

      final baseUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      );

      // Set the url to use for the issuance session to the issuer url in the scheme
      ref.read(passportIssuerUrlProvider.notifier).set(baseUri.toString());

      if (ref.read(ocrProcessorProvider) != null) {
        context.pushDrivingLicenceMrzReaderScreen();
      } else {
        context.pushDrivingLicenceManualEntryScreen();
      }
    }
  }

  void _startMobileNumberIssuance(
    BuildContext context,
    String url,
    WidgetRef ref,
  ) {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);

      final baseUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      );

      // Set the url to use for the issuance session to the issuer url in the scheme
      ref.read(smsIssuerUrlProvider.notifier).set(baseUri.toString());

      context.pushSmsIssuanceScreen();
    }
  }

  void _startEmailIssuance(BuildContext context, String url, WidgetRef ref) {
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);

      final baseUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
      );

      // Set the url to use for the issuance session to the issuer url in the scheme
      ref.read(emailIssuerUrlProvider.notifier).set(baseUri.toString());

      context.pushEmailIssuanceScreen();
    }
  }

  /// Unified entry point for "user tapped Get / Reobtain inside the app
  /// and we need to take them to the issuer to obtain a credential".
  ///
  /// Called from add-data details, credential details (reobtain), the
  /// credential card's reobtain button, and the issue wizard.
  ///
  /// Behaviour:
  /// - For known embedded scheme credentials (pbdf/pbdf-staging passport,
  ///   drivinglicence, idcard, mobilenumber, email), dispatch to the
  ///   in-app embedded flow and return — without marking the credential
  ///   as launched (the embedded flows don't go out to a browser and
  ///   back, so the finish-time pop-to-success logic doesn't apply).
  /// - Otherwise, mark the credential as launched in-app (so the
  ///   resulting issuance session's finish lands on
  ///   `IssuanceSuccessScreen` instead of `clientReturnUrl` / ArrowBack /
  ///   send-to-background) and open the URL. Universal-link credential
  ///   types go through `openURLExternally` so the OS can dispatch the
  ///   link to a registered native app (UZI register, Belastingdienst);
  ///   everything else goes through `openURL` (in-app browser, falling
  ///   back to external for opted-in URLs).
  Future<void> openIssueURL(
    BuildContext context,
    String credentialId,
    TranslatedValue? issueURL,
    WidgetRef ref,
  ) async {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final url = issueURL?.translate(lang);
    if (url == null || url.isEmpty) {
      throw UnsupportedError(
        "Credential type $credentialId does not have a suitable issue url for $lang",
      );
    }

    final embeddedFlows = {
      //----------- production
      "pbdf.pbdf.passport": _startPassportIssuance,
      "pbdf.pbdf.drivinglicence": _startDrivingLicenceIssuance,
      "pbdf.pbdf.idcard": _startIdCardIssuance,
      "pbdf.sidn-pbdf.mobilenumber": _startMobileNumberIssuance,
      "pbdf.sidn-pbdf.email": _startEmailIssuance,
      //----------- staging
      "pbdf-staging.pbdf.passport": _startPassportIssuance,
      "pbdf-staging.pbdf.drivinglicence": _startDrivingLicenceIssuance,
      "pbdf-staging.pbdf.idcard": _startIdCardIssuance,
      "pbdf-staging.sidn-pbdf.mobilenumber": _startMobileNumberIssuance,
      "pbdf-staging.sidn-pbdf.email": _startEmailIssuance,
    };
    final flow = embeddedFlows[credentialId];
    if (flow != null) {
      return flow(context, url, ref);
    }

    markInAppLaunched([credentialId]);

    // TODO: surface `isULIssueUrl` on the schemaless credential models
    // (CredentialDescriptor / Credential) so we can drop the legacy
    // `_irmaConfigurationSubject` lookup here. Today there's no other
    // place that information lives on the wallet side. Affected
    // credentials (none overlap with the embedded flows above):
    //   pbdf.minvws-cibg.pilot-2, pbdf.bzkpilot.personalData/.address,
    //   plus several irma-demo demo creds (digidproef.*, uzipoc-cibg.*).
    // Schemaless credentials that aren't in legacy irmaConfiguration are
    // treated as non-universal-link.
    final cred = _irmaConfigurationSubject.valueOrNull
        ?.credentialTypes[credentialId];
    if (cred?.isULIssueUrl ?? false) {
      return openURLExternally(url, suppressQrScanner: true);
    }

    return openURL(url);
  }

  Future<void> openURL(String url) async {
    if ((await getExternalBrowserURLs().first).contains(url)) {
      return openURLExternally(url, suppressQrScanner: true);
    } else {
      return openURLinAppBrowser(url);
    }
  }

  Future<void> openURLinAppBrowser(String url) async {
    _resumedFromBrowserSubject.add(true);
    if (Platform.isAndroid) {
      await _iiabchannel.invokeMethod("open_browser", url);
    } else {
      final uri = Uri.parse(url);
      final hasOpened = await launchUrl(uri, mode: .inAppWebView);

      // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
      if (!hasOpened) {
        throw Exception("url could not be opened: $url");
      }
    }
  }

  Future<void> openURLExternally(
    String url, {
    bool suppressQrScanner = false,
  }) async {
    if (suppressQrScanner) {
      _resumedFromBrowserSubject.add(true);
    }
    // On iOS, open Safari rather than Safari view controller
    final uri = Uri.parse(url);
    final hasOpened = await launchUrl(uri, mode: .externalApplication);

    // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
    if (!hasOpened) {
      throw Exception("url could not be opened: $url");
    }
  }

  /// Drive an OpenID4VCI authorization-code flow through an
  /// `ASWebAuthenticationSession` (iOS) / Chrome Custom Tab + activity callback
  /// (Android). The OAuth `redirect_uri` is the universal link
  /// `https://open.yivi.app/-/auth-callback` (set in irmago). A bounce page
  /// at that URL JS-redirects to `app.yivi.open://auth-callback?...`, which
  /// the auth session intercepts via `callbackUrlScheme`. The resulting URL
  /// is then handed off to [handleOpenID4VCIAuthCallback].
  Future<void> authenticateOpenID4VCI(
    String authorizationRequestUrl,
    Iterable<String> credentialIds,
  ) async {
    _resumedFromBrowserSubject.add(true);
    markInAppLaunched(credentialIds);
    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: authorizationRequestUrl,
        callbackUrlScheme: "app.yivi.open",
      );
    } on PlatformException catch (e) {
      // User dismissed the browser sheet. The session stays in
      // `requestAuthorizationCode`; the pending screen lets them retry or
      // dismiss. Anything else (e.g. the browser couldn't open) bubbles up.
      if (e.code == "CANCELED") return;
      rethrow;
    }
    await handleOpenID4VCIAuthCallback(result);
  }

  Future<void> handleOpenID4VCIAuthCallback(String url) async {
    // We only parse `state` here, used to route the callback to the right
    // session. The library parses the rest of the URL on the Go side —
    // including the OAuth error case (`?state=X&error=access_denied`), which
    // has no `code` — so we forward the URL even when it carries a failure.
    final uri = Uri.parse(url);
    final state = uri.queryParameters["state"];
    if (state == null) {
      throw MissingPointer(
        details:
            'expected "state" to be present in query parameters, but wasn\'t',
      );
    }

    final session = _sessionRepository.getCurrentSessionStateByOpenID4VCIState(
      state,
    );
    if (session == null) {
      throw MissingPointer(
        details: 'No session found for state value "$state"',
      );
    }

    bridgedDispatch(
      SessionUserInteractionEvent.authCallback(
        sessionId: session.id,
        callbackUrl: url,
        proceed: true,
      ),
    );
  }

  void startTestSessionFromUrl(String url) {
    final sessionPtr = Pointer.fromString(url) as SessionPointer;
    sessionPtr.continueOnSecondDevice = true;
    _pendingPointerSubject.add(sessionPtr);
  }

  /// Only meant for testing and debug purposes.
  Future<void> startTestSession(
    String requestBody, {
    continueOnSecondDevice = true,
  }) async {
    final sessionPtr = await createTestSession(
      requestBody,
      continueOnSecondDevice: continueOnSecondDevice,
    );
    _pendingPointerSubject.add(sessionPtr);
  }

  /// Only meant for testing and debug purposes.
  Future<void> startTestIssueWizard(String wizardKey) async {
    final issueWizardPointer = IssueWizardPointer(wizardKey);
    _pendingPointerSubject.add(issueWizardPointer);
  }
}

Future<SessionPointer> createTestSession(
  String requestBody, {
  bool continueOnSecondDevice = true,
}) async {
  final Uri uri = Uri.parse("https://is.demo.staging.yivi.app/session");

  final request = await HttpClient().postUrl(uri);
  request.headers.set("Content-Type", "application/json");
  request.write(requestBody);

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).first;

  if (response.statusCode != 200) {
    throw "Status ${response.statusCode}: $responseBody";
  }

  final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
  final sessionPtr = SessionPointer.fromJson(
    responseObject["sessionPtr"] as Map<String, dynamic>,
  );

  sessionPtr.continueOnSecondDevice = continueOnSecondDevice;
  return sessionPtr;
}
