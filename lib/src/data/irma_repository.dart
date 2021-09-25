// This code is not null safe yet.
// @dart=2.11

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/data/irma_bridge.dart';
import 'package:irmamobile/src/data/irma_preferences.dart';
import 'package:irmamobile/src/data/session_repository.dart';
import 'package:irmamobile/src/models/applifecycle_changed_event.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/models/change_pin_events.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/models/client_preferences.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/error_event.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/handle_url_event.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/sentry/sentry.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:package_info/package_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class _InAppCredentialState {
  final int pendingInactivations;
  final String credentialType;

  _InAppCredentialState({
    this.pendingInactivations,
    this.credentialType,
  });

  _InAppCredentialState copyWith({
    int pendingInactivations,
    String credentialType,
  }) {
    return _InAppCredentialState(
      pendingInactivations: pendingInactivations ?? this.pendingInactivations,
      credentialType: credentialType ?? this.credentialType,
    );
  }
}

class ExternalBrowserCredtype {
  final String cred;
  final String os;

  const ExternalBrowserCredtype({this.cred, this.os});
}

class IrmaRepository {
  static IrmaRepository _instance;
  factory IrmaRepository({@required IrmaBridge client, @required IrmaPreferences preferences}) {
    _instance = IrmaRepository._internal(client, preferences);
    _instance.dispatch(AppReadyEvent(), isBridgedEvent: true);

    return _instance;
  }

  @Deprecated('Use IrmaRepositoryProvider.of(context) instead')
  static IrmaRepository get() {
    if (_instance == null) {
      throw Exception('IrmaRepository has not been initialized');
    }
    return _instance;
  }

  final IrmaPreferences preferences;

  final IrmaBridge _bridge;
  final _eventSubject = PublishSubject<Event>();

  SessionRepository _sessionRepository;

  // Try to pipe events from the _eventSubject, otherwise you have to explicitly close the subject in close().
  final _irmaConfigurationSubject = BehaviorSubject<IrmaConfiguration>();
  final _credentialsSubject = BehaviorSubject<Credentials>();
  final _enrollmentStatusSubject = BehaviorSubject<EnrollmentStatus>.seeded(EnrollmentStatus.undetermined);
  final _enrollmentEventSubject = PublishSubject<EnrollmentEvent>();
  final _authenticationEventSubject = PublishSubject<AuthenticationEvent>();
  final _changePinEventSubject = PublishSubject<ChangePinBaseEvent>();
  final _lockedSubject = BehaviorSubject<bool>.seeded(true);
  final _blockedSubject = BehaviorSubject<DateTime>();
  final _lastActiveTimeSubject = BehaviorSubject<DateTime>();
  final _pendingSessionPointerSubject = BehaviorSubject<SessionPointer>.seeded(null);
  final _preferencesSubject = BehaviorSubject<ClientPreferencesEvent>();
  final _inAppCredentialSubject = BehaviorSubject<_InAppCredentialState>();
  final _resumedWithURLSubject = BehaviorSubject<bool>.seeded(false);
  final _resumedFromBrowserSubject = BehaviorSubject<bool>.seeded(false);
  final _issueWizardSubject = BehaviorSubject<IssueWizardEvent>.seeded(null);
  final _issueWizardActiveSubject = BehaviorSubject<bool>.seeded(false);
  final _fatalErrorSubject = BehaviorSubject<ErrorEvent>();

  StreamSubscription<Event> _bridgeEventSubscription;

  IrmaConfiguration get irmaConfiguration => _irmaConfigurationSubject.value;

  // _internal is a named constructor only used by the factory
  IrmaRepository._internal(
    this._bridge,
    this.preferences,
  ) : assert(_bridge != null) {
    _inAppCredentialSubject.add(_InAppCredentialState());
    _eventSubject.listen(_eventListener);
    _sessionRepository = SessionRepository(
      repo: this,
      sessionEventStream: _eventSubject.where((event) => event is SessionEvent).cast<SessionEvent>(),
    );
    _credentialsSubject.forEach((creds) async {
      final event = await _issueWizardSubject.first;
      if (event != null) {
        _issueWizardSubject.add(await processIssueWizard(event.wizardData.id, event.wizardContents, creds));
      }
    });
    // Listen for bridge events and send them to our event subject.
    _bridgeEventSubscription = _bridge.events.listen((event) => _eventSubject.add(event));
  }

  Future<void> close() async {
    // First we have to cancel the bridge event subscription
    await _bridgeEventSubscription.cancel();

    // Then we can close all internal subjects
    await Future.wait([
      _eventSubject.close(),
      _irmaConfigurationSubject.close(),
      _credentialsSubject.close(),
      _enrollmentStatusSubject.close(),
      _enrollmentEventSubject.close(),
      _authenticationEventSubject.close(),
      _changePinEventSubject.close(),
      _lockedSubject.close(),
      _blockedSubject.close(),
      _lastActiveTimeSubject.close(),
      _pendingSessionPointerSubject.close(),
      _preferencesSubject.close(),
      _inAppCredentialSubject.close(),
      _resumedWithURLSubject.close(),
      _resumedFromBrowserSubject.close(),
      _issueWizardSubject.close(),
      _issueWizardActiveSubject.close(),
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
    } else if (event is CredentialsEvent) {
      _credentialsSubject.add(Credentials.fromRaw(
        irmaConfiguration: await _irmaConfigurationSubject.first,
        rawCredentials: event.credentials,
      ));
    } else if (event is AuthenticationEvent) {
      _authenticationEventSubject.add(event);
      if (event is AuthenticationSuccessEvent) {
        _lockedSubject.add(false);
        _blockedSubject.add(null);
      }
    } else if (event is ChangePinBaseEvent) {
      _changePinEventSubject.add(event);
    } else if (event is EnrollmentStatusEvent) {
      _enrollmentStatusSubject.add(event.enrollmentStatus);
      if (event.enrollmentStatus == EnrollmentStatus.unenrolled) {
        _lockedSubject.add(false);
      }
    } else if (event is EnrollmentEvent) {
      _enrollmentEventSubject.add(event);
    } else if (event is HandleURLEvent) {
      try {
        final sessionPointer = SessionPointer.fromString(event.url);
        _pendingSessionPointerSubject.add(sessionPointer);
        _resumedWithURLSubject.add(true);
        closeWebView();
      } on MissingSessionPointer {
        // pass
      }
    } else if (event is NewSessionEvent) {
      _pendingSessionPointerSubject.add(null);
    } else if (event is ClearAllDataEvent) {
      _credentialsSubject.add(Credentials({}));
      _enrollmentStatusSubject.add(EnrollmentStatus.unenrolled);
      _lockedSubject.add(false);
      _blockedSubject.add(null);
      preferences.clearAll();
    } else if (event is AppLifecycleChangedEvent) {
      if (event.state == AppLifecycleState.paused) {
        _lastActiveTimeSubject.add(DateTime.now());
        _resumedWithURLSubject.add(false);
      }
    } else if (event is ClientPreferencesEvent) {
      _preferencesSubject.add(event);
    } else if (event is IssueWizardContentsEvent) {
      _issueWizardSubject.add(await processIssueWizard(
        event.id,
        event.wizardContents,
        await _credentialsSubject.first,
      ));
    }
  }

  Stream<Event> getEvents() {
    return _eventSubject.stream;
  }

  void dispatch(Event event, {bool isBridgedEvent = false}) {
    _eventSubject.add(event);

    if (isBridgedEvent) {
      _bridge.dispatch(event);
    }
  }

  void bridgedDispatch(Event event) {
    dispatch(event, isBridgedEvent: true);
  }

  // -- Scheme manager, issuer, credential and attribute definitions
  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return _irmaConfigurationSubject.stream;
  }

  Stream<Map<String, Issuer>> getIssuers() {
    return _irmaConfigurationSubject.stream.map<Map<String, Issuer>>(
      (config) => config.issuers,
    );
  }

  // -- Credential instances
  Stream<Credentials> getCredentials() {
    return _credentialsSubject.stream;
  }

  // -- Enrollment
  Future<EnrollmentEvent> enroll({String email, String pin, String language}) {
    _lockedSubject.add(false);
    _blockedSubject.add(null);

    dispatch(EnrollEvent(email: email, pin: pin, language: language), isBridgedEvent: true);

    return _enrollmentEventSubject.where((event) {
      switch (event.runtimeType) {
        case EnrollmentSuccessEvent:
          preferences.setLongPin(pin.length != 5);
          return true;
          break;
        case EnrollmentFailureEvent:
          return true;
          break;
        default:
          return false;
      }
    }).first;
  }

  Stream<EnrollmentStatus> getEnrollmentStatus() {
    return _enrollmentStatusSubject.stream;
  }

  // -- Authentication
  void lock({DateTime unblockTime}) {
    // TODO: This should actually lock irmago up
    _lockedSubject.add(true);
    _blockedSubject.add(unblockTime);
  }

  void setDeveloperMode(bool enabled) {
    bridgedDispatch(ClientPreferencesEvent(clientPreferences: ClientPreferences(developerMode: enabled)));
  }

  Future<AuthenticationEvent> unlock(String pin) {
    dispatch(AuthenticateEvent(pin: pin), isBridgedEvent: true);

    return _authenticationEventSubject.where((event) {
      switch (event.runtimeType) {
        case AuthenticationSuccessEvent:
          preferences.setLongPin(pin.length != 5);
          return true;
          break;
        case AuthenticationFailedEvent:
        case AuthenticationErrorEvent:
          return true;
          break;
        default:
          return false;
      }
    }).first;
  }

  Future<ChangePinBaseEvent> changePin(String oldPin, String newPin) {
    dispatch(ChangePinEvent(oldPin: oldPin, newPin: newPin), isBridgedEvent: true);

    return _changePinEventSubject.where((event) {
      switch (event.runtimeType) {
        case ChangePinSuccessEvent:
          // Change pin length
          preferences.setLongPin(newPin.length != 5);
          return true;
          break;
        case ChangePinFailedEvent:
        case ChangePinErrorEvent:
          return true;
          break;
        default:
          return false;
      }
    }).first;
  }

  Stream<bool> getLocked() {
    return _lockedSubject.distinct().asBroadcastStream();
  }

  Stream<DateTime> getBlockTime() {
    return _blockedSubject;
  }

  // -- Version information
  Stream<VersionInformation> getVersionInformation() {
    // Get two Streams before waiting on them to allow for asynchronicity.
    final packageInfoStream = PackageInfo.fromPlatform().asStream();
    final irmaVersionInfoStream = _irmaConfigurationSubject.stream; // TODO: add filtering

    return Rx.combineLatest2(packageInfoStream, irmaVersionInfoStream,
            (PackageInfo packageInfo, IrmaConfiguration irmaVersionInfo) {
      int minimumBuild = 0;
      irmaVersionInfo.schemeManagers.forEach((_, scheme) {
        int thisRequirement = 0;
        switch (Platform.operatingSystem) {
          case "android":
            thisRequirement = scheme.minimumAppVersion.android ?? 0;
            break;
          case "ios":
            thisRequirement = scheme.minimumAppVersion.iOS ?? 0;
            break;
          default:
            throw Exception("Unsupported Platfrom.operatingSystem");
        }
        if (thisRequirement > minimumBuild) {
          minimumBuild = thisRequirement;
        }
      });

      int currentBuild = int.tryParse(packageInfo.buildNumber) ?? minimumBuild;

      if (Platform.operatingSystem == "android") {
        while (currentBuild > 1024 * 1024) {
          currentBuild -= 1024 * 1024;
        }
      }
      return VersionInformation(
        availableVersion: minimumBuild,
        requiredVersion: minimumBuild,
        currentVersion: currentBuild,
      );
    })
        // When a fatal error occurs, no new IrmaConfiguration will be found anymore. This means we can close the stream.
        .takeUntil(_fatalErrorSubject);
  }

  // -- Session
  Stream<SessionState> getSessionState(int sessionID) {
    return _sessionRepository.getSessionState(sessionID);
  }

  Future<bool> hasActiveSessions() {
    return _sessionRepository.hasActiveSessions();
  }

  // Returns a future whether the app was resumed by either
  // 1) coming back from the browser, or
  // 2) handling an incoming URL
  Future<bool> appResumedAutomatically() {
    return Rx.combineLatest2(
            _resumedFromBrowserSubject.stream, _resumedWithURLSubject.stream, (bool a, bool b) => a || b)
        .first
        .then((result) {
      _resumedFromBrowserSubject.add(false); // App is resumed, so we have to reset the value
      return result;
    });
  }

  Stream<SessionPointer> getPendingSessionPointer() {
    return _pendingSessionPointerSubject.stream;
  }

  // -- lastActiveTime
  Stream<DateTime> getLastActiveTime() {
    return _lastActiveTimeSubject.stream;
  }

  Stream<bool> getDeveloperMode() {
    return _preferencesSubject.stream.map((pref) => pref.clientPreferences.developerMode);
  }

  BehaviorSubject<IssueWizardEvent> getIssueWizard() {
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
    final wizardData = conf.issueWizards[id];
    final creds = Set.from(credentials.values.map((cred) => cred.info.fullId));
    return IssueWizardEvent(
      haveCredential: wizardData.issues != null && creds.contains(wizardData.issues),
      wizardData: wizardData,
      wizardContents: contents.map((item) {
        // The credential field may be non-nil for any wizard item type
        final haveCredential = item.credential != null && creds.contains(item.credential);
        if (item.type != 'credential') {
          return item.copyWith(completed: haveCredential || (item.completed ?? false));
        }
        final credtype = conf.credentialTypes[item.credential];
        return item.copyWith(
          completed: haveCredential,
          header: item.header.isNotEmpty ? item.header : credtype.name,
          text: item.text.isNotEmpty ? item.text : credtype.faqSummary,
        );
      }).toList(),
    );
  }

  final List<ExternalBrowserCredtype> externalBrowserCredtypes = const [
    ExternalBrowserCredtype(cred: "pbdf.gemeente.address", os: "ios"),
    ExternalBrowserCredtype(cred: "pbdf.gemeente.personalData", os: "ios"),
  ];

  final List<String> externalBrowserUrls = const [
    "https://privacybydesign.foundation/myirma/",
    "https://privacybydesign.foundation/mijnirma/",
    "https://privacybydesign.foundation/demo/",
    "https://privacybydesign.foundation/demo-en/"
  ];

  // TODO Remove when disclosure sessions can be started from custom tabs
  Stream<List<String>> getExternalBrowserURLs() {
    return _irmaConfigurationSubject.map(
      (irmaConfiguration) => externalBrowserCredtypes
          .where((type) => type.os == null || type.os == Platform.operatingSystem)
          .map((type) => irmaConfiguration.credentialTypes[type.cred].issueUrl.values)
          .expand((v) => v)
          .toList()
        ..addAll(externalBrowserUrls),
    );
  }

  Stream<ErrorEvent> getFatalErrors() {
    return _fatalErrorSubject.stream;
  }

  static const _iiabchannel = MethodChannel('irma.app/iiab');

  Future<String> getInAppCredential() {
    return _inAppCredentialSubject.first.then((state) => state.credentialType);
  }

  Future<void> processInactivation() async {
    final curState = await _inAppCredentialSubject.first;
    if ((curState.pendingInactivations ?? 0) > 0) {
      // If there are still inactivations to be ignored, we ignore
      // and just decrement count
      _inAppCredentialSubject.add(curState.copyWith(
        pendingInactivations: curState.pendingInactivations - 1,
      ));
    } else {
      // Forget about previous opening of browser
      _inAppCredentialSubject.add(_InAppCredentialState());
    }
  }

  // Remember that an inactivation of the app is coming due to opening the browser
  // for issuance of the given credential type. Opening the browser inactivates the app
  // (i.e. sets the AppLifecycleState to paused), so we must not react to that the way
  // we normally do (e.g. go back to the previous app or show the big topleft arrow).
  void expectInactivationForCredentialType(String type) {
    _inAppCredentialSubject.add(_InAppCredentialState(pendingInactivations: 1, credentialType: type));
  }

  Future<void> openIssueURL(BuildContext context, String type) async {
    expectInactivationForCredentialType(type);
    return openURL(
      getTranslation(
        context,
        await _irmaConfigurationSubject.first
            .then((irmaConfiguration) => irmaConfiguration.credentialTypes[type].issueUrl),
      ),
    );
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
      await _iiabchannel.invokeMethod('open_browser', url);
    } else {
      final hasOpened = await launch(url, forceSafariVC: true);
      // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
      if (!hasOpened) {
        throw Exception('url could not be opened: $url');
      }
    }
  }

  Future<void> openURLExternally(String url, {bool suppressQrScanner = false}) async {
    if (suppressQrScanner) {
      _resumedFromBrowserSubject.add(true);
    }
    // On iOS, open Safari rather than Safari view controller
    final hasOpened = await launch(url, forceSafariVC: false);
    // Sometimes launch does not throw an exception itself on failure. Therefore, we also check the return value.
    if (!hasOpened) {
      throw Exception('url could not be opened: $url');
    }
  }

  /// Only meant for testing and debug purposes.
  Future<void> startTestSession(String requestBody) async {
    final Uri uri = Uri.parse('https://demo.privacybydesign.foundation/backend/session');

    final request = await HttpClient().postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(requestBody);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).first;

    if (response.statusCode != 200) {
      debugPrint('Status ${response.statusCode}: $responseBody');
      return;
    }

    final responseObject = jsonDecode(responseBody) as Map<String, dynamic>;
    final sessionPtr = SessionPointer.fromJson(responseObject['sessionPtr'] as Map<String, dynamic>);

    // A debug session is not a regular mobile session, because there is no initiating app.
    // Therefore treat this session like it was started by scanning a QR.
    sessionPtr.continueOnSecondDevice = true;
    _pendingSessionPointerSubject.add(sessionPtr);
  }
}
