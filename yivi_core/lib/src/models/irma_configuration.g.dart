// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'irma_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IrmaConfigurationEvent _$IrmaConfigurationEventFromJson(
  Map<String, dynamic> json,
) => IrmaConfigurationEvent(
  irmaConfiguration: IrmaConfiguration.fromJson(
    json['irma_configuration'] as Map<String, dynamic>,
  ),
);

IrmaConfiguration _$IrmaConfigurationFromJson(Map<String, dynamic> json) =>
    IrmaConfiguration(
      schemeManagers: (json['scheme_managers'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, SchemeManager.fromJson(e as Map<String, dynamic>)),
      ),
      requestorSchemes: (json['requestor_schemes'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RequestorScheme.fromJson(e as Map<String, dynamic>)),
      ),
      requestors: (json['requestors'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RequestorInfo.fromJson(e as Map<String, dynamic>)),
      ),
      issuers: (json['issuers'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, Issuer.fromJson(e as Map<String, dynamic>)),
      ),
      credentialTypes: (json['credential_types'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, CredentialType.fromJson(e as Map<String, dynamic>)),
      ),
      attributeTypes: (json['attribute_types'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, AttributeType.fromJson(e as Map<String, dynamic>)),
      ),
      issueWizards: (json['issue_wizards'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, IssueWizard.fromJson(e as Map<String, dynamic>)),
      ),
      path: json['path'] as String,
    );

SchemeManager _$SchemeManagerFromJson(Map<String, dynamic> json) =>
    SchemeManager(
      id: json['id'] as String,
      name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
      url: json['url'] as String,
      description: TranslatedValue.fromJson(
        json['description'] as Map<String, dynamic>?,
      ),
      minimumAppVersion: AppVersion.fromJson(
        json['minimum_app_version'] as Map<String, dynamic>,
      ),
      keyshareServer: json['keyshare_server'] as String,
      keyshareWebsite: json['keyshare_website'] as String,
      timestampServer: json['timestamp_server'] as String,
      keyshareAttribute: json['keyshare_attribute'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      demo: json['demo'] as bool,
    );

RequestorScheme _$RequestorSchemeFromJson(Map<String, dynamic> json) =>
    RequestorScheme(id: json['id'] as String, demo: json['demo'] as bool);

Map<String, dynamic> _$RequestorSchemeToJson(RequestorScheme instance) =>
    <String, dynamic>{'id': instance.id, 'demo': instance.demo};

AppVersion _$AppVersionFromJson(Map<String, dynamic> json) => AppVersion(
  android: (json['android'] as num).toInt(),
  iOS: (json['ios'] as num).toInt(),
);

Issuer _$IssuerFromJson(Map<String, dynamic> json) => Issuer(
  id: json['id'] as String,
  name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
  schemeManagerId: json['scheme_manager_id'] as String,
  contactAddress: json['contact_address'] as String,
  contactEmail: json['contact_email'] as String,
);

CredentialType _$CredentialTypeFromJson(
  Map<String, dynamic> json,
) => CredentialType(
  id: json['id'] as String,
  name: TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
  issuerId: json['issuer_id'] as String,
  schemeManagerId: json['scheme_manager_id'] as String,
  isSingleton: json['is_singleton'] as bool,
  description: TranslatedValue.fromJson(
    json['description'] as Map<String, dynamic>?,
  ),
  issueUrl: json['issue_url'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['issue_url'] as Map<String, dynamic>?),
  isULIssueUrl: json['is_ul_issue_url'] as bool? ?? false,
  disallowDelete: json['disallow_delete'] as bool? ?? false,
  isInCredentialStore: json['is_in_credential_store'] as bool? ?? false,
  category: json['category'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['category'] as Map<String, dynamic>?),
  faqIntro: json['faq_intro'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['faq_intro'] as Map<String, dynamic>?),
  faqPurpose: json['faq_purpose'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['faq_purpose'] as Map<String, dynamic>?),
  faqContent: json['faq_content'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['faq_content'] as Map<String, dynamic>?),
  faqHowto: json['faq_howto'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['faq_howto'] as Map<String, dynamic>?),
  faqSummary: json['faq_summary'] == null
      ? const TranslatedValue.empty()
      : TranslatedValue.fromJson(json['faq_summary'] as Map<String, dynamic>?),
  logo: json['logo'] as String?,
);

AttributeType _$AttributeTypeFromJson(Map<String, dynamic> json) =>
    AttributeType(
      id: json['id'] as String,
      index: (json['index'] as num).toInt(),
      credentialTypeId: json['credential_type_id'] as String,
      issuerId: json['issuer_id'] as String,
      schemeManagerId: json['scheme_manager_id'] as String,
      name: json['name'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(json['name'] as Map<String, dynamic>?),
      description: json['description'] == null
          ? const TranslatedValue.empty()
          : TranslatedValue.fromJson(
              json['description'] as Map<String, dynamic>?,
            ),
      optional: json['optional'] == null
          ? false
          : AttributeType._parseOptional(json['optional'] as String?),
      displayIndex: (json['display_index'] as num?)?.toInt(),
      displayHint: json['display_hint'] as String?,
    );
