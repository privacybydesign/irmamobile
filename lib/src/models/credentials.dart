import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';

import 'attribute.dart';
import 'attribute_value.dart';
import 'irma_configuration.dart';
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

  CredentialView({
    required this.info,
    this.expired = false,
    this.revoked = false,
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
  bool get valid => !expired && !revoked;
  bool get obtainable => credentialType.issueUrl.isNotEmpty;

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

  Credential({
    required super.info,
    required this.signedOn,
    required this.expires,
    required super.attributes,
    required super.revoked,
    required this.hash,
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
