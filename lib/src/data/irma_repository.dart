import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/data/irma_bridge.dart';
import 'package:irmamobile/src/data/session_repository.dart';
import 'package:irmamobile/src/models/app_ready_event.dart';
import 'package:irmamobile/src/models/authentication.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/enroll_event.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/models/preferences.dart';
import 'package:irmamobile/src/models/session.dart';
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
  final _eventSubject = BehaviorSubject<Event>();

  SessionRepository _sessionRepository;

  // _internal is a named constructor only used by the factory
  IrmaRepository._internal({
    @required this.bridge,
  }) : assert(bridge != null) {
    _eventSubject.listen(_eventListener);
    _sessionRepository = SessionRepository(
      repo: this,
      sessionEventStream: _eventSubject.where((event) => event is SessionEvent).cast<SessionEvent>(),
    );
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
    } else if (event is EnrollmentStatusEvent) {
      final isEnrolled = event.unenrolledSchemeManagerIds.isEmpty;
      _isEnrolledSubject.add(isEnrolled);
    } else if (event is PreferencesEvent) {
      _preferencesSubject.add(event.preferences);
    } else if (event is LogsEvent) {
      _logsSubject.add((event as LogsEvent).logEntries);
    }
  }

  Stream<Object> getEvents() {
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
  final irmaConfigurationSubject = BehaviorSubject<IrmaConfiguration>();

  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return irmaConfigurationSubject.stream;
  }

  Stream<Map<String, Issuer>> getIssuers() {
    return irmaConfigurationSubject.stream.map<Map<String, Issuer>>(
      (config) => config.issuers,
    );
  }

  // -- Credential instances
  final _credentialsSubject = BehaviorSubject<Credentials>();

  Stream<Credentials> getCredentials() {
    return _credentialsSubject.stream;
  }

  void deleteAllCredentials() {
    // TODO
  }

  // -- Enrollment
  final _isEnrolledSubject = PublishSubject<bool>();

  // TODO: Remove this away
  void enroll({String email, String pin, String language}) {
    _lockedSubject.add(false);

    final event = EnrollEvent(email: email, pin: pin, language: language);
    dispatch(event, isBridgedEvent: true);
  }

  Stream<bool> getIsEnrolled() {
    return _isEnrolledSubject.stream;
  }

  // -- Authentication
  final _authenticationEventSubject = PublishSubject<AuthenticationEvent>();
  final _lockedSubject = BehaviorSubject<bool>.seeded(true);

  void _authenticationEventListener(AuthenticationEvent event) {
    if (event is AuthenticationSuccessEvent) {
      _lockedSubject.add(false);
    } else if (event is AuthenticationFailedEvent) {
      _lockedSubject.add(true);
    }
  }

  void lock() {
    // TODO: this doesn't seem to actually cause a locking event anymore..
    // Should maybe be reworked to go to irmago?
    _lockedSubject.add(true);
  }

  // TODO: Move getting of first authentication result to own method
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

  // -- Logs
  final _logsSubject = BehaviorSubject<List<LogEntry>>();
  Stream<List<LogEntry>> getLogs() {
    return _logsSubject.stream;
  }

  final _preferencesSubject = BehaviorSubject<Preferences>();
  Stream<Preferences> getPreferences() {
    return _preferencesSubject.stream;
  }

  // -- Session
  Stream<SessionState> getSessionState(int sessionID) {
    return _sessionRepository.getSessionState(sessionID);
  }
}
