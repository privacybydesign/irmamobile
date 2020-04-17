import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/attribute_value.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attributes.g.dart';

// Attributes of a credential.
class Attributes extends UnmodifiableMapView<AttributeType, AttributeValue> {
  List<AttributeType> sortedAttributeTypes;
  Image portraitPhoto;

  Attributes(Map<AttributeType, AttributeValue> map)
      : assert(map != null),
        super(map) {
    // Pre-calculate an ordered list of attributeTypes, initially on index, finally on displayIndex
    sortedAttributeTypes = keys.toList();
    sortedAttributeTypes.sort((a1, a2) => a1.index.compareTo(a2.index));
    if (sortedAttributeTypes.every((a) => a.displayIndex != null)) {
      sortedAttributeTypes.sort((a1, a2) => (a1.displayIndex).compareTo(a2.displayIndex));
    }

    // Pre-convert the first portraitPhoto, if present
    final photoAttributeType = sortedAttributeTypes.firstWhere(
      (at) => this[at] is PhotoValue,
      orElse: () => null,
    );

    if (photoAttributeType != null) {
      portraitPhoto = (this[photoAttributeType] as PhotoValue).image;
    }
  }

  factory Attributes.fromRaw({IrmaConfiguration irmaConfiguration, Map<String, TranslatedValue> rawAttributes}) {
    return Attributes(rawAttributes.map<AttributeType, AttributeValue>((k, v) {
      return MapEntry(
        irmaConfiguration.attributeTypes[k],
        AttributeValue.fromRaw(irmaConfiguration.attributeTypes[k], v),
      );
    }));
  }
}

class ConDisCon<T> extends UnmodifiableListView<DisCon<T>> {
  ConDisCon(Iterable<DisCon<T>> list)
      : assert(list != null),
        super(list);

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
  DisCon(Iterable<Con<T>> list)
      : assert(list != null),
        super(list);
}

class ConCon<T> extends UnmodifiableListView<Con<T>> {
  ConCon(Iterable<Con<T>> list)
      : assert(list != null),
        super(list);

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
  Con(Iterable<T> list)
      : assert(list != null),
        super(list);
}

@JsonSerializable()
class AttributeRequest {
  AttributeRequest({this.type, this.value, this.notNull});

  @JsonKey(name: 'Type')
  String type;

  @JsonKey(name: 'Value')
  String value;

  @JsonKey(name: 'NotNull')
  bool notNull;

  factory AttributeRequest.fromJson(Map<String, dynamic> json) => _$AttributeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeRequestToJson(this);
}

@JsonSerializable()
class AttributeIdentifier {
  AttributeIdentifier({this.type, this.credentialHash});

  @JsonKey(name: 'Type')
  String type;

  @JsonKey(name: 'CredentialHash')
  String credentialHash;

  factory AttributeIdentifier.fromJson(Map<String, dynamic> json) => _$AttributeIdentifierFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeIdentifierToJson(this);

  AttributeIdentifier.fromAttribute(Attribute attribute) {
    type = attribute.attributeType.fullId;
    credentialHash = attribute.credentialHash;
  }
}

class CredentialAttribute extends Attribute {
  final Credential credential;

  @override
  final bool notRevokable;

  CredentialAttribute({
    @required this.credential,
    @required AttributeType attributeType,
    @required AttributeValue value,
    @required this.notRevokable,
  })  : assert(credential != null),
        super(credentialInfo: credential.info, attributeType: attributeType, value: value);

  @override
  bool get expired => credential.expired;
  @override
  bool get revoked => credential.revoked;
  @override
  bool get choosable => !notRevokable && !expired && !revoked;
  @override
  String get credentialHash => credential.hash;
}

class Attribute {
  final CredentialInfo credentialInfo;
  final AttributeType attributeType;
  final AttributeValue value;

  Attribute({
    @required this.credentialInfo,
    @required this.attributeType,
    @required this.value,
  })  : assert(credentialInfo != null),
        assert(attributeType != null),
        assert(value != null);

  bool get expired => false;
  bool get revoked => false;
  bool get notRevokable => false;
  bool get choosable => false;
  String get credentialHash => "";

  factory Attribute.fromCandidate(
      IrmaConfiguration irmaConfiguration, Credentials credentials, DisclosureCandidate candidate) {
    final attributeType = irmaConfiguration.attributeTypes[candidate.type];
    final credential = credentials[candidate.credentialHash];
    if (candidate.credentialHash != null && candidate.credentialHash != "") {
      final value = credential.attributes[attributeType];
      return CredentialAttribute(
        credential: credential,
        attributeType: attributeType,
        notRevokable: candidate.notRevokable,
        value: value,
      );
    } else {
      return Attribute(
        credentialInfo: CredentialInfo.fromConfiguration(
          irmaConfiguration: irmaConfiguration,
          credentialIdentifier: candidate.type,
        ),
        attributeType: attributeType,
        value: NullValue(),
      );
    }
  }

  factory Attribute.fromDisclosedAttribute(IrmaConfiguration irmaConfiguration, DisclosedAttribute disclosedAttribute) {
    final attributeType = irmaConfiguration.attributeTypes[disclosedAttribute.identifier];
    return Attribute(
      credentialInfo: CredentialInfo.fromConfiguration(
        irmaConfiguration: irmaConfiguration,
        credentialIdentifier: disclosedAttribute.identifier,
      ),
      attributeType: attributeType,
      value: AttributeValue.fromRaw(attributeType, disclosedAttribute.value),
    );
  }
}

@JsonSerializable(nullable: false)
class DisclosedAttribute {
  const DisclosedAttribute({
    this.rawValue,
    this.value,
    this.identifier,
    this.status,
    this.issuanceTime,
  });

  @JsonKey(name: 'rawValue')
  final String rawValue;

  @JsonKey(name: 'value')
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
  DisclosureCandidate({this.type, this.credentialHash, this.notRevokable});

  @JsonKey(name: 'Type')
  String type;

  @JsonKey(name: 'CredentialHash')
  String credentialHash;

  @JsonKey(name: 'NotRevokable')
  bool notRevokable;

  factory DisclosureCandidate.fromJson(Map<String, dynamic> json) => _$DisclosureCandidateFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosureCandidateToJson(this);
}
