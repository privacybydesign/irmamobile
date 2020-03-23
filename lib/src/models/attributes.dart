import 'dart:collection';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attributes.g.dart';

Image _decodePortraitPhoto(TranslatedValue value) {
  try {
    return Image.memory(
      const Base64Decoder().convert(value.values.first),
    );
  } catch (_) {}

  return null;
}

// Attributes of a credential.
class Attributes extends UnmodifiableMapView<AttributeType, TranslatedValue> {
  List<AttributeType> sortedAttributeTypes;
  Image portraitPhoto;

  Attributes(Map<AttributeType, TranslatedValue> map)
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
      (at) => at.displayHint == "portraitPhoto",
      orElse: () => null,
    );

    if (photoAttributeType != null) {
      portraitPhoto = _decodePortraitPhoto(this[photoAttributeType]);
    }
  }

  factory Attributes.fromRaw({IrmaConfiguration irmaConfiguration, Map<String, TranslatedValue> rawAttributes}) {
    return Attributes(rawAttributes.map<AttributeType, TranslatedValue>((k, v) {
      return MapEntry(irmaConfiguration.attributeTypes[k], v);
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

  AttributeIdentifier.fromCredentialAttribute(CredentialAttribute credentialAttribute) {
    type = credentialAttribute.attributeType.fullId;
    credentialHash = credentialAttribute.credential.hash;
  }
}

class CredentialAttribute {
  final Credential credential;
  final AttributeType attributeType;
  final TranslatedValue value;
  final bool notRevokable;
  Image portraitPhoto;

  CredentialAttribute({
    @required this.credential,
    @required this.attributeType,
    @required this.value,
    @required this.notRevokable,
  })  : assert(credential != null),
        assert(attributeType != null),
        assert(value != null),
        assert(notRevokable != null) {
    if (attributeType.displayHint == "portraitPhoto") {
      portraitPhoto = _decodePortraitPhoto(value);
    }
  }

  factory CredentialAttribute.fromDisclosureCandidate(
      IrmaConfiguration irmaConfiguration, Credentials credentials, DisclosureCandidate candidate) {
    final hash = candidate.credentialHash;
    final type = candidate.type;
    final attributeType = irmaConfiguration.attributeTypes[type];
    final credential = hash != ""
        ? credentials[hash]
        : Credential.fromId(irmaConfiguration: irmaConfiguration, id: type.substring(0, type.lastIndexOf(".")));
    final value = hash == "" ? TranslatedValue({"en": "-", "nl": "-"}) : credential.attributes[attributeType];

    return CredentialAttribute(
        credential: credential, attributeType: attributeType, value: value, notRevokable: candidate.notRevokable);
  }
}

@JsonSerializable()
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
  DisclosureCandidate({this.type, this.credentialHash, this.expired, this.revoked, this.notRevokable});

  @JsonKey(name: 'Type')
  String type;

  @JsonKey(name: 'CredentialHash')
  String credentialHash;

  @JsonKey(name: 'Expired')
  bool expired;

  @JsonKey(name: 'Revoked')
  bool revoked;

  @JsonKey(name: 'NotRevokable')
  bool notRevokable;

  factory DisclosureCandidate.fromJson(Map<String, dynamic> json) => _$DisclosureCandidateFromJson(json);
  Map<String, dynamic> toJson() => _$DisclosureCandidateToJson(this);
}
