import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

part 'irma_configuration.g.dart';

@JsonSerializable(nullable: false, createToJson: false)
class IrmaConfigurationEvent extends Event {
  IrmaConfigurationEvent({this.irmaConfiguration});

  @JsonKey(name: 'IrmaConfiguration')
  final IrmaConfiguration irmaConfiguration;

  factory IrmaConfigurationEvent.fromJson(Map<String, dynamic> json) => _$IrmaConfigurationEventFromJson(json);
}

@JsonSerializable(nullable: false, createToJson: false)
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
}

@JsonSerializable(nullable: false, createToJson: false)
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
}

@JsonSerializable(nullable: false, createToJson: false)
class AppVersion {
  AppVersion({this.android, this.iOS});

  @JsonKey(name: 'Android')
  final int android;

  @JsonKey(name: 'IOS')
  final int iOS;

  factory AppVersion.fromJson(Map<String, dynamic> json) => _$AppVersionFromJson(json);
}

// TODO: move to a RawIssuer type and re-introduce the issuer type which has
// colors and backgrounds (not from irma scheme right now).
@JsonSerializable(nullable: false, createToJson: false)
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

  String get fullId => "$schemeManagerId.$id";

  String logoPath(String irmaConfigurationPath) {
    return "$irmaConfigurationPath/$schemeManagerId/$id/logo.png";
  }
}

@JsonSerializable(nullable: false, createToJson: false)
class CredentialType {
  CredentialType({
    this.id,
    this.name,
    this.shortName,
    this.issuerId,
    this.schemeManagerId,
    this.isSingleton,
    this.description,
    this.issueUrl,
    this.isULIssueUrl,
    this.disallowDelete,
    this.foregroundColor,
    this.backgroundGradientStart,
    this.backgroundGradientEnd,
    this.isInCredentialStore,
    this.category,
    this.faqIntro,
    this.faqPurpose,
    this.faqContent,
    this.faqHowto,
  });

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

  @JsonKey(name: 'IsULIssueURL', nullable: true)
  final bool isULIssueUrl;

  @JsonKey(name: 'DisallowDelete', nullable: true)
  final bool disallowDelete;

  @JsonKey(name: 'ForegroundColor', fromJson: _fromColorCode)
  final Color foregroundColor;

  @JsonKey(name: 'BackgroundGradientStart', fromJson: _fromColorCode)
  final Color backgroundGradientStart;

  @JsonKey(name: 'BackgroundGradientEnd', fromJson: _fromColorCode)
  final Color backgroundGradientEnd;

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

  String get fullId => "$schemeManagerId.$issuerId.$id";
  String get fullIssuerId => "$schemeManagerId.$issuerId";

  String logoPath(String irmaConfigurationPath) {
    return "$irmaConfigurationPath/$schemeManagerId/$issuerId/Issues/$id/logo.png";
  }
}

// TODO: Change this to RawAttributeType and move to a new AttributeType that
// has TranslatedValues for `name` and `description`.
@JsonSerializable(nullable: false, createToJson: false)
class AttributeType {
  AttributeType({
    this.id,
    this.optional,
    this.name,
    this.description,
    this.index,
    this.displayIndex,
    this.displayHint,
    this.credentialTypeId,
    this.issuerId,
    this.schemeManagerId,
  });

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Optional')
  final String optional;

  @JsonKey(name: 'Name', nullable: true)
  final TranslatedValue name;

  @JsonKey(name: 'Description', nullable: true)
  final TranslatedValue description;

  @JsonKey(name: 'Index')
  final int index;

  @JsonKey(name: 'DisplayIndex')
  final int displayIndex;

  @JsonKey(name: 'DisplayHint')
  final String displayHint;

  @JsonKey(name: 'CredentialTypeID')
  final String credentialTypeId;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  factory AttributeType.fromJson(Map<String, dynamic> json) => _$AttributeTypeFromJson(json);

  String get fullId => "$schemeManagerId.$issuerId.$credentialTypeId.$id";
  String get fullCredentialId => "$schemeManagerId.$issuerId.$credentialTypeId";
}

Color _fromColorCode(String colorCode) {
  if (colorCode == null || colorCode.length != 7 || colorCode[0] != "#") {
    return null;
  }

  final rgbInt = int.tryParse(colorCode.substring(1, 7), radix: 16);
  if (rgbInt == null) {
    return null;
  }

  const alphaInt = 0xFF000000;
  return Color(alphaInt + rgbInt);
}
