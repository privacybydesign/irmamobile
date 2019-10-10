import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';

class IrmaClientState {
  final Map<String, SchemeManager> schemeManagers;
  final Map<String, Issuer> issuers;
  final Map<String, CredentialType> credentialTypes;
  final Map<String, Credential> credentials;

  IrmaClientState({
    this.schemeManagers,
    this.issuers,
    this.credentialTypes,
    this.credentials,
  });

  IrmaClientState copyWith({
    schemeManagers,
    issuers,
    credentialTypes,
    credentials,
  }) {
    return new IrmaClientState(
      schemeManagers: schemeManagers ?? this.schemeManagers,
      issuers: issuers ?? this.issuers,
      credentialTypes: credentialTypes ?? this.credentialTypes,
      credentials: credentials ?? this.credentials,
    );
  }
}
