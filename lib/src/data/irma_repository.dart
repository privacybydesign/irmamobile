import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:package_info/package_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/applifecycle_changed_event.dart';
import '../models/authentication_events.dart';
import '../models/change_pin_events.dart';
import '../models/clear_all_data_event.dart';
import '../models/client_preferences.dart';
import '../models/credential_events.dart';
import '../models/credentials.dart';
import '../models/enrollment_events.dart';
import '../models/enrollment_status.dart';
import '../models/error_event.dart';
import '../models/event.dart';
import '../models/handle_url_event.dart';
import '../models/irma_configuration.dart';
import '../models/issue_wizard.dart';
import '../models/native_events.dart';
import '../models/session.dart';
import '../models/session_events.dart';
import '../models/session_state.dart';
import '../models/version_information.dart';
import '../sentry/sentry.dart';
import 'irma_bridge.dart';
import 'irma_preferences.dart';
import 'session_repository.dart';

class _CredentialObtainState {
  // List containing the ids of the credentials
  // that the user tried to obtain via the credential store
  // or by refreshing credentials on the data.
  final Set<String> previouslyLaunchedCredentials;

  _CredentialObtainState({
    this.previouslyLaunchedCredentials = const <String>{},
  });
}

class _ExternalBrowserCredtype {
  final String cred;
  final String os;

  const _ExternalBrowserCredtype({required this.cred, required this.os});
}

class IrmaRepository {
  static IrmaRepository? _instance;
  factory IrmaRepository({
    required IrmaBridge client,
    required IrmaPreferences preferences,
    String defaultKeyshareScheme = 'pbdf',
  }) {
    _instance = IrmaRepository._internal(client, preferences, defaultKeyshareScheme);
    _instance!.dispatch(AppReadyEvent(), isBridgedEvent: true);
    return _instance!;
  }

  @Deprecated('Use IrmaRepositoryProvider.of(context) instead')
  factory IrmaRepository.get() {
    if (_instance == null) {
      throw Exception('IrmaRepository has not been initialized');
    }
    return _instance!;
  }

  final IrmaPreferences preferences;
  final String defaultKeyshareScheme;

  final IrmaBridge _bridge;
  final _eventSubject = PublishSubject<Event>();

  // SessionRepository depends on a IrmaRepository instance, so therefore it must be late final.
  late final SessionRepository _sessionRepository;

  // Try to pipe events from the _eventSubject, otherwise you have to explicitly close the subject in close().
  final _irmaConfigurationSubject = BehaviorSubject<IrmaConfiguration>();
  final _credentialsSubject = BehaviorSubject<Credentials>();
  final _enrollmentStatusSubject = BehaviorSubject<EnrollmentStatus>.seeded(EnrollmentStatus.undetermined);
  final _enrollmentEventSubject = PublishSubject<EnrollmentEvent>();
  final _authenticationEventSubject = PublishSubject<AuthenticationEvent>();
  final _changePinEventSubject = PublishSubject<ChangePinBaseEvent>();
  final _lockedSubject = BehaviorSubject<bool>.seeded(true);
  final _blockedSubject = BehaviorSubject<DateTime?>();
  final _lastActiveTimeSubject = BehaviorSubject<DateTime>();
  final _pendingPointerSubject = BehaviorSubject<Pointer?>.seeded(null);
  final _preferencesSubject = BehaviorSubject<ClientPreferencesEvent>();
  final _credentialObtainState = BehaviorSubject<_CredentialObtainState>();
  final _resumedWithURLSubject = BehaviorSubject<bool>.seeded(false);
  final _resumedFromBrowserSubject = BehaviorSubject<bool>.seeded(false);
  final _issueWizardSubject = BehaviorSubject<IssueWizardEvent?>.seeded(null);
  final _issueWizardActiveSubject = BehaviorSubject<bool>.seeded(false);
  final _fatalErrorSubject = BehaviorSubject<ErrorEvent>();

  late StreamSubscription<Event> _bridgeEventSubscription;

  // _internal is a named constructor only used by the factory
  IrmaRepository._internal(
    this._bridge,
    this.preferences,
    this.defaultKeyshareScheme,
  ) {
    _credentialObtainState.add(_CredentialObtainState());
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
      _pendingPointerSubject.close(),
      _preferencesSubject.close(),
      _credentialObtainState.close(),
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
      if (event.enrolledSchemeManagerIds.contains(defaultKeyshareScheme)) {
        _enrollmentStatusSubject.add(EnrollmentStatus.enrolled);
      } else if (event.unenrolledSchemeManagerIds.contains(defaultKeyshareScheme)) {
        _enrollmentStatusSubject.add(EnrollmentStatus.unenrolled);
        _lockedSubject.add(false);
      } else {
        _enrollmentStatusSubject.add(EnrollmentStatus.undetermined);
        dispatch(ErrorEvent(
          exception: 'Expected default keyshare scheme $defaultKeyshareScheme could not be found in configuration',
          stack: '',
          fatal: true,
        ));
      }
    } else if (event is EnrollmentEvent) {
      _enrollmentEventSubject.add(event);
    } else if (event is HandleURLEvent) {
      try {
        final pointer = Pointer.fromString(event.url);
        _pendingPointerSubject.add(pointer);
        _resumedWithURLSubject.add(true);
        closeWebView();
      } on MissingPointer {
        // pass
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

  void removeLaunchedCredentials(Iterable<String> credentialTypeIds) {
    final state = _credentialObtainState.value;
    final updatedLaunchedCredentials = state.previouslyLaunchedCredentials
        .where(
          (credTypeId) => !credentialTypeIds.contains(credTypeId),
        )
        .toSet();

    _credentialObtainState.add(_CredentialObtainState(
      previouslyLaunchedCredentials: updatedLaunchedCredentials,
    ));
  }

  void bridgedDispatch(Event event) {
    dispatch(event, isBridgedEvent: true);
  }

  // -- Scheme manager, issuer, credential and attribute definitions
  IrmaConfiguration get irmaConfiguration => _irmaConfigurationSubject.value;

  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return _irmaConfigurationSubject.stream;
  }

  Stream<Map<String, Issuer>> getIssuers() {
    return _irmaConfigurationSubject.stream.map<Map<String, Issuer>>(
      (config) => config.issuers,
    );
  }

  // -- Credential instances
  Credentials get credentials => _credentialsSubject.value;

  Stream<Credentials> getCredentials() {
    return _credentialsSubject.stream;
  }

  // -- Enrollment
  Future<EnrollmentEvent> enroll({required String email, required String pin, required String language}) {
    _lockedSubject.add(false);
    _blockedSubject.add(null);

    dispatch(
      EnrollEvent(
        email: email,
        pin: pin,
        language: language,
        schemeId: defaultKeyshareScheme,
      ),
      isBridgedEvent: true,
    );

    return _enrollmentEventSubject.where((event) {
      switch (event.runtimeType) {
        case EnrollmentSuccessEvent:
          preferences.setLongPin(pin.length != 5);
          return true;
        case EnrollmentFailureEvent:
          return true;
        default:
          return false;
      }
    }).first;
  }

  Stream<EnrollmentStatus> getEnrollmentStatus() {
    return _enrollmentStatusSubject.stream;
  }

  // -- Authentication
  void lock({DateTime? unblockTime}) {
    // TODO: This should actually lock irmago up
    _lockedSubject.add(true);
    _blockedSubject.add(unblockTime);
  }

  void setDeveloperMode(bool enabled) {
    bridgedDispatch(ClientPreferencesEvent(clientPreferences: ClientPreferences(developerMode: enabled)));
  }

  Future<AuthenticationEvent> unlock(String pin) {
    dispatch(AuthenticateEvent(pin: pin, schemeId: defaultKeyshareScheme), isBridgedEvent: true);

    return _authenticationEventSubject.where((event) {
      switch (event.runtimeType) {
        case AuthenticationSuccessEvent:
          preferences.setLongPin(pin.length != 5);
          return true;
        case AuthenticationFailedEvent:
        case AuthenticationErrorEvent:
          return true;
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
        case ChangePinFailedEvent:
        case ChangePinErrorEvent:
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

    yield* _irmaConfigurationSubject.map((irmaConfiguration) {
      int minimumBuild = 0;
      for (final scheme in irmaConfiguration.schemeManagers.values) {
        int thisRequirement = 0;
        switch (Platform.operatingSystem) {
          case 'android':
            thisRequirement = scheme.minimumAppVersion.android;
            break;
          case 'ios':
            thisRequirement = scheme.minimumAppVersion.iOS;
            break;
          default:
            throw Exception('Unsupported Platfrom.operatingSystem');
        }
        if (thisRequirement > minimumBuild) {
          minimumBuild = thisRequirement;
        }
      }

      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? minimumBuild;

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
  SessionState? getCurrentSessionState(int sessionID) => _sessionRepository.getCurrentSessionState(sessionID);

  Stream<SessionState> getSessionState(int sessionID) {
    // Prevent states to be emitted twice when multiple sessions run in parallel.
    return _sessionRepository.getSessionState(sessionID).distinct();
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

  Stream<Pointer?> getPendingPointer() {
    return _pendingPointerSubject.stream;
  }

  // -- lastActiveTime
  Stream<DateTime> getLastActiveTime() {
    return _lastActiveTimeSubject.stream;
  }

  Stream<bool> getDeveloperMode() {
    return _preferencesSubject.stream.map((pref) => pref.clientPreferences.developerMode);
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
      throw UnsupportedError('Wizard id $id could not been found');
    }
    final wizardData = conf.issueWizards[id]!;
    final creds = Set.from(credentials.values.map((cred) => cred.info.fullId));
    return IssueWizardEvent(
      haveCredential: wizardData.issues != null && creds.contains(wizardData.issues),
      wizardData: wizardData,
      wizardContents: contents.map((item) {
        // The credential field may be non-nil for any wizard item type
        final haveCredential = item.credential != null && creds.contains(item.credential);
        if (item.type != 'credential') {
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

  final List<_ExternalBrowserCredtype> externalBrowserCredtypes = const [
    _ExternalBrowserCredtype(cred: 'pbdf.gemeente.address', os: 'ios'),
    _ExternalBrowserCredtype(cred: 'pbdf.gemeente.personalData', os: 'ios'),
    _ExternalBrowserCredtype(cred: 'pbdf.pbdf.idin', os: 'android'),
  ];

  final List<String> externalBrowserUrls = const [
    'https://privacybydesign.foundation/myirma/',
    'https://privacybydesign.foundation/mijnirma/',
    'https://privacybydesign.foundation/demo/',
    'https://privacybydesign.foundation/demo-en/'
  ];

  // TODO Remove when disclosure sessions can be started from custom tabs
  Stream<List<String>> getExternalBrowserURLs() {
    return _irmaConfigurationSubject.map(
      (irmaConfiguration) => externalBrowserCredtypes
          .where((type) => type.os == Platform.operatingSystem)
          .map((type) => irmaConfiguration.credentialTypes[type.cred]?.issueUrl.values ?? [])
          .expand((v) => v)
          .toList()
        ..addAll(externalBrowserUrls),
    );
  }

  Stream<ErrorEvent> getFatalErrors() {
    return _fatalErrorSubject.stream;
  }

  static const _iiabchannel = MethodChannel('irma.app/iiab');

  Future<Set<String>> getPreviouslyLaunchedCredentials() {
    return _credentialObtainState.first.then(
      (state) => state.previouslyLaunchedCredentials,
    );
  }

  Future<void> openIssueURL(
    BuildContext context,
    String type,
  ) async {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    final irmaConfig = await _irmaConfigurationSubject.first;
    final cred = irmaConfig.credentialTypes[type];

    if (cred == null) {
      throw UnsupportedError('Credential type $type not found in irma config');
    }

    final url = cred.issueUrl.translate(lang, fallback: '');
    if (url.isEmpty) {
      throw UnsupportedError('Credential type $type does not have a suitable issue url for $lang');
    }

    final alreadyObtainedCredentials = await _credentialsSubject.first;
    final alreadyObtainedCredentialsTypes = alreadyObtainedCredentials.values.map((cred) => cred.credentialType.fullId);

    if (cred.isInCredentialStore || alreadyObtainedCredentialsTypes.contains(type)) {
      final state = await _credentialObtainState.first;
      final updatedLaunchedCredentials = {
        ...state.previouslyLaunchedCredentials,
        type,
      };

      _credentialObtainState.add(_CredentialObtainState(
        previouslyLaunchedCredentials: updatedLaunchedCredentials,
      ));
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
  Future<void> startTestSession(String requestBody, {continueOnSecondDevice = true}) async {
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

    sessionPtr.continueOnSecondDevice = continueOnSecondDevice;
    _pendingPointerSubject.add(sessionPtr);
  }

  /// Only meant for testing and debug purposes.
  Future<void> startTestIssueWizard(String wizardKey) async {
    final issueWizardPointer = IssueWizardPointer(wizardKey);
    _pendingPointerSubject.add(issueWizardPointer);
  }
}
