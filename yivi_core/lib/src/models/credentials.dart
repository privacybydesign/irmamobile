import "dart:collection";

import "package:json_annotation/json_annotation.dart";

import "attribute.dart";
import "attribute_value.dart";
import "irma_configuration.dart";
import "log_entry.dart";
import "translated_value.dart";

part "credentials.g.dart";

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class CredentialTypeInfo {
  final TranslatedValue issuerName;

  final TranslatedValue name;

  final String verifiableCredentialType;

  final Map<String, TranslatedValue> attributes;

  final CredentialFormat credentialFormat;

  CredentialTypeInfo({
    required this.issuerName,
    required this.name,
    required this.verifiableCredentialType,
    required this.attributes,
    required this.credentialFormat,
  });

  factory CredentialTypeInfo.fromJson(Map<String, dynamic> json) =>
      _$CredentialTypeInfoFromJson(json);
}

class Credentials extends UnmodifiableMapView<String, Credential> {
  Credentials(super.map);

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
    assert(
      _attributes.every(
        (attr) => attr.attributeType.fullCredentialId == info.fullId,
      ),
    );
    // Sort by display index if every attribute has one. Otherwise, we sort on regular index.
    if (_attributes.every((attr) => attr.attributeType.displayIndex != null)) {
      _attributes.sort(
        (a1, a2) => a1.attributeType.displayIndex!.compareTo(
          a2.attributeType.displayIndex!,
        ),
      );
    } else {
      _attributes.sort(
        (a1, a2) => a1.attributeType.index.compareTo(a2.attributeType.index),
      );
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
        throw Exception(
          "Attribute type $attrType not present in configuration",
        );
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

  UnmodifiableListView<Attribute> get attributes =>
      UnmodifiableListView(_attributes);

  Iterable<Attribute> get attributesWithValue =>
      _attributes.where((att) => att.value is! NullValue);

  bool get isKeyshareCredential => attributes.any(
    (attr) => info.schemeManager.keyshareAttributes.contains(
      attr.attributeType.fullId,
    ),
  );

  bool get obtainable => credentialType.issueUrl.isNotEmpty;

  bool get valid => !expiredOrEmpty && !revoked;

  bool get expiredOrEmpty =>
      expired || (instanceCount == null ? false : instanceCount == 0);

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
}

class CredentialInfo {
  final String id;
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;

  String get fullId => "${issuer.fullId}.$id";

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
    final parsedCredentialId = credentialIdentifier.split(".");
    assert(parsedCredentialId.length == 3);
    final schemeManagerId = parsedCredentialId[0];
    final issuerId = "$schemeManagerId.${parsedCredentialId[1]}";
    final credentialId = "$issuerId.${parsedCredentialId[2]}";

    final schemeManager = irmaConfiguration.schemeManagers[schemeManagerId];
    final issuer = irmaConfiguration.issuers[issuerId];
    final credentialType = irmaConfiguration.credentialTypes[credentialId];
    if (schemeManager == null || issuer == null || credentialType == null) {
      throw Exception(
        "Credential type $credentialId not present in configuration",
      );
    }

    return CredentialInfo(
      id: parsedCredentialId.last,
      schemeManager: schemeManager,
      issuer: issuer,
      credentialType: credentialType,
    );
  }
}
