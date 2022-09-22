import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

import 'attribute.dart';
import 'attribute_value.dart';
import 'irma_configuration.dart';
import 'translated_value.dart';

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

abstract class AbstractCredential implements CredentialInfo {
  final CredentialInfo info;
  final List<Attribute> _attributes;

  AbstractCredential({
    required this.info,
    required Iterable<Attribute> attributes,
  }) : _attributes = attributes.toList() {
    assert(_attributes.every((attr) => attr.attributeType.fullCredentialId == info.fullId));
    // Sort by display index if every attribute has one. Otherwise, we keep the current sorting.
    if (_attributes.every((attr) => attr.attributeType.displayIndex != null)) {
      _attributes.sort((a1, a2) => a1.attributeType.displayIndex!.compareTo(a2.attributeType.displayIndex!));
    }
  }

  UnmodifiableListView<Attribute> get attributes => UnmodifiableListView(_attributes);
  Iterable<Attribute> get attributesWithValue => _attributes.where((att) => att.value is! NullValue);
  bool get isKeyshareCredential =>
      attributes.any((attr) => info.schemeManager.keyshareAttributes.contains(attr.attributeType.fullId));

  @override
  CredentialType get credentialType => info.credentialType;

  @override
  String get fullId => info.fullId;

  @override
  String get id => info.id;

  @override
  Issuer get issuer => info.issuer;

  @override
  SchemeManager get schemeManager => info.schemeManager;
}

class Credential extends AbstractCredential {
  final DateTime signedOn;
  final DateTime expires;
  final bool revoked;
  final String hash;

  bool get expired => expires.isBefore(DateTime.now());
  bool get valid => !expired && !revoked;

  Credential({
    required CredentialInfo info,
    required this.signedOn,
    required this.expires,
    required Iterable<Attribute> attributes,
    required this.revoked,
    required this.hash,
  }) : super(info: info, attributes: attributes);

  factory Credential.fromRaw({required IrmaConfiguration irmaConfiguration, required RawCredential rawCredential}) {
    final credInfo = CredentialInfo.fromConfiguration(
      irmaConfiguration: irmaConfiguration,
      credentialIdentifier: rawCredential.fullId,
    );

    final attributes = rawCredential.attributes.entries.map((entry) {
      final attrType = irmaConfiguration.attributeTypes[entry.key];
      if (attrType == null) {
        throw Exception('Attribute type $attrType not present in configuration');
      }

      return Attribute(
        attributeType: attrType,
        value: AttributeValue.fromRaw(attrType, entry.value),
        credentialHash: rawCredential.hash,
      );
    });

    return Credential(
      info: credInfo,
      signedOn: DateTime.fromMillisecondsSinceEpoch(rawCredential.signedOn * 1000),
      expires: DateTime.fromMillisecondsSinceEpoch(rawCredential.expires * 1000),
      attributes: attributes,
      revoked: rawCredential.revoked,
      hash: rawCredential.hash,
    );
  }
}

class RemovedCredential extends AbstractCredential {
  RemovedCredential({
    required CredentialInfo info,
    required Iterable<Attribute> attributes,
  }) : super(info: info, attributes: attributes);

  factory RemovedCredential.fromRaw({
    required IrmaConfiguration irmaConfiguration,
    required String credentialIdentifier,
    required Map<String, TranslatedValue> rawAttributes,
  }) {
    final credInfo = CredentialInfo.fromConfiguration(
      irmaConfiguration: irmaConfiguration,
      credentialIdentifier: credentialIdentifier,
    );
    return RemovedCredential(
      info: credInfo,
      attributes: rawAttributes.entries.map((entry) {
        final attrType = irmaConfiguration.attributeTypes[entry.key];
        if (attrType == null) {
          throw Exception('Attribute type $attrType not present in configuration');
        }

        return Attribute(
          attributeType: attrType,
          value: AttributeValue.fromRaw(attrType, entry.value),
        );
      }),
    );
  }
}

class CredentialInfo {
  final String id;
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;

  String get fullId => '${issuer.fullId}.$id';

  const CredentialInfo({
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

    final schemeManager = irmaConfiguration.schemeManagers[schemeManagerId];
    final issuer = irmaConfiguration.issuers[issuerId];
    final credentialType = irmaConfiguration.credentialTypes[credentialId];
    if (schemeManager == null || issuer == null || credentialType == null) {
      throw Exception('Credential type $credentialId not present in configuration');
    }

    return CredentialInfo(
      id: parsedCredentialId.last,
      schemeManager: schemeManager,
      issuer: issuer,
      credentialType: credentialType,
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
