// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'irma_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IrmaConfigurationEvent _$IrmaConfigurationEventFromJson(Map<String, dynamic> json) {
  return IrmaConfigurationEvent(
    irmaConfiguration: IrmaConfiguration.fromJson(json['IrmaConfiguration'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$IrmaConfigurationEventToJson(IrmaConfigurationEvent instance) => <String, dynamic>{
      'IrmaConfiguration': instance.irmaConfiguration,
    };

IrmaConfiguration _$IrmaConfigurationFromJson(Map<String, dynamic> json) {
  return IrmaConfiguration(
    schemeManagers: (json['SchemeManagers'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, SchemeManager.fromJson(e as Map<String, dynamic>)),
    ),
    issuers: (json['Issuers'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, Issuer.fromJson(e as Map<String, dynamic>)),
    ),
    credentialTypes: (json['CredentialTypes'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, CredentialType.fromJson(e as Map<String, dynamic>)),
    ),
    attributeTypes: (json['AttributeTypes'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, AttributeType.fromJson(e as Map<String, dynamic>)),
    ),
    path: json['Path'] as String,
  );
}

Map<String, dynamic> _$IrmaConfigurationToJson(IrmaConfiguration instance) => <String, dynamic>{
      'SchemeManagers': instance.schemeManagers,
      'Issuers': instance.issuers,
      'CredentialTypes': instance.credentialTypes,
      'AttributeTypes': instance.attributeTypes,
      'Path': instance.path,
    };

SchemeManager _$SchemeManagerFromJson(Map<String, dynamic> json) {
  return SchemeManager(
    id: json['ID'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>),
    url: json['URL'] as String,
    description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>),
    minimumAppVersion: AppVersion.fromJson(json['MinimumAppVersion'] as Map<String, dynamic>),
    keyshareServer: json['KeyshareServer'] as String,
    keyshareWebsite: json['KeyshareWebsite'] as String,
    keyshareAttribute: json['KeyshareAttribute'] as String,
    timestamp: json['Timestamp'] as int,
  );
}

Map<String, dynamic> _$SchemeManagerToJson(SchemeManager instance) => <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'URL': instance.url,
      'Description': instance.description,
      'MinimumAppVersion': instance.minimumAppVersion,
      'KeyshareServer': instance.keyshareServer,
      'KeyshareWebsite': instance.keyshareWebsite,
      'KeyshareAttribute': instance.keyshareAttribute,
      'Timestamp': instance.timestamp,
    };

AppVersion _$AppVersionFromJson(Map<String, dynamic> json) {
  return AppVersion(
    android: json['Android'] as int,
    iOS: json['IOS'] as int,
  );
}

Map<String, dynamic> _$AppVersionToJson(AppVersion instance) => <String, dynamic>{
      'Android': instance.android,
      'IOS': instance.iOS,
    };

Issuer _$IssuerFromJson(Map<String, dynamic> json) {
  return Issuer(
    id: json['ID'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>),
    shortName: TranslatedValue.fromJson(json['ShortName'] as Map<String, dynamic>),
    schemeManagerId: json['SchemeManagerID'] as String,
    contactAddress: json['ContactAddress'] as String,
    contactEmail: json['ContactEmail'] as String,
  );
}

Map<String, dynamic> _$IssuerToJson(Issuer instance) => <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'ShortName': instance.shortName,
      'SchemeManagerID': instance.schemeManagerId,
      'ContactAddress': instance.contactAddress,
      'ContactEmail': instance.contactEmail,
    };

CredentialType _$CredentialTypeFromJson(Map<String, dynamic> json) {
  return CredentialType(
    id: json['ID'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>),
    shortName: TranslatedValue.fromJson(json['ShortName'] as Map<String, dynamic>),
    issuerId: json['IssuerID'] as String,
    schemeManagerId: json['SchemeManagerID'] as String,
    isSingleton: json['IsSingleton'] as bool,
    description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>),
    issueUrl: json['IssueURL'] == null ? null : TranslatedValue.fromJson(json['IssueURL'] as Map<String, dynamic>),
    disallowDelete: json['DisallowDelete'] as bool,
    foregroundColor: _fromColorCode(json['ForegroundColor'] as String),
    backgroundGradientStart: _fromColorCode(json['BackgroundGradientStart'] as String),
    backgroundGradientEnd: _fromColorCode(json['BackgroundGradientEnd'] as String),
    isInCredentialStore: json['IsInCredentialStore'] as bool,
    category: json['Category'] == null ? null : TranslatedValue.fromJson(json['Category'] as Map<String, dynamic>),
    faqIntro: json['FAQIntro'] == null ? null : TranslatedValue.fromJson(json['FAQIntro'] as Map<String, dynamic>),
    faqPurpose:
        json['FAQPurpose'] == null ? null : TranslatedValue.fromJson(json['FAQPurpose'] as Map<String, dynamic>),
    faqContent:
        json['FAQContent'] == null ? null : TranslatedValue.fromJson(json['FAQContent'] as Map<String, dynamic>),
    faqHowto: json['FAQHowto'] == null ? null : TranslatedValue.fromJson(json['FAQHowto'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CredentialTypeToJson(CredentialType instance) => <String, dynamic>{
      'ID': instance.id,
      'Name': instance.name,
      'ShortName': instance.shortName,
      'IssuerID': instance.issuerId,
      'SchemeManagerID': instance.schemeManagerId,
      'IsSingleton': instance.isSingleton,
      'Description': instance.description,
      'IssueURL': instance.issueUrl,
      'DisallowDelete': instance.disallowDelete,
      'ForegroundColor': instance.foregroundColor,
      'BackgroundGradientStart': instance.backgroundGradientStart,
      'BackgroundGradientEnd': instance.backgroundGradientEnd,
      'IsInCredentialStore': instance.isInCredentialStore,
      'Category': instance.category,
      'FAQIntro': instance.faqIntro,
      'FAQPurpose': instance.faqPurpose,
      'FAQContent': instance.faqContent,
      'FAQHowto': instance.faqHowto,
    };

AttributeType _$AttributeTypeFromJson(Map<String, dynamic> json) {
  return AttributeType(
    id: json['ID'] as String,
    optional: json['Optional'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>),
    description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>),
    index: json['Index'] as int,
    displayIndex: json['DisplayIndex'] as int,
    displayHint: json['DisplayHint'] as String,
    credentialTypeId: json['CredentialTypeID'] as String,
    issuerId: json['IssuerID'] as String,
    schemeManagerId: json['SchemeManagerID'] as String,
  );
}

Map<String, dynamic> _$AttributeTypeToJson(AttributeType instance) => <String, dynamic>{
      'ID': instance.id,
      'Optional': instance.optional,
      'Name': instance.name,
      'Description': instance.description,
      'Index': instance.index,
      'DisplayIndex': instance.displayIndex,
      'DisplayHint': instance.displayHint,
      'CredentialTypeID': instance.credentialTypeId,
      'IssuerID': instance.issuerId,
      'SchemeManagerID': instance.schemeManagerId,
    };
