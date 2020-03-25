import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/data/irma_bridge.dart';
import 'package:irmamobile/src/data/session_repository.dart';
import 'package:irmamobile/src/models/app_ready_event.dart';
import 'package:irmamobile/src/models/authentication_events.dart';
import 'package:irmamobile/src/models/change_pin_events.dart';
import 'package:irmamobile/src/models/clear_all_data_event.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/enrollment_events.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/handle_url_event.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/session_events.dart';
import 'package:irmamobile/src/models/session_state.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:package_info/package_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:version/version.dart';

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
  final _authenticationEventSubject = PublishSubject<AuthenticationEvent>();
  final _changePinEventSubject = PublishSubject<ChangePinBaseEvent>();
  final _lockedSubject = BehaviorSubject<bool>.seeded(true);
  final _pendingSessionPointerSubject = BehaviorSubject<SessionPointer>.seeded(null);

  // _cachedPin is used to re-activate session without navigating to the pin
  // screen. This is a temporary solution. The app must not be released with this
  // logic still present.
  //
  // TODO: fix this
  @Deprecated("This must be removed")
  String _cachedPin;

  // _internal is a named constructor only used by the factory
  IrmaRepository._internal({
    @required this.bridge,
  }) : assert(bridge != null) {
    _eventSubject.listen(_eventListener);
    _sessionRepository = SessionRepository(
      repo: this,
      sessionEventStream: _eventSubject.where((event) => event is SessionEvent).cast<SessionEvent>(),
    );

    // TODO: This shouldn't be here. See comment on _cachedPin.
    _authenticationEventSubject.listen((event) {
      if (event is AuthenticateEvent) {
        _cachedPin = event.pin;
      }
    });
  }

  Future<void> _eventListener(Event event) async {
    if (event is IrmaConfigurationEvent) {
      irmaConfigurationSubject.add(event.irmaConfiguration);
    } else if (event is CredentialsEvent) {
      _credentialsSubject.add(Credentials.fromRaw(
        irmaConfiguration: await irmaConfigurationSubject.first,
        rawCredentials: event.credentials,
      ));
    } else if (event is AuthenticationEvent) {
      _authenticationEventSubject.add(event);
      if (event is AuthenticateEvent) {
        // TODO: This shouldn't be here. See comment on `_cachedPin`.
        _cachedPin = event.pin;
      }
      if (event is AuthenticationSuccessEvent) {
        _lockedSubject.add(false);
      }
    } else if (event is ChangePinBaseEvent) {
      _changePinEventSubject.add(event);
    } else if (event is EnrollEvent) {
      // TODO: This shouldn't be here. See comment on `_cachedPin`.
      _cachedPin = event.pin;
    } else if (event is EnrollmentStatusEvent) {
      _enrollmentStatusSubject.add(event.enrollmentStatus);
    } else if (event is RequestPinSessionEvent) {
      // TODO: this shouldn't be here, remove when the RequestPinSessionEvent is
      // properly hooked up to UI. See comment on `_cachedPin`.
      if (_cachedPin != null) {
        bridgedDispatch(RespondPinEvent(
          sessionID: event.sessionID,
          proceed: true,
          pin: _cachedPin,
        ));
      }
    } else if (event is HandleURLEvent) {
      try {
        final sessionPointer = SessionPointer.fromString(event.url);
        _pendingSessionPointerSubject.add(sessionPointer);
      } on MissingSessionPointer {
        // pass
      }
    } else if (event is NewSessionEvent) {
      _pendingSessionPointerSubject.add(null);
    } else if (event is ClearAllDataEvent) {
      _credentialsSubject.add(Credentials({}));
      _enrollmentStatusSubject.add(EnrollmentStatus.unenrolled);
      _lockedSubject.add(true);
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
  void enroll({String email, String pin, String language}) {
    _lockedSubject.add(false);

    final event = EnrollEvent(email: email, pin: pin, language: language);
    dispatch(event, isBridgedEvent: true);
  }

  Stream<EnrollmentStatus> getEnrollmentStatus() {
    return _enrollmentStatusSubject.stream;
  }

  // -- Authentication
  void lock() {
    // TODO: This should actually lock irmago up
    _lockedSubject.add(true);
  }

  Future<AuthenticationEvent> unlock(String pin) {
    dispatch(AuthenticateEvent(pin: pin), isBridgedEvent: true);

    return _authenticationEventSubject.where((event) {
      switch (event.runtimeType) {
        case AuthenticationSuccessEvent:
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

  // -- Version information
  Stream<VersionInformation> getVersionInformation() {
    // Get two Streams before waiting on them to allow for asynchronicity.
    final packageInfoStream = PackageInfo.fromPlatform().asStream();
    final irmaVersionInfoStream = irmaConfigurationSubject.stream; // TODO: add filtering

    return packageInfoStream.transform<VersionInformation>(
      combineLatest<PackageInfo, IrmaConfiguration, VersionInformation>(
        irmaVersionInfoStream,
        (packageInfo, irmaVersionInfo) {
          final minimumAppVersions = irmaVersionInfo.schemeManagers['pbdf'].minimumAppVersion;
          Version minimumVersion;
          switch (Platform.operatingSystem) {
            case "android":
              minimumVersion = Version(minimumAppVersions.android, 0, 0);
              break;
            case "ios":
              minimumVersion = Version(minimumAppVersions.iOS, 0, 0);
              break;
            default:
              throw Exception("Unsupported Platfrom.operatingSystem");
          }
          final currentVersion = Version.parse(packageInfo.version);
          return VersionInformation(
            availableVersion: minimumVersion,
            // TODO: use current version as required version until a good
            // version is available from the scheme.
            requiredVersion: currentVersion,
            currentVersion: currentVersion,
          );
        },
      ),
    );
  }

  // -- Session
  Stream<SessionState> getSessionState(int sessionID) {
    return _sessionRepository.getSessionState(sessionID);
  }

  Stream<SessionPointer> getPendingSessionPointer() {
    return _pendingSessionPointerSubject.stream;
  }
}
