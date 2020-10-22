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

class IrmaRepository {
  static IrmaRepository _instance;
  factory IrmaRepository({@required IrmaBridge client}) {
    _instance = IrmaRepository._internal(bridge: client);
    _instance.dispatch(AppReadyEvent(), isBridgedEvent: true);

    return _instance;
  }

  static IrmaRepository get() {
    if (_instance == null) {
      throw Exception('IrmaRepository has not been initialized');
    }
    return _instance;
  }

  final IrmaBridge bridge;
  final _eventSubject = PublishSubject<Event>();

  SessionRepository _sessionRepository;

  final irmaConfigurationSubject = BehaviorSubject<IrmaConfiguration>(); // TODO: Make this member private
  final _credentialsSubject = BehaviorSubject<Credentials>();
  final _enrollmentStatusSubject = BehaviorSubject<EnrollmentStatus>.seeded(EnrollmentStatus.undetermined);
  final _enrollmentEventSubject = PublishSubject<EnrollmentEvent>();
  final _authenticationEventSubject = PublishSubject<AuthenticationEvent>();
  final _changePinEventSubject = PublishSubject<ChangePinBaseEvent>();
  final _lockedSubject = BehaviorSubject<bool>.seeded(true);
  final _blockedSubject = BehaviorSubject<DateTime>();
  final _lastActiveTimeSubject = BehaviorSubject<DateTime>();
  final _appLifecycleState = BehaviorSubject<AppLifecycleState>();
  final _pendingSessionPointerSubject = BehaviorSubject<SessionPointer>.seeded(null);
  final _preferencesSubject = BehaviorSubject<ClientPreferencesEvent>();
  final _inAppCredentialSubject = BehaviorSubject<_InAppCredentialState>();
  final _resumedWithURLSubject = BehaviorSubject<bool>.seeded(false);
  final _resumedFromBrowserSubject = BehaviorSubject<bool>.seeded(false);

  // _internal is a named constructor only used by the factory
  IrmaRepository._internal({
    @required this.bridge,
  }) : assert(bridge != null) {
    _inAppCredentialSubject.add(_InAppCredentialState());
    _eventSubject.listen(_eventListener);
    _sessionRepository = SessionRepository(
      repo: this,
      sessionEventStream: _eventSubject.where((event) => event is SessionEvent).cast<SessionEvent>(),
    );
  }

  Future<void> _eventListener(Event event) async {
    if (event is ErrorEvent) {
      reportError(event.exception, event.stack);
    } else if (event is IrmaConfigurationEvent) {
      irmaConfigurationSubject.add(event.irmaConfiguration);
    } else if (event is CredentialsEvent) {
      _credentialsSubject.add(Credentials.fromRaw(
        irmaConfiguration: await irmaConfigurationSubject.first,
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
      IrmaPreferences.get().clearAll();
    } else if (event is AppLifecycleChangedEvent) {
      if (event.state == AppLifecycleState.paused) {
        _lastActiveTimeSubject.add(DateTime.now());
        _resumedWithURLSubject.add(false);
      }
    } else if (event is ClientPreferencesEvent) {
      _preferencesSubject.add(event);
    }
  }

  Stream<Event> getEvents() {
    return _eventSubject.stream;
  }

  void dispatch(Event event, {bool isBridgedEvent = false}) {
    _eventSubject.add(event);

    if (isBridgedEvent) {
      bridge.dispatch(event);
    }
  }

  void bridgedDispatch(Event event) {
    dispatch(event, isBridgedEvent: true);
  }

  // -- Scheme manager, issuer, credential and attribute definitions
  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return irmaConfigurationSubject.stream;
  }

  Stream<Map<String, Issuer>> getIssuers() {
    return irmaConfigurationSubject.stream.map<Map<String, Issuer>>(
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
          IrmaPreferences.get().setLongPin(pin.length != 5);
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
          IrmaPreferences.get().setLongPin(pin.length != 5);
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
          IrmaPreferences.get().setLongPin(newPin.length != 5);
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
    final irmaVersionInfoStream = irmaConfigurationSubject.stream; // TODO: add filtering

    return Observable.combineLatest2(packageInfoStream, irmaVersionInfoStream,
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
    });
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
    return Observable.combineLatest2(
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

  final List<String> externalBrowserCredtypes = const [
    "pbdf.nuts.agb",
  ];

  final List<String> externalBrowserUrls = const [
    "https://privacybydesign.foundation/myirma/",
    "https://privacybydesign.foundation/mijnirma/",
    "https://privacybydesign.foundation/demo/",
    "https://privacybydesign.foundation/demo-en/"
  ];

  // TODO Remove when disclosure sessions can be started from custom tabs
  Stream<List<String>> getExternalBrowserURLs() {
    return irmaConfigurationSubject.map(
      (irmaConfiguration) => externalBrowserCredtypes
          .map((type) => irmaConfiguration.credentialTypes[type].issueUrl.values)
          .expand((v) => v)
          .toList()
            ..addAll(externalBrowserUrls),
    );
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

  Future<void> openIssueURL(BuildContext context, String type) async {
    // Remember that we started browser for issuing of this credential type from the app
    // the browser itself dismisses us always, so first dismissal of app needs to be ignored.
    _inAppCredentialSubject.add(_InAppCredentialState(pendingInactivations: 1, credentialType: type));
    openURL(
        context,
        getTranslation(
            context,
            await irmaConfigurationSubject.first
                .then((irmaConfiguration) => irmaConfiguration.credentialTypes[type].issueUrl)));
  }

  Future<void> openURL(BuildContext context, String url) async {
    _resumedFromBrowserSubject.add(true);
    if ((await getExternalBrowserURLs().first).contains(url)) {
      openURLinBrowser(context, url);
    } else {
      if (Platform.isAndroid) {
        _iiabchannel.invokeMethod('open_browser', url);
      } else {
        launch(url, forceSafariVC: true);
      }
    }
  }

  void openURLinBrowser(BuildContext context, String url) {
    // On iOS, open Safari rather than Safari view controller
    launch(url, forceSafariVC: false);
  }
}
