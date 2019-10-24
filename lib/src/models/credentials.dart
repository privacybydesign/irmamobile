import 'dart:collection';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/raw_credentials.dart';

class Credentials extends UnmodifiableMapView<String, Credential> {
  Credentials(Map<String, Credential> map)
      : assert(map != null),
        super(map);

  factory Credentials.fromRaw({IrmaConfiguration irmaConfiguration, RawCredentials rawCredentials}) {
    return Credentials(
      rawCredentials.credentials.asMap().map<String, Credential>((_, rawCredential) {
        final credential = Credential.fromRaw(
          irmaConfiguration: irmaConfiguration,
          rawCredential: rawCredential,
        );
        return MapEntry(credential.id, credential);
      }),
    );
  }
}
