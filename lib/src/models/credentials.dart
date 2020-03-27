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
  final String id;
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;
  final DateTime signedOn;
  final DateTime expires;
  final Attributes attributes;
  final bool revoked;
  final String hash;

  bool get expired => expires?.isBefore(DateTime.now());

  Credential({
    @required this.id,
    @required this.issuer,
    @required this.schemeManager,
    @required this.credentialType,
    @required this.signedOn,
    @required this.expires,
    @required this.attributes,
    @required this.revoked,
    @required this.hash,
  })  : assert(id != null),
        assert(issuer != null),
        assert(schemeManager != null),
        assert(credentialType != null),
        assert(signedOn != null || hash == null),
        assert(expires != null || hash == null),
        assert(attributes != null || hash == null),
        assert(revoked != null || hash == null);

  Credential.fromRaw({IrmaConfiguration irmaConfiguration, RawCredential rawCredential})
      : id = rawCredential.id,
        schemeManager = irmaConfiguration.schemeManagers[rawCredential.schemeManagerId],
        issuer = irmaConfiguration.issuers[rawCredential.fullIssuerId],
        credentialType = irmaConfiguration.credentialTypes[rawCredential.fullId],
        signedOn = DateTime.fromMillisecondsSinceEpoch(rawCredential.signedOn * 1000),
        expires = DateTime.fromMillisecondsSinceEpoch(rawCredential.expires * 1000),
        attributes = Attributes.fromRaw(
          irmaConfiguration: irmaConfiguration,
          rawAttributes: rawCredential.attributes,
        ),
        revoked = rawCredential.revoked,
        hash = rawCredential.hash;

  factory Credential.fromId({IrmaConfiguration irmaConfiguration, String id}) {
    final parts = id.split("\.");
    final schemeManagerId = parts[0];
    final fullIssuerId = "$schemeManagerId.${parts[1]}";
    return Credential(
        id: parts.last,
        issuer: irmaConfiguration.issuers[fullIssuerId],
        schemeManager: irmaConfiguration.schemeManagers[schemeManagerId],
        credentialType: irmaConfiguration.credentialTypes[id],
        signedOn: null,
        expires: null,
        attributes: null,
        revoked: null,
        hash: null);
  }

  String get fullIssuerId => "${issuer.fullId}";

  String get fullId => "$fullIssuerId.$id";
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
  final Map<String, TranslatedValue> attributes;

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
