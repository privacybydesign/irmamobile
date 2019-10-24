import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/version_information.dart';

abstract class IrmaClient {
  Stream<Credentials> getCredentials();

  Stream<Credential> getCredential(String id);

  Stream<Map<String, Issuer>> getIssuers();

  Stream<VersionInformation> getVersionInformation();

  void enroll({String email, String pin, String language});
}
