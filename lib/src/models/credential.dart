import 'package:flutter/foundation.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/raw_credential.dart';

// Instead of
class Credential {
  final String id;
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;
  final DateTime signedOn;
  final DateTime expires;
  final Attributes attributes;
  final String hash;

  Credential({
    @required this.id,
    @required this.issuer,
    @required this.schemeManager,
    @required this.credentialType,
    @required this.signedOn,
    @required this.expires,
    @required this.attributes,
    @required this.hash,
  })  : assert(id != null),
        assert(issuer != null),
        assert(schemeManager != null),
        assert(credentialType != null),
        assert(signedOn != null),
        assert(expires != null),
        assert(attributes != null),
        assert(hash != null);

  Credential.fromRaw({IrmaConfiguration irmaConfiguration, RawCredential rawCredential})
      : id = rawCredential.id,
        schemeManager = irmaConfiguration.schemeManagers[rawCredential.schemeManagerId],
        issuer = irmaConfiguration.issuers[rawCredential.fullIssuerId],
        credentialType = irmaConfiguration.credentialTypes[rawCredential.fullId],
        signedOn = DateTime.fromMillisecondsSinceEpoch(rawCredential.signedOn),
        expires = DateTime.fromMillisecondsSinceEpoch(rawCredential.expires),
        attributes = Attributes.fromRaw(
          irmaConfiguration: irmaConfiguration,
          rawAttributes: rawCredential.attributes,
        ),
        hash = rawCredential.hash;
}
