import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

import 'attribute.dart';
import 'attribute_value.dart';
import 'irma_configuration.dart';
import 'log_entry.dart';
import 'translated_value.dart';

part 'credentials.g.dart';

class Credentials extends UnmodifiableMapView<String, Credential> {
  Credentials(super.map);

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

class CredentialView implements CredentialInfo {
  final CredentialInfo info;
  final bool expired;
  final bool revoked;
  final List<Attribute> _attributes;
  final int? instanceCount;

  CredentialView({
    required this.info,
    this.expired = false,
    this.revoked = false,
    this.instanceCount,
    required Iterable<Attribute> attributes,
  }) : _attributes = attributes.toList() {
    assert(_attributes.every((attr) => attr.attributeType.fullCredentialId == info.fullId));
    // Sort by display index if every attribute has one. Otherwise, we sort on regular index.
    if (_attributes.every((attr) => attr.attributeType.displayIndex != null)) {
      _attributes.sort((a1, a2) => a1.attributeType.displayIndex!.compareTo(a2.attributeType.displayIndex!));
    } else {
      _attributes.sort((a1, a2) => a1.attributeType.index.compareTo(a2.attributeType.index));
    }
  }

  factory CredentialView.fromAttributes({
    required IrmaConfiguration irmaConfiguration,
    required Iterable<Attribute> attributes,
  }) {
    assert(attributes.isNotEmpty);
    return CredentialView(
      info: CredentialInfo.fromConfiguration(
        irmaConfiguration: irmaConfiguration,
        credentialIdentifier: attributes.first.attributeType.fullCredentialId,
      ),
      attributes: attributes,
    );
  }

  factory CredentialView.fromRawAttributes({
    required IrmaConfiguration irmaConfiguration,
    required Map<String, TranslatedValue> rawAttributes,
  }) {
    final attributes = rawAttributes.entries.map((entry) {
      final attrType = irmaConfiguration.attributeTypes[entry.key];
      if (attrType == null) {
        throw Exception('Attribute type $attrType not present in configuration');
      }
      return Attribute(
        attributeType: attrType,
        value: AttributeValue.fromRaw(attrType, entry.value),
      );
    });
    return CredentialView.fromAttributes(
      irmaConfiguration: irmaConfiguration,
      attributes: attributes,
    );
  }

  UnmodifiableListView<Attribute> get attributes => UnmodifiableListView(_attributes);

  Iterable<Attribute> get attributesWithValue => _attributes.where((att) => att.value is! NullValue);

  bool get isKeyshareCredential =>
      attributes.any((attr) => info.schemeManager.keyshareAttributes.contains(attr.attributeType.fullId));

  bool get obtainable => credentialType.issueUrl.isNotEmpty;

  bool get valid => !expiredOrEmpty && !revoked;

  bool get expiredOrEmpty => expired || (instanceCount == null ? false : instanceCount == 0);

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

class Credential extends CredentialView {
  final DateTime signedOn;
  final DateTime expires;
  final String hash;
  final CredentialFormat format;

  Credential({
    required super.info,
    required this.signedOn,
    required this.expires,
    required super.attributes,
    required super.revoked,
    required this.hash,
    required this.format,
    required super.instanceCount,
  }) : super(expired: expires.isBefore(DateTime.now()));

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
      );
    });

    return Credential(
      info: credInfo,
      signedOn: DateTime.fromMillisecondsSinceEpoch(rawCredential.signedOn * 1000),
      expires: DateTime.fromMillisecondsSinceEpoch(rawCredential.expires * 1000),
      attributes: attributes,
      revoked: rawCredential.revoked,
      hash: rawCredential.hash,
      format: rawCredential.format,
      instanceCount: rawCredential.instanceCount,
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
    required this.format,
    required this.instanceCount,
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

  @JsonKey(name: 'CredentialFormat', fromJson: stringToCredentialFormat, toJson: credentialFormatToString)
  final CredentialFormat format;

  @JsonKey(name: 'InstanceCount')
  final int? instanceCount;

  factory RawCredential.fromJson(Map<String, dynamic> json) => _$RawCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$RawCredentialToJson(this);

  String get fullIssuerId => '$schemeManagerId.$issuerId';

  String get fullId => '$fullIssuerId.$id';
}

// A credential referencing multiple credential instances with the same attribute values and credential type
// in different credential formats
@JsonSerializable()
class RawMultiFormatCredential {
  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'Revoked')
  final bool revoked;

  @JsonKey(name: 'Attributes')
  final Map<String, TranslatedValue> attributes;

  @JsonKey(name: 'HashByFormat', fromJson: parseHashByFormat)
  final Map<CredentialFormat, String> hashByFormat;

  @JsonKey(name: 'SignedOn')
  final int signedOn;

  @JsonKey(name: 'Expires')
  final int expires;

  @JsonKey(name: 'InstanceCount')
  final int? instanceCount;

  RawMultiFormatCredential({
    required this.id,
    required this.issuerId,
    required this.schemeManagerId,
    required this.attributes,
    required this.hashByFormat,
    required this.signedOn,
    required this.expires,
    required this.revoked,
    required this.instanceCount,
  });

  static RawMultiFormatCredential fromRawCredential(RawCredential cred) {
    return RawMultiFormatCredential(
      id: cred.id,
      issuerId: cred.issuerId,
      schemeManagerId: cred.schemeManagerId,
      attributes: cred.attributes,
      hashByFormat: {cred.format: cred.hash},
      signedOn: cred.signedOn,
      expires: cred.expires,
      revoked: cred.revoked,
      instanceCount: cred.instanceCount,
    );
  }

  factory RawMultiFormatCredential.fromJson(Map<String, dynamic> json) => _$RawMultiFormatCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$RawMultiFormatCredentialToJson(this);
}

// A credential referencing multiple credential instances with the same attribute values and credential type
// in different credential formats
class MultiFormatCredential {
  final String identifier;
  final bool revoked;
  final Issuer issuer;
  final CredentialType credentialType;
  final List<Attribute> attributes;
  final Map<CredentialFormat, String> hashByFormat;
  final DateTime signedOn;
  final DateTime expires;
  final int? instanceCount;

  MultiFormatCredential({
    required this.identifier,
    required this.credentialType,
    required this.attributes,
    required this.hashByFormat,
    required this.signedOn,
    required this.expires,
    required this.revoked,
    required this.issuer,
    required this.instanceCount,
  });

  static MultiFormatCredential fromRawMultiFormatCredential(RawMultiFormatCredential raw, IrmaConfiguration config) {
    final credInfo = CredentialInfo.fromConfiguration(
      irmaConfiguration: config,
      credentialIdentifier: '${raw.schemeManagerId}.${raw.issuerId}.${raw.id}',
    );

    final attributes = raw.attributes.entries.map((entry) {
      final attrType = config.attributeTypes[entry.key];
      if (attrType == null) {
        throw Exception('Attribute type $attrType not present in configuration');
      }

      return Attribute(
        attributeType: attrType,
        value: AttributeValue.fromRaw(attrType, entry.value),
      );
    }).toList();

    assert(attributes.every((attr) => attr.attributeType.fullCredentialId == credInfo.fullId));
    // Sort by display index if every attribute has one. Otherwise, we sort on regular index.
    if (attributes.every((attr) => attr.attributeType.displayIndex != null)) {
      attributes.sort((a1, a2) => a1.attributeType.displayIndex!.compareTo(a2.attributeType.displayIndex!));
    } else {
      attributes.sort((a1, a2) => a1.attributeType.index.compareTo(a2.attributeType.index));
    }

    final signedOn = DateTime.fromMillisecondsSinceEpoch(raw.signedOn * 1000);
    final expires = DateTime.fromMillisecondsSinceEpoch(raw.expires * 1000);

    return MultiFormatCredential(
      identifier: credInfo.fullId,
      credentialType: credInfo.credentialType,
      attributes: attributes,
      hashByFormat: raw.hashByFormat,
      signedOn: signedOn,
      expires: expires,
      revoked: raw.revoked,
      issuer: credInfo.issuer,
      instanceCount: raw.instanceCount,
    );
  }

  bool get expired => expires.isBefore(DateTime.now());

  bool get valid => !expired && !revoked && (instanceCount == null ? true : instanceCount != 0);
}

Map<CredentialFormat, String> parseHashByFormat(Map<String, dynamic> json) {
  return Map.fromEntries(json.entries.map((e) => MapEntry(stringToCredentialFormat(e.key), e.value as String)));
}
