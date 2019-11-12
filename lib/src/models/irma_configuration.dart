import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'irma_configuration.g.dart';

// Template:
//
// @JsonSerializable(nullable: false)
// class Foobar {
//   Foobar({});

//   @JsonKey(name: 'omgwtf')
//   final  omgwtf;

//   factory Foobar.fromJson(Map<String, dynamic> json) => _$FoobarFromJson(json);
//   Map<String, dynamic> toJson() => _$FoobarToJson(this);
// }

// TODO: Change this to a RawIrmaConfiguration and create a typed
// IrmaConfiguration that makes use of DateTime and TranslatedValue (and more).
@JsonSerializable(nullable: false, explicitToJson: true)
class IrmaConfiguration with EquatableMixin {
  IrmaConfiguration({this.schemeManagers, this.issuers, this.credentialTypes, this.attributeTypes, this.path});

  @JsonKey(name: 'SchemeManagers')
  final Map<String, SchemeManager> schemeManagers;

  @JsonKey(name: 'Issuers')
  final Map<String, Issuer> issuers;

  @JsonKey(name: 'CredentialTypes')
  final Map<String, CredentialType> credentialTypes;

  @JsonKey(name: 'AttributeTypes')
  final Map<String, AttributeType> attributeTypes;

  @JsonKey(name: 'Path')
  final String path;

  factory IrmaConfiguration.fromJson(Map<String, dynamic> json) => _$IrmaConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$IrmaConfigurationToJson(this);

  IrmaConfiguration copyWith({
    Map<String, SchemeManager> schemeManagers,
    Map<String, Issuer> issuers,
    Map<String, CredentialType> credentialTypes,
    Map<String, AttributeType> attributeTypes,
    String path,
  }) {
    return IrmaConfiguration(
      schemeManagers: schemeManagers ?? this.schemeManagers,
      issuers: issuers ?? this.issuers,
      credentialTypes: credentialTypes ?? this.credentialTypes,
      attributeTypes: attributeTypes ?? this.attributeTypes,
      path: path ?? this.path,
    );
  }

  @override
  List<Object> get props {
    return [schemeManagers, issuers, credentialTypes, attributeTypes, path];
  }
}

@JsonSerializable(nullable: false, explicitToJson: true)
class SchemeManager {
  SchemeManager(
      {this.id,
      this.name,
      this.url,
      this.description,
      this.minimumAppVersion,
      this.keyshareServer,
      this.keyshareWebsite,
      this.keyshareAttribute,
      this.timestamp});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Name')
  final Map<String, String> name;

  @JsonKey(name: 'URL')
  final String url;

  @JsonKey(name: 'Description')
  final Map<String, String> description;

  @JsonKey(name: 'MinimumAppVersion')
  final AppVersion minimumAppVersion;

  @JsonKey(name: 'KeyshareServer')
  final String keyshareServer;

  @JsonKey(name: 'KeyshareWebsite')
  final String keyshareWebsite;

  @JsonKey(name: 'KeyshareAttribute')
  final String keyshareAttribute;

  @JsonKey(name: 'Timestamp')
  final int timestamp;

  factory SchemeManager.fromJson(Map<String, dynamic> json) => _$SchemeManagerFromJson(json);
  Map<String, dynamic> toJson() => _$SchemeManagerToJson(this);
}

@JsonSerializable(nullable: false)
class AppVersion {
  AppVersion({this.android, this.iOS});

  @JsonKey(name: 'Android')
  final int android;

  @JsonKey(name: 'IOS')
  final int iOS;

  factory AppVersion.fromJson(Map<String, dynamic> json) => _$AppVersionFromJson(json);
  Map<String, dynamic> toJson() => _$AppVersionToJson(this);
}

// TODO: move to a RawIssuer type and re-introduce the issuer type which has
// colors and backgrounds (not from irma scheme right now).
@JsonSerializable(nullable: false)
class Issuer {
  Issuer({this.id, this.name, this.shortName, this.schemeManagerId, this.contactAddress, this.contactEmail});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Name')
  final Map<String, String> name;

  @JsonKey(name: 'ShortName')
  final Map<String, String> shortName;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'ContactAddress')
  final String contactAddress;

  @JsonKey(name: 'ContactEmail')
  final String contactEmail;

  factory Issuer.fromJson(Map<String, dynamic> json) => _$IssuerFromJson(json);
  Map<String, dynamic> toJson() => _$IssuerToJson(this);
}

@JsonSerializable(nullable: false, explicitToJson: true)
class CredentialType {
  CredentialType(
      {this.id,
      this.name,
      this.shortName,
      this.issuerId,
      this.schemeManagerId,
      this.isSingleton,
      this.description,
      this.issueUrl});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Name')
  final Map<String, String> name;

  @JsonKey(name: 'ShortName')
  final Map<String, String> shortName;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'IsSingleton')
  final bool isSingleton;

  @JsonKey(name: 'Description')
  final Map<String, String> description;

  @JsonKey(name: 'IssueURL', nullable: true)
  final Map<String, String> issueUrl;

  factory CredentialType.fromJson(Map<String, dynamic> json) => _$CredentialTypeFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialTypeToJson(this);
}

// TODO: Change this to RawAttributeType and move to a new AttributeType that
// has TranslatedValues for `name` and `description`.
@JsonSerializable(nullable: false)
class AttributeType {
  AttributeType(
      {this.id,
      this.optional,
      this.name,
      this.description,
      this.index,
      this.displayIndex,
      this.credentialTypeId,
      this.issuerId,
      this.schemeManagerId});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Optional')
  final String optional;

  @JsonKey(name: 'Name')
  final Map<String, String> name;

  @JsonKey(name: 'Description')
  final Map<String, String> description;

  @JsonKey(name: 'Index')
  final int index;

  @JsonKey(name: 'DisplayIndex')
  final int displayIndex;

  @JsonKey(name: 'CredentialTypeID')
  final String credentialTypeId;

  @JsonKey(name: 'issuerId')
  final String issuerId;

  @JsonKey(name: 'schemeManagerId')
  final String schemeManagerId;

  factory AttributeType.fromJson(Map<String, dynamic> json) => _$AttributeTypeFromJson(json);
  Map<String, dynamic> toJson() => _$AttributeTypeToJson(this);
}
