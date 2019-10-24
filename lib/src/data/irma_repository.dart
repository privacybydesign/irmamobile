import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/data/irma_client.dart';
import 'package:irmamobile/src/models/authentication_result.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/version_information.dart';

class IrmaRepository {
  static IrmaRepository _instance;
  static IrmaRepository get() {
    if (_instance == null) {
      throw Exception("IrmaRepository has not been initialized");
    }
    return _instance;
  }

  // init must be called during the startup of the application lifecycle.
  static init(IrmaClient client) {
    _instance = IrmaRepository._internal(client: client);
  }

  final IrmaClient client;

// _internal is a named constructor that is only used by `init`.
  IrmaRepository._internal({
    @required this.client,
  }) : assert(client != null);

  Stream<Credentials> getCredentials() {
    return client.getCredentials();
  }

  Stream<Credential> getCredential(String id) {
    return client.getCredential(id);
  }

  Stream<Map<String, Issuer>> getIssuers() {
    return client.getIssuers();
  }

  Stream<VersionInformation> getVersionInformation() {
    return client.getVersionInformation();
  }

  void enroll({String email, String pin, String language}) {
    client.enroll(
      email: email,
      pin: pin,
      language: language,
    );
  }

  void lock() {
    client.lock();
  }

  Future<AuthenticationResult> unlock(String pin) {
    return client.unlock(pin);
  }

  Stream<bool> getLocked() {
    return client.getLocked();
  }
}
