import 'package:equatable/equatable.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential.g.dart';

@JsonSerializable(nullable: false)
class Credential extends Equatable {
  Credential({this.id, this.issuerId, this.schemeManagerId, this.signedOn, this.expires, this.attributes, this.hash});

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
  final Map<String, Map<String, String>> attributes;

  @JsonKey(name: 'Hash')
  final String hash;

  factory Credential.fromJson(Map<String, dynamic> json) => _$CredentialFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialToJson(this);

  String get fullIssuerId => "$schemeManagerId.$issuerId";
  String get fullId => "$fullIssuerId.$id";

  @override
  List<Object> get props {
    return null;
  }
}

class RichCredential with EquatableMixin {
  final SchemeManager schemeManager;
  final Issuer issuer;
  final CredentialType credentialType;

  final String id;
  final int signedOn;
  final int expires;
  final List<RichAttribute> attributes;

  RichCredential({IrmaConfiguration irmaConfiguration, Credential credential})
      : schemeManager = irmaConfiguration.schemeManagers[credential.schemeManagerId],
        issuer = irmaConfiguration.issuers[credential.fullIssuerId],
        credentialType = irmaConfiguration.credentialTypes[credential.fullId],
        id = credential.id,
        signedOn = credential.signedOn,
        expires = credential.expires,
        attributes = credential.attributes.entries
            .map((entry) =>
                RichAttribute(irmaConfiguration: irmaConfiguration, fullAttributeId: entry.key, value: entry.value))
            .toList();

  @override
  List<Object> get props {
    return null;
  }
}

class RichAttribute with EquatableMixin {
  final AttributeType type;
  final Map<String, String> value;

  RichAttribute({IrmaConfiguration irmaConfiguration, String fullAttributeId, this.value})
      : type = irmaConfiguration.attributeTypes[fullAttributeId];

  @override
  List<Object> get props {
    return null;
  }
}
