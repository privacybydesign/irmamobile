import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:irmamobile/src/data/irma_client.dart';
import 'package:irmamobile/src/models/authentication_result.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/enroll_event.dart';
import 'package:irmamobile/src/models/enrollment_status.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log.dart';
import 'package:irmamobile/src/models/preferences.dart';
import 'package:irmamobile/src/models/raw_credentials.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:package_info/package_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:version/version.dart';

class IrmaClientBridge implements IrmaClient {
  MethodChannel methodChannel;

  IrmaClientBridge() {
    methodChannel = const MethodChannel('irma.app/irma_mobile_bridge');
    methodChannel.setMethodCallHandler(_handleMethodCall);
    methodChannel.invokeMethod<void>("AppReadyEvent", "{}");

    _authenticationSubject.listen((result) {
      if (result is AuthenticationResultSuccess) {
        _lockedSubject.add(false);
      } else {
        _lockedSubject.add(true);
      }
    });
  }

  final _irmaConfigurationStream = BehaviorSubject<IrmaConfiguration>();
  final _credentialsStream = BehaviorSubject<Credentials>();
  final _isEnrolledStream = PublishSubject<bool>();
  final _preferencesStream = BehaviorSubject<Preferences>();
  final _enrollmentStatusStream = BehaviorSubject<EnrollmentStatus>();

  // _handleMethodCall handles incomming method calls from irmago and returns an
  // answer to irmago.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      final data = jsonDecode(call.arguments as String) as Map<String, dynamic>;
      switch (call.method) {
        case 'IrmaConfigurationEvent':
          _irmaConfigurationStream.add(IrmaConfiguration.fromJson(data));
          break;
        case 'CredentialsEvent':
          _credentialsStream.add(Credentials.fromRaw(
            irmaConfiguration: await _irmaConfigurationStream.firstWhere((irmaConfig) => irmaConfig != null),
            rawCredentials: RawCredentials.fromJson(data),
          ));
          break;
        case 'AuthenticationFailedEvent':
          _authenticationSubject.add(AuthenticationResultFailed.fromJson(data));
          break;
        case 'AuthenticationSuccessEvent':
          _authenticationSubject.add(AuthenticationResultSuccess());
          break;
        case 'AuthenticationErrorEvent':
          _authenticationSubject.add(AuthenticationResultError.fromJson(data));
          break;
        case 'EnrollmentStatusEvent':
          // TODO: Add model for this
          debugPrint(jsonEncode(data));
          final unenrolledSchemeManagers = data['UnenrolledSchemeManagerIds'] as List<dynamic>;
          _isEnrolledStream.add(unenrolledSchemeManagers.isEmpty);

          break;
        case 'PreferencesEvent':
          _preferencesStream.add(Preferences.fromJson(data['Preferences'] as Map<String, dynamic>));
          break;
        case 'EnrollmentStatusEvent':
          _enrollmentStatusStream.add(EnrollmentStatus.fromJson(data));
          break;
        default:
          debugPrint('Unrecognized bridge event name received: ${call.method} with payload: $data');

          return Future<dynamic>.value(null);
      }
    } catch (e, stacktrace) {
      debugPrint("Error receiving or parsing method call from native: ${e.toString()}");
      debugPrint(stacktrace.toString());
      rethrow;
    }

    return Future<dynamic>.value(null);
  }

  @override
  Stream<Credentials> getCredentials() {
    return _credentialsStream.stream;
  }

  @override
  Stream<IrmaConfiguration> getIrmaConfiguration() {
    return _irmaConfigurationStream.stream;
  }

  @override
  Stream<Credential> getCredential(String hash) {
    return _credentialsStream
        .map<Credential>((credentials) => credentials[hash])
        .where((credential) => credential != null)
        .distinct();
  }

  @override
  Stream<Map<String, Issuer>> getIssuers() {
    return _irmaConfigurationStream.stream.map<Map<String, Issuer>>(
      (config) => config.issuers,
    );
  }

  @override
  Stream<VersionInformation> getVersionInformation() {
    // Get two Streams before waiting on them to allow for asynchronicity.
    final packageInfoStream = PackageInfo.fromPlatform().asStream();
    final irmaVersionInfoStream = _irmaConfigurationStream.stream; // TODO: add filtering

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

  @override
  void deleteAllCredentials() {
    methodChannel.invokeMethod("DeleteAllCredentialsEvent");
  }

  Stream<EnrollmentStatus> getEnrollmentStatus() {
    return _enrollmentStatusStream;
  }

  @override
  void enroll({String email, String pin, String language}) {
    _lockedSubject.add(false);
    methodChannel.invokeMethod(
        "EnrollEvent",
        jsonEncode(EnrollEvent(
          email: email,
          pin: pin,
          language: language,
        ).toJson()));
  }

  final _authenticationSubject = PublishSubject<AuthenticationResult>();
  final _lockedSubject = BehaviorSubject<bool>.seeded(true);

  @override
  void lock() {
    _lockedSubject.add(true);
  }

  @override
  Future<AuthenticationResult> unlock(String pin) {
    methodChannel.invokeMethod("AuthenticateEvent", jsonEncode({'pin': pin}));
    return _authenticationSubject.first;
  }

  @override
  Stream<bool> getLocked() {
    return _lockedSubject.distinct().asBroadcastStream();
  }

  @override
  Stream<bool> getIsEnrolled() {
    return _isEnrolledStream.stream;
  }

  int _sessionId = 0;

  @override
  void startSession(String request) {
    methodChannel.invokeMethod("NewSessionEvent", '{"SessionID": $_sessionId, "Request": $request}');
    _sessionId++;
  }

  Stream<List<Log>> loadLogs(int before, int max) {
    // TODO: implement loadLogs
    return null;
  }

  @override
  Stream<Preferences> getPreferences() {
    return _preferencesStream.stream;
  }

  @override
  void setCrashReportingPreference({@required bool value}) {
    methodChannel.invokeMethod("SetCrashReportingPreferenceEvent", jsonEncode({'EnableCrashReporting': value}));
  }

  @override
  void setQrScannerOnStartupPreference({@required bool value}) {
    methodChannel.invokeMethod("SetQrScannerOnStartupPreferenceEvent", jsonEncode({'QrScannerOnStartup': value}));
  }
}
