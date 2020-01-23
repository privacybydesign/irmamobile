import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'irma_configuration.g.dart';

@JsonSerializable(nullable: false, explicitToJson: true)
class IrmaConfigurationEvent extends Event {
  IrmaConfigurationEvent({this.irmaConfiguration});

  @JsonKey(name: 'IrmaConfiguration')
  final IrmaConfiguration irmaConfiguration;

  factory IrmaConfigurationEvent.fromJson(Map<String, dynamic> json) => _$IrmaConfigurationEventFromJson(json);
  Map<String, dynamic> toJson() => _$IrmaConfigurationEventToJson(this);
}

@JsonSerializable(nullable: false, explicitToJson: true)
class IrmaConfiguration {
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
  final TranslatedValue name;

  @JsonKey(name: 'URL')
  final String url;

  @JsonKey(name: 'Description')
  final TranslatedValue description;

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
  final TranslatedValue name;

  @JsonKey(name: 'ShortName')
  final TranslatedValue shortName;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'ContactAddress')
  final String contactAddress;

  @JsonKey(name: 'ContactEmail')
  final String contactEmail;

  factory Issuer.fromJson(Map<String, dynamic> json) => _$IssuerFromJson(json);
  Map<String, dynamic> toJson() => _$IssuerToJson(this);

  String get fullId => "$schemeManagerId.$id";
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
      this.issueUrl,
      this.backgroundColor,
      this.isInCredentialStore,
      this.category,
      this.faqIntro,
      this.faqPurpose,
      this.faqContent,
      this.faqHowto});

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Name')
  final TranslatedValue name;

  @JsonKey(name: 'ShortName')
  final TranslatedValue shortName;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'IsSingleton')
  final bool isSingleton;

  @JsonKey(name: 'Description')
  final TranslatedValue description;

  @JsonKey(name: 'IssueURL', nullable: true)
  final TranslatedValue issueUrl;

  @JsonKey(name: 'BackgroundColor', nullable: true)
  final String backgroundColor;

  @JsonKey(name: 'IsInCredentialStore', nullable: true)
  final bool isInCredentialStore;

  @JsonKey(name: 'Category', nullable: true)
  final TranslatedValue category;

  @JsonKey(name: 'FAQIntro', nullable: true)
  final TranslatedValue faqIntro;

  @JsonKey(name: 'FAQPurpose', nullable: true)
  final TranslatedValue faqPurpose;

  @JsonKey(name: 'FAQContent', nullable: true)
  final TranslatedValue faqContent;

  @JsonKey(name: 'FAQHowto', nullable: true)
  final TranslatedValue faqHowto;

  factory CredentialType.fromJson(Map<String, dynamic> json) => _$CredentialTypeFromJson(json);
  Map<String, dynamic> toJson() => _$CredentialTypeToJson(this);

  String get fullId => "$schemeManagerId.$issuerId.$id";
  String get fullIssuerId => "$schemeManagerId.$issuerId";

  String logoPath(String irmaConfigurationPath) {
    return "$irmaConfigurationPath/$schemeManagerId/$issuerId/Issues/$id/logo.png";
  }
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
  final TranslatedValue name;

  @JsonKey(name: 'Description')
  final TranslatedValue description;

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
