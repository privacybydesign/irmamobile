import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
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
  final String hash;

  Credential({
    @required this.info,
    @required this.signedOn,
    @required this.expires,
    @required this.attributes,
    @required this.hash,
  })  : assert(info != null),
        assert(signedOn != null),
        assert(expires != null),
        assert(attributes != null),
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
        hash = rawCredential.hash;
}

class CredentialInfo {
  final String id;
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;

  CredentialInfo({
    @required this.id,
    @required this.issuer,
    @required this.schemeManager,
    @required this.credentialType,
  })  : assert(id != null),
        assert(issuer != null),
        assert(schemeManager != null),
        assert(credentialType != null);
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
  final Map<String, TranslatedValue> attributes;

  @JsonKey(name: 'Hash')
  final String hash;

  factory RawCredential.fromJson(Map<String, dynamic> json) => _$RawCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$RawCredentialToJson(this);

  String get fullIssuerId => "$schemeManagerId.$issuerId";

  String get fullId => "$fullIssuerId.$id";
}
