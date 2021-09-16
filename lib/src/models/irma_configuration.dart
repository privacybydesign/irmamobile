import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/issue_wizard.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:irmamobile/src/util/color_from_code.dart';
import 'package:json_annotation/json_annotation.dart';

part 'irma_configuration.g.dart';

@JsonSerializable(createToJson: false)
class IrmaConfigurationEvent extends Event {
  IrmaConfigurationEvent({required this.irmaConfiguration});

  @JsonKey(name: 'IrmaConfiguration')
  final IrmaConfiguration irmaConfiguration;

  factory IrmaConfigurationEvent.fromJson(Map<String, dynamic> json) => _$IrmaConfigurationEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class IrmaConfiguration {
  IrmaConfiguration({
    required this.schemeManagers,
    required this.requestorSchemes,
    required this.requestors,
    required this.issuers,
    required this.credentialTypes,
    required this.attributeTypes,
    required this.issueWizards,
    required this.path,
  });

  @JsonKey(name: 'SchemeManagers')
  final Map<String, SchemeManager> schemeManagers;

  @JsonKey(name: 'RequestorSchemes')
  final Map<String, RequestorScheme> requestorSchemes;

  @JsonKey(name: 'Requestors')
  final Map<String, RequestorInfo> requestors;

  @JsonKey(name: 'Issuers')
  final Map<String, Issuer> issuers;

  @JsonKey(name: 'CredentialTypes')
  final Map<String, CredentialType> credentialTypes;

  @JsonKey(name: 'AttributeTypes')
  final Map<String, AttributeType> attributeTypes;

  @JsonKey(name: 'IssueWizards')
  final Map<String, IssueWizard> issueWizards;

  @JsonKey(name: 'Path')
  final String path;

  factory IrmaConfiguration.fromJson(Map<String, dynamic> json) => _$IrmaConfigurationFromJson(json);
}

@JsonSerializable(createToJson: false)
class SchemeManager {
  SchemeManager({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.minimumAppVersion,
    required this.keyshareServer,
    required this.keyshareWebsite,
    required this.keyshareAttribute,
    required this.timestamp,
  });

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

@JsonSerializable()
class RequestorScheme {
  RequestorScheme({required this.id, required this.demo});

  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'demo')
  final bool demo;

  factory RequestorScheme.fromJson(Map<String, dynamic> json) => _$RequestorSchemeFromJson(json);
  Map<String, dynamic> toJson() => _$RequestorSchemeToJson(this);
}

@JsonSerializable(createToJson: false)
class AppVersion {
  AppVersion({required this.android, required this.iOS});

  @JsonKey(name: 'Android')
  final int android;

  @JsonKey(name: 'IOS')
  final int iOS;

  factory AppVersion.fromJson(Map<String, dynamic> json) => _$AppVersionFromJson(json);
}

@JsonSerializable(createToJson: false)
class Issuer {
  Issuer({
    required this.id,
    required this.name,
    required this.schemeManagerId,
    required this.contactAddress,
    required this.contactEmail,
  });

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Name')
  final TranslatedValue name;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'ContactAddress')
  final String contactAddress;

  @JsonKey(name: 'ContactEmail')
  final String contactEmail;

  factory Issuer.fromJson(Map<String, dynamic> json) => _$IssuerFromJson(json);

  String get fullId => '$schemeManagerId.$id';
}

@JsonSerializable(createToJson: false)
class CredentialType {
  CredentialType({
    required this.id,
    required this.name,
    required this.issuerId,
    required this.schemeManagerId,
    required this.isSingleton,
    required this.description,
    this.issueUrl = const TranslatedValue.empty(),
    this.isULIssueUrl = false,
    this.disallowDelete = false,
    this.foregroundColor,
    this.backgroundGradientStart,
    this.backgroundGradientEnd,
    this.isInCredentialStore = false,
    this.category = const TranslatedValue.empty(),
    this.faqIntro = const TranslatedValue.empty(),
    this.faqPurpose = const TranslatedValue.empty(),
    this.faqContent = const TranslatedValue.empty(),
    this.faqHowto = const TranslatedValue.empty(),
    this.faqSummary = const TranslatedValue.empty(),
    this.logo = '',
  });

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Name')
  final TranslatedValue name;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  @JsonKey(name: 'IsSingleton')
  final bool isSingleton;

  @JsonKey(name: 'Description')
  final TranslatedValue description;

  @JsonKey(name: 'IssueURL') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue issueUrl;

  @JsonKey(name: 'IsULIssueURL')
  final bool isULIssueUrl;

  @JsonKey(name: 'DisallowDelete', defaultValue: false)
  final bool disallowDelete;

  @JsonKey(name: 'ForegroundColor', fromJson: colorFromCode)
  final Color? foregroundColor;

  @JsonKey(name: 'BackgroundGradientStart', fromJson: colorFromCode)
  final Color? backgroundGradientStart;

  @JsonKey(name: 'BackgroundGradientEnd', fromJson: colorFromCode)
  final Color? backgroundGradientEnd;

  @JsonKey(name: 'IsInCredentialStore', defaultValue: false)
  final bool isInCredentialStore;

  @JsonKey(name: 'Category') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue category;

  @JsonKey(name: 'FAQIntro') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqIntro;

  @JsonKey(name: 'FAQPurpose') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqPurpose;

  @JsonKey(name: 'FAQContent') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqContent;

  @JsonKey(name: 'FAQHowto') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqHowto;

  @JsonKey(name: 'FAQSummary') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqSummary;

  /// When no logo is present, the empty string is used.
  @JsonKey(name: 'Logo')
  final String logo;

  factory CredentialType.fromJson(Map<String, dynamic> json) => _$CredentialTypeFromJson(json);

  String get fullId => '$schemeManagerId.$issuerId.$id';
  String get fullIssuerId => '$schemeManagerId.$issuerId';
}

@JsonSerializable(createToJson: false)
class AttributeType {
  AttributeType({
    required this.id,
    required this.index,
    required this.credentialTypeId,
    required this.issuerId,
    required this.schemeManagerId,
    this.name = const TranslatedValue.empty(),
    this.description = const TranslatedValue.empty(),
    this.optional = false,
    this.displayIndex,
    this.displayHint,
  });

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'Optional', fromJson: _parseOptional)
  final bool optional;

  // In case of revocation attributes, Name and Description are not present
  @JsonKey(name: 'Name') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue name;

  @JsonKey(name: 'Description') // Default value is set by fromJson of TranslatedValue
  final TranslatedValue description;

  @JsonKey(name: 'Index')
  final int index;

  @JsonKey(name: 'DisplayIndex')
  final int? displayIndex;

  @JsonKey(name: 'DisplayHint')
  final String? displayHint;

  @JsonKey(name: 'CredentialTypeID')
  final String credentialTypeId;

  @JsonKey(name: 'IssuerID')
  final String issuerId;

  @JsonKey(name: 'SchemeManagerID')
  final String schemeManagerId;

  factory AttributeType.fromJson(Map<String, dynamic> json) => _$AttributeTypeFromJson(json);

  String get fullId => '$schemeManagerId.$issuerId.$credentialTypeId.$id';
  String get fullCredentialId => '$schemeManagerId.$issuerId.$credentialTypeId';

  // Helpers for json annotation
  static bool _parseOptional(String? raw) => raw != null && raw.toLowerCase() == 'true';
}
