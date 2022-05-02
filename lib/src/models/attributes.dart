import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attributes.g.dart';

// Attributes of a credential.
@Deprecated('Use Credential.attributeList or RemovedCredential.attributeList instead.')
class Attributes extends UnmodifiableMapView<AttributeType, AttributeValue> {
  late final List<AttributeType> sortedAttributeTypes;
  late final Image? portraitPhoto;

  @Deprecated('Use Credential.attributeList or RemovedCredential.attributeList instead.')
  Attributes(Map<AttributeType, AttributeValue> map) : super(map) {
    // Pre-calculate an ordered list of attributeTypes, initially on index, finally on displayIndex
    sortedAttributeTypes = keys.toList();
    sortedAttributeTypes.sort((a1, a2) => a1.index.compareTo(a2.index));
    if (sortedAttributeTypes.every((a) => a.displayIndex != null)) {
      sortedAttributeTypes.sort((a1, a2) => a1.displayIndex!.compareTo(a2.displayIndex!));
    }

    // Pre-convert the first portraitPhoto, if present.
    // Remove this when we support multiple photo attributes in one credential.
    final photoIndex = sortedAttributeTypes.indexWhere(
      (at) => this[at] is PhotoValue,
    );

    portraitPhoto = photoIndex >= 0 ? (this[sortedAttributeTypes[photoIndex]]! as PhotoValue).image : null;
  }

  @Deprecated('Use Credential.attributeList or RemovedCredential.attributeList instead.')
  factory Attributes.fromRaw({
    required IrmaConfiguration irmaConfiguration,
    required Map<String, TranslatedValue> rawAttributes,
  }) {
    return Attributes(rawAttributes.map<AttributeType, AttributeValue>((k, v) {
      // irmago enforces that the type of the given attributes is known in the configuration.
      final attributeType = irmaConfiguration.attributeTypes[k]!;
      return MapEntry(
        attributeType,
        AttributeValue.fromRaw(attributeType, v),
      );
    }));
  }
}

class ConDisCon<T> extends UnmodifiableListView<DisCon<T>> {
  ConDisCon(Iterable<DisCon<T>> list) : super(list);

  // This can't be a contructor due to dart-lang/sdk#26391
  static ConDisCon<T> fromRaw<R, T>(List<List<List<R>>> rawConDisCon, T Function(R) fromRaw) {
    return ConDisCon<T>(rawConDisCon.map((rawDisCon) {
      return DisCon<T>(rawDisCon.map((rawCon) {
        return Con<T>(rawCon.map((elem) {
          return fromRaw(elem);
        }));
      }));
    }));
  }

  // This can't be a contructor due to dart-lang/sdk#26391
  static ConDisCon<T> fromConCon<T>(ConCon<T> conCon) {
    return ConDisCon<T>(conCon.map((con) {
      return DisCon<T>(<Con<T>>[con]);
    }));
  }
}

class DisCon<T> extends UnmodifiableListView<Con<T>> {
  DisCon(Iterable<Con<T>> list) : super(list);
}

class ConCon<T> extends UnmodifiableListView<Con<T>> {
  ConCon(Iterable<Con<T>> list) : super(list);

  // This can't be a contructor due to dart-lang/sdk#26391
  static ConCon<T> fromRaw<R, T>(List<List<R>> rawConCon, T Function(R) fromRaw) {
    return ConCon<T>(rawConCon.map((rawCon) {
      return Con<T>(rawCon.map((elem) {
        return fromRaw(elem);
      }));
    }));
  }
}

class Con<T> extends UnmodifiableListView<T> {
  Con(Iterable<T> list) : super(list);
}

@JsonSerializable()
class AttributeIdentifier {
  const AttributeIdentifier({required this.type, required this.credentialHash});

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'CredentialHash')
  final String credentialHash;

  factory AttributeIdentifier.fromJson(Map<String, dynamic> json) => _$AttributeIdentifierFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeIdentifierToJson(this);

  factory AttributeIdentifier.fromAttribute(Attribute attribute) => AttributeIdentifier(
        type: attribute.attributeType.fullId,
        credentialHash: attribute.credentialHash,
      );
}

class CredentialAttribute extends Attribute {
  final Credential credential;

  @override
  final bool notRevokable;

  CredentialAttribute({
    required this.credential,
    required AttributeType attributeType,
    required AttributeValue value,
    required this.notRevokable,
  }) : super(credentialInfo: credential.info, attributeType: attributeType, value: value);

  @override
  bool get expired => credential.expired;
  @override
  bool get revoked => credential.revoked;
  @override
  bool get choosable => !notRevokable && !expired && !revoked;
  @override
  String get credentialHash => credential.hash;
}

class Attribute extends Equatable {
  final CredentialInfo credentialInfo;
  final AttributeType attributeType;
  final AttributeValue value;

  Attribute({
    required this.credentialInfo,
    required this.attributeType,
    required this.value,
  });

  bool get expired => false;
  bool get revoked => false;
  bool get notRevokable => false;
  bool get choosable => false;
  String get credentialHash => '';

  factory Attribute.fromCandidate(
      IrmaConfiguration irmaConfiguration, Credentials credentials, DisclosureCandidate candidate) {
    // irmago enforces that the type of the given attributes is known in the configuration.
    final attributeType = irmaConfiguration.attributeTypes[candidate.type]!;
    if (candidate.credentialHash != null && candidate.credentialHash != '') {
      // irmago enforces that the a credential instance exists for the given candidate.
      final credential = credentials[candidate.credentialHash]!;
      final value = credential.attributes[attributeType]!;
      return CredentialAttribute(
        credential: credential,
        attributeType: attributeType,
        notRevokable: candidate.notRevokable,
        value: value,
      );
    } else {
      final value = AttributeValue.fromRaw(attributeType, candidate.value);
      return Attribute(
        credentialInfo: CredentialInfo.fromConfiguration(
          irmaConfiguration: irmaConfiguration,
          credentialIdentifier: candidate.type.split('.').take(3).join('.'),
        ),
        attributeType: attributeType,
        value: value,
      );
    }
  }

  factory Attribute.fromDisclosedAttribute(IrmaConfiguration irmaConfiguration, DisclosedAttribute disclosedAttribute) {
    // irmago enforces that the type of the given attribute is known in the configuration.
    final attributeType = irmaConfiguration.attributeTypes[disclosedAttribute.identifier]!;
    return Attribute(
      credentialInfo: CredentialInfo.fromConfiguration(
        irmaConfiguration: irmaConfiguration,
        credentialIdentifier: disclosedAttribute.identifier.split('.').take(3).join('.'),
      ),
      attributeType: attributeType,
      value: AttributeValue.fromRaw(attributeType, disclosedAttribute.value),
    );
  }

  @override
  List<Object?> get props => [credentialInfo.id, value];
}

@JsonSerializable()
class DisclosedAttribute {
  const DisclosedAttribute({
    required this.identifier,
    required this.status,
    required this.issuanceTime,
    this.value = const TranslatedValue.empty(),
    this.rawValue,
  });

  @JsonKey(name: 'rawValue')
  final String? rawValue;

  @JsonKey(name: 'value') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue value;

  @JsonKey(name: 'id')
  final String identifier;

  @JsonKey(name: 'status')
  final String status;

  @JsonKey(name: 'issuancetime')
  final int issuanceTime;

  factory DisclosedAttribute.fromJson(Map<String, dynamic> json) => _$DisclosedAttributeFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosedAttributeToJson(this);
}

@JsonSerializable()
class DisclosureCandidate {
  DisclosureCandidate({
    required this.type,
    this.notRevokable = false,
    this.value = const TranslatedValue.empty(),
    this.credentialHash,
  });

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'CredentialHash')
  final String? credentialHash;

  @JsonKey(name: 'Value') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue value;

  @JsonKey(name: 'NotRevokable')
  final bool notRevokable;

  factory DisclosureCandidate.fromJson(Map<String, dynamic> json) => _$DisclosureCandidateFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosureCandidateToJson(this);
}
