import 'dart:collection';

import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credentials.g.dart';

class Credentials extends UnmodifiableMapView<String, Credential> {
  Credentials(Map<String, Credential> map) : super(map);

  factory Credentials.fromRaw({
    required IrmaConfiguration irmaConfiguration,
    required List<RawCredential> rawCredentials,
  }) {
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
  bool get isKeyshareCredential =>
      attributes.keys.any((attributeType) => info.schemeManager.keyshareAttributes.contains(attributeType.fullId));

  List<Attribute> get attributeList => attributes.entries
      .map((entry) =>
          CredentialAttribute(credential: this, attributeType: entry.key, value: entry.value, notRevokable: false))
      .toList();

  Credential({
    required this.info,
    required this.signedOn,
    required this.expires,
    required this.attributes,
    required this.revoked,
    required this.hash,
  });

  Credential.fromRaw({required IrmaConfiguration irmaConfiguration, required RawCredential rawCredential})
      : info = CredentialInfo.fromConfiguration(
          irmaConfiguration: irmaConfiguration,
          credentialIdentifier: rawCredential.fullId,
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
    required this.info,
    required this.attributes,
  });

  RemovedCredential.fromRaw({
    required IrmaConfiguration irmaConfiguration,
    required String credentialIdentifier,
    required Map<String, TranslatedValue> rawAttributes,
  })  : info = CredentialInfo.fromConfiguration(
            irmaConfiguration: irmaConfiguration, credentialIdentifier: credentialIdentifier),
        attributes = Attributes.fromRaw(irmaConfiguration: irmaConfiguration, rawAttributes: rawAttributes);
}

class CredentialInfo {
  final String id;
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;

  String get fullId => '${issuer.fullId}.$id';

  CredentialInfo({
    required this.id,
    required this.issuer,
    required this.schemeManager,
    required this.credentialType,
  });

  factory CredentialInfo.fromConfiguration({
    required IrmaConfiguration irmaConfiguration,
    required String credentialIdentifier,
  }) {
    final parsedCredentialId = credentialIdentifier.split('.');
    assert(parsedCredentialId.length == 3);
    final schemeManagerId = parsedCredentialId[0];
    final issuerId = '$schemeManagerId.${parsedCredentialId[1]}';
    final credentialId = '$issuerId.${parsedCredentialId[2]}';
    // irmago enforces that the type of the given credential is known in the configuration.
    return CredentialInfo(
      id: parsedCredentialId.last,
      issuer: irmaConfiguration.issuers[issuerId]!,
      schemeManager: irmaConfiguration.schemeManagers[schemeManagerId]!,
      credentialType: irmaConfiguration.credentialTypes[credentialId]!,
    );
  }
}

@JsonSerializable()
class RawCredential {
  const RawCredential({
    required this.id,
    required this.issuerId,
    required this.schemeManagerId,
    required this.signedOn,
    required this.expires,
    required this.attributes,
    required this.hash,
    required this.revoked,
    required this.revocationSupported,
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

  String get fullIssuerId => '$schemeManagerId.$issuerId';

  String get fullId => '$fullIssuerId.$id';
}
