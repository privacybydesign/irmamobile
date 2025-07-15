// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'irma_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IrmaConfigurationEvent _$IrmaConfigurationEventFromJson(Map<String, dynamic> json) => IrmaConfigurationEvent(
  irmaConfiguration: IrmaConfiguration.fromJson(json['IrmaConfiguration'] as Map<String, dynamic>),
);

IrmaConfiguration _$IrmaConfigurationFromJson(Map<String, dynamic> json) => IrmaConfiguration(
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

SchemeManager _$SchemeManagerFromJson(Map<String, dynamic> json) => SchemeManager(
  id: json['ID'] as String,
  name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
  url: json['URL'] as String,
  description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>?),
  minimumAppVersion: AppVersion.fromJson(json['MinimumAppVersion'] as Map<String, dynamic>),
  keyshareServer: json['KeyshareServer'] as String,
  keyshareWebsite: json['KeyshareWebsite'] as String,
  timestampServer: json['TimestampServer'] as String,
  keyshareAttribute: json['KeyshareAttribute'] as String,
  timestamp: (json['Timestamp'] as num).toInt(),
  demo: json['Demo'] as bool,
);

RequestorScheme _$RequestorSchemeFromJson(Map<String, dynamic> json) =>
    RequestorScheme(id: json['id'] as String, demo: json['demo'] as bool);

Map<String, dynamic> _$RequestorSchemeToJson(RequestorScheme instance) => <String, dynamic>{
  'id': instance.id,
  'demo': instance.demo,
};

AppVersion _$AppVersionFromJson(Map<String, dynamic> json) =>
    AppVersion(android: (json['Android'] as num).toInt(), iOS: (json['IOS'] as num).toInt());

Issuer _$IssuerFromJson(Map<String, dynamic> json) => Issuer(
  id: json['ID'] as String,
  name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
  schemeManagerId: json['SchemeManagerID'] as String,
  contactAddress: json['ContactAddress'] as String,
  contactEmail: json['ContactEMail'] as String,
);

CredentialType _$CredentialTypeFromJson(Map<String, dynamic> json) => CredentialType(
  id: json['ID'] as String,
  name: TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
  issuerId: json['IssuerID'] as String,
  schemeManagerId: json['SchemeManagerID'] as String,
  isSingleton: json['IsSingleton'] as bool,
  description: TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>?),
  issueUrl: json['IssueURL'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['IssueURL'] as Map<String, dynamic>?),
  isULIssueUrl: json['IsULIssueURL'] as bool? ?? false,
  disallowDelete: json['DisallowDelete'] as bool? ?? false,
  isInCredentialStore: json['IsInCredentialStore'] as bool? ?? false,
  category: json['Category'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['Category'] as Map<String, dynamic>?),
  faqIntro: json['FAQIntro'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['FAQIntro'] as Map<String, dynamic>?),
  faqPurpose: json['FAQPurpose'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['FAQPurpose'] as Map<String, dynamic>?),
  faqContent: json['FAQContent'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['FAQContent'] as Map<String, dynamic>?),
  faqHowto: json['FAQHowto'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['FAQHowto'] as Map<String, dynamic>?),
  faqSummary: json['FAQSummary'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['FAQSummary'] as Map<String, dynamic>?),
  logo: json['Logo'] as String?,
);

AttributeType _$AttributeTypeFromJson(Map<String, dynamic> json) => AttributeType(
  id: json['ID'] as String,
  index: (json['Index'] as num).toInt(),
  credentialTypeId: json['CredentialTypeID'] as String,
  issuerId: json['IssuerID'] as String,
  schemeManagerId: json['SchemeManagerID'] as String,
  name: json['Name'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['Name'] as Map<String, dynamic>?),
  description: json['Description'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['Description'] as Map<String, dynamic>?),
  optional: json['Optional'] == null ? false : AttributeType._parseOptional(json['Optional'] as String?),
  displayIndex: (json['DisplayIndex'] as num?)?.toInt(),
  displayHint: json['DisplayHint'] as String?,
);
