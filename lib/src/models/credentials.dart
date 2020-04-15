import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credentials.g.dart';

class Credentials extends UnmodifiableMapView<String, Credential> {
  Credentials(Map<String, Credential> map)
      : assert(map != null),
        super(map);

  factory Credentials.fromRaw({IrmaConfiguration irmaConfiguration, List<RawCredential> rawCredentials}) {
    return Credentials(
      rawCredentials.asMap().map<String, Credential>((_, rawCredential) {
        final credential = Credential.fromRaw(
          irmaConfiguration: irmaConfiguration,
          rawCredential: rawCredential,
        );
        return MapEntry(credential.hash, credential);
      }),
    );
  }

  Credentials rebuiltRemoveWhere(bool Function(String, Credential) test) {
    return Credentials(
      Map.fromEntries(
        entries.expand((entry) => test(entry.key, entry.value) ? [] : [entry]),
      ),
    );
  }
}

class Credential {
  final CredentialInfo info;
  final DateTime signedOn;
  final DateTime expires;
  final Attributes attributes;
  final bool revoked;
  final String hash;

  bool get expired => expires.isBefore(DateTime.now());

  Credential({
    @required this.info,
    @required this.signedOn,
    @required this.expires,
    @required this.attributes,
    @required this.revoked,
    @required this.hash,
  })  : assert(info != null),
        assert(signedOn != null),
        assert(expires != null),
        assert(attributes != null),
        assert(revoked != null),
        assert(hash != null);

  Credential.fromRaw({IrmaConfiguration irmaConfiguration, RawCredential rawCredential})
      : info = CredentialInfo(
          id: rawCredential.id,
          schemeManager: irmaConfiguration.schemeManagers[rawCredential.schemeManagerId],
          issuer: irmaConfiguration.issuers[rawCredential.fullIssuerId],
          credentialType: irmaConfiguration.credentialTypes[rawCredential.fullId],
        ),
        signedOn = DateTime.fromMillisecondsSinceEpoch(rawCredential.signedOn * 1000),
        expires = DateTime.fromMillisecondsSinceEpoch(rawCredential.expires * 1000),
        attributes = Attributes.fromRaw(
          irmaConfiguration: irmaConfiguration,
          rawAttributes: rawCredential.attributes,
        ),
        revoked = rawCredential.revoked,
        hash = rawCredential.hash;
}

class RemovedCredential {
  final CredentialInfo info;
  final Attributes attributes;

  RemovedCredential({
    @required this.info,
    @required this.attributes,
  })  : assert(info != null),
        assert(attributes != null);

  RemovedCredential.fromRaw(
      {IrmaConfiguration irmaConfiguration, String credentialIdentifier, Map<String, dynamic> rawAttributes})
      : info = CredentialInfo.fromConfiguration(
            irmaConfiguration: irmaConfiguration, credentialIdentifier: credentialIdentifier),
        attributes = Attributes.fromRaw(irmaConfiguration: irmaConfiguration, rawAttributes: rawAttributes);
}

class CredentialInfo {
  final String id;
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;

  String get fullId => "${issuer.fullId}.$id";

  CredentialInfo({
    @required this.id,
    @required this.issuer,
    @required this.schemeManager,
    @required this.credentialType,
  })  : assert(id != null),
        assert(issuer != null),
        assert(schemeManager != null),
        assert(credentialType != null);

  factory CredentialInfo.fromConfiguration({IrmaConfiguration irmaConfiguration, String credentialIdentifier}) {
    final parsedAttributeId = credentialIdentifier.split(".");
    final schemeManagerId = parsedAttributeId[0];
    final issuerId = "$schemeManagerId.${parsedAttributeId[1]}";
    final credentialId = "$issuerId.${parsedAttributeId[2]}";
    return CredentialInfo(
      id: parsedAttributeId.last,
      issuer: irmaConfiguration.issuers[issuerId],
      schemeManager: irmaConfiguration.schemeManagers[schemeManagerId],
      credentialType: irmaConfiguration.credentialTypes[credentialId],
    );
  }
}

@JsonSerializable(nullable: false)
class RawCredential {
  const RawCredential({
    this.id,
    this.issuerId,
    this.schemeManagerId,
    this.signedOn,
    this.expires,
    this.attributes,
    this.hash,
    this.revoked,
    this.revocationSupported,
  });

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'SignedOn')
  final int signedOn;

  @JsonKey(name: 'Expires')
  final int expires;

  @JsonKey(name: 'Attributes')
  final Map<String, dynamic> attributes;

  @JsonKey(name: 'Hash')
  final String hash;

  @JsonKey(name: 'Revoked')
  final bool revoked;

  @JsonKey(name: 'RevocationSupported')
  final bool revocationSupported;

  factory RawCredential.fromJson(Map<String, dynamic> json) => _$RawCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$RawCredentialToJson(this);

  String get fullIssuerId => "$schemeManagerId.$issuerId";

  String get fullId => "$fullIssuerId.$id";
}
