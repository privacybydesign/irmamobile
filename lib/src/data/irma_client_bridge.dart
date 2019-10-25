import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:irmamobile/src/data/irma_client.dart';
import 'package:irmamobile/src/models/authentication_result.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/enroll_event.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
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

    authenticationSubject.listen((result) {
      if (result is AuthenticationResultSuccess) {
        lockedSubject.add(true);
      } else {
        lockedSubject.add(false);
      }
    });
  }

  final irmaConfigurationStream = BehaviorSubject<IrmaConfiguration>();
  final credentialsStream = PublishSubject<Credentials>();

  // _handleMethodCall handles incomming method calls from irmago and returns an
  // answer to irmago.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      var data = jsonDecode(call.arguments);
      switch (call.method) {
        case 'IrmaConfigurationEvent':
          irmaConfigurationStream.add(IrmaConfiguration.fromJson(data));
          break;
        case 'CredentialsEvent':
          credentialsStream.add(Credentials.fromRaw(
            irmaConfiguration: await irmaConfigurationStream.firstWhere((irmaConfig) => irmaConfig != null),
            rawCredentials: RawCredentials.fromJson(data),
          ));
          break;
        case 'AuthenticationFailedEvent':
          authenticationSubject.add(AuthenticationResultFailed.fromJson(data));
          break;
        case 'AuthenticationSuccess':
          authenticationSubject.add(AuthenticationResultSuccess());
          break;
        case 'AuthenticationError':
          authenticationSubject.add(AuthenticationResultError.fromJson(data));
          break;
        default:
          debugPrint('Unrecognized bridge event name received: ' + call.method);
          return Future<dynamic>.value(null);
      }
    } catch (e, stacktrace) {
      debugPrint("Error receiving or parsing method call from native: " + e.toString());
      debugPrint(stacktrace.toString());
      rethrow;
    }

    return Future<dynamic>.value(null);
  }

  @override
  Stream<Credentials> getCredentials() {
    return credentialsStream.stream;
  }

  @override
  Stream<Credential> getCredential(String hash) {
    return credentialsStream
        .map<Credential>((credentials) => credentials[hash])
        .where((credential) => credential != null)
        .distinct();
  }

  @override
  Stream<Map<String, Issuer>> getIssuers() {
    return irmaConfigurationStream.stream.map<Map<String, Issuer>>(
      (config) => config.issuers,
    );
  }

  @override
  Stream<VersionInformation> getVersionInformation() {
    // Get two Streams before waiting on them to allow for asynchronicity.
    final packageInfoStream = PackageInfo.fromPlatform().asStream();
    final irmaVersionInfoStream = irmaConfigurationStream.stream; // TODO: add filtering

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
  void enroll({String email, String pin, String language}) {
    this.methodChannel.invokeMethod(
        "EnrollEvent",
        jsonEncode(EnrollEvent(
          email: email,
          pin: pin,
          language: language,
        ).toJson()));
  }

  final authenticationSubject = PublishSubject<AuthenticationResult>();
  final lockedSubject = BehaviorSubject<bool>.seeded(true);

  @override
  void lock() {
    lockedSubject.add(true);
  }

  @override
  Future<AuthenticationResult> unlock(String pin) {
    this.methodChannel.invokeMethod("AuthenticateEvent", jsonEncode({'pin': pin}));
    return authenticationSubject.first;
  }

  @override
  Stream<bool> getLocked() {
    return lockedSubject.distinct().asBroadcastStream();
  }
}
