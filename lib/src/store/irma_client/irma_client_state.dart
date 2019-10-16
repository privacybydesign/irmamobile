import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';

class IrmaClientState {
  final Map<String, SchemeManager> schemeManagers;
  final Map<String, Issuer> issuers;
  final Map<String, CredentialType> credentialTypes;
  final Map<String, AttributeType> attributeTypes;
  final Map<String, Credential> credentials;

  IrmaClientState({
    this.schemeManagers = const {},
    this.issuers = const {},
    this.credentialTypes = const {},
    this.attributeTypes = const {},
    this.credentials = const {},
  });

  IrmaConfiguration get irmaConfiguration => IrmaConfiguration(
      schemeManagers: schemeManagers,
      issuers: issuers,
      credentialTypes: credentialTypes,
      attributeTypes: attributeTypes);

  IrmaClientState copyWith({
    schemeManagers,
    issuers,
    credentialTypes,
    attributeTypes,
    credentials,
  }) {
    return new IrmaClientState(
      schemeManagers: schemeManagers ?? this.schemeManagers,
      issuers: issuers ?? this.issuers,
      credentialTypes: credentialTypes ?? this.credentialTypes,
      attributeTypes: attributeTypes ?? this.attributeTypes,
      credentials: credentials ?? this.credentials,
    );
  }
}
