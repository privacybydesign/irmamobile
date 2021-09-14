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

IrmaConfiguration _$IrmaConfigurationFromJson(Map<String, dynamic> json) {
  return IrmaConfiguration(
    schemeManagers: (json['SchemeManagers'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, SchemeManager.fromJson(e as Map<String, dynamic>)),
    ),
    requestorSchemes: (json['RequestorSchemes'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, RequestorScheme.fromJson(e as Map<String, dynamic>)),
    ),
    requestors: (json['Requestors'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, RequestorInfo.fromJson(e as Map<String, dynamic>)),
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
    issueWizards: (json['IssueWizards'] as Map<String, dynamic>).map(
      (k, e) => MapEntry(k, IssueWizard.fromJson(e as Map<String, dynamic>)),
    ),
    path: json['Path'] as String,
  );
}

SchemeManager _$SchemeManagerFromJson(Map<String, dynamic> json) {
  return SchemeManager(
    id: json['ID'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
    url: json['URL'] as String,
    description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>?),
    minimumAppVersion: AppVersion.fromJson(json['MinimumAppVersion'] as Map<String, dynamic>),
    keyshareServer: json['KeyshareServer'] as String,
    keyshareWebsite: json['KeyshareWebsite'] as String,
    keyshareAttribute: json['KeyshareAttribute'] as String,
    timestamp: json['Timestamp'] as int,
  );
}

RequestorScheme _$RequestorSchemeFromJson(Map<String, dynamic> json) {
  return RequestorScheme(
    id: json['id'] as String,
    demo: json['demo'] as bool,
  );
}

Map<String, dynamic> _$RequestorSchemeToJson(RequestorScheme instance) => <String, dynamic>{
      'id': instance.id,
      'demo': instance.demo,
    };

AppVersion _$AppVersionFromJson(Map<String, dynamic> json) {
  return AppVersion(
    android: json['Android'] as int,
    iOS: json['IOS'] as int,
  );
}

Issuer _$IssuerFromJson(Map<String, dynamic> json) {
  return Issuer(
    id: json['ID'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
    schemeManagerId: json['SchemeManagerID'] as String,
    contactAddress: json['ContactAddress'] as String,
    contactEmail: json['ContactEmail'] as String,
  );
}

CredentialType _$CredentialTypeFromJson(Map<String, dynamic> json) {
  return CredentialType(
    id: json['ID'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
    issuerId: json['IssuerID'] as String,
    schemeManagerId: json['SchemeManagerID'] as String,
    isSingleton: json['IsSingleton'] as bool,
    description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>?),
    issueUrl: TranslatedValue.fromJson(json['IssueURL'] as Map<String, dynamic>?),
    isULIssueUrl: json['IsULIssueURL'] as bool?,
    disallowDelete: json['DisallowDelete'] as bool? ?? false,
    foregroundColor: colorFromCode(json['ForegroundColor'] as String?),
    backgroundGradientStart: colorFromCode(json['BackgroundGradientStart'] as String?),
    backgroundGradientEnd: colorFromCode(json['BackgroundGradientEnd'] as String?),
    isInCredentialStore: json['IsInCredentialStore'] as bool? ?? false,
    category: TranslatedValue.fromJson(json['Category'] as Map<String, dynamic>?),
    faqIntro: TranslatedValue.fromJson(json['FAQIntro'] as Map<String, dynamic>?),
    faqPurpose: TranslatedValue.fromJson(json['FAQPurpose'] as Map<String, dynamic>?),
    faqContent: TranslatedValue.fromJson(json['FAQContent'] as Map<String, dynamic>?),
    faqHowto: TranslatedValue.fromJson(json['FAQHowto'] as Map<String, dynamic>?),
    faqSummary: TranslatedValue.fromJson(json['FAQSummary'] as Map<String, dynamic>?),
    logo: json['Logo'] as String,
  );
}

AttributeType _$AttributeTypeFromJson(Map<String, dynamic> json) {
  return AttributeType(
    id: json['ID'] as String,
    index: json['Index'] as int,
    credentialTypeId: json['CredentialTypeID'] as String,
    issuerId: json['IssuerID'] as String,
    schemeManagerId: json['SchemeManagerID'] as String,
    name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
    description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>?),
    optional: AttributeType._parseOptional(json['Optional'] as String?),
    displayIndex: json['DisplayIndex'] as int?,
    displayHint: json['DisplayHint'] as String?,
  );
}
