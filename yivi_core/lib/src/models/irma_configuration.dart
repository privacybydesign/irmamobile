import "package:json_annotation/json_annotation.dart";

import "event.dart";
import "issue_wizard.dart";
import "session.dart";
import "translated_value.dart";

part "irma_configuration.g.dart";

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class IrmaConfigurationEvent extends Event {
  IrmaConfigurationEvent({required this.irmaConfiguration});

  final IrmaConfiguration irmaConfiguration;

  factory IrmaConfigurationEvent.fromJson(Map<String, dynamic> json) =>
      _$IrmaConfigurationEventFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
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

  final Map<String, SchemeManager> schemeManagers;

  final Map<String, RequestorScheme> requestorSchemes;

  final Map<String, RequestorInfo> requestors;

  final Map<String, Issuer> issuers;

  final Map<String, CredentialType> credentialTypes;

  final Map<String, AttributeType> attributeTypes;

  final Map<String, IssueWizard> issueWizards;

  final String path;

  factory IrmaConfiguration.fromJson(Map<String, dynamic> json) =>
      _$IrmaConfigurationFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SchemeManager {
  SchemeManager({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.minimumAppVersion,
    required this.keyshareServer,
    required this.keyshareWebsite,
    required this.timestampServer,
    @Deprecated("Use keyshareAttributes instead")
    required this.keyshareAttribute,
    required this.timestamp,
    required this.demo,
  });

  final String id;

  final TranslatedValue name;

  final String url;

  final TranslatedValue description;

  final AppVersion minimumAppVersion;

  final String keyshareServer;

  final String keyshareWebsite;

  @Deprecated("Use keyshareAttributes instead")
  final String keyshareAttribute;

  final String timestampServer;

  final int timestamp;

  final bool demo;

  factory SchemeManager.fromJson(Map<String, dynamic> json) =>
      _$SchemeManagerFromJson(json);

  // In the pbdf scheme, not all keyshare attributes are mentioned. Therefore, we hardcode them for now.
  // This should be fixed in the scheme description.
  Iterable<String> get keyshareAttributes => {
    keyshareAttribute,
    if (id == "pbdf") ...[
      "pbdf.sidn-pbdf.irma.pseudonym",
      "pbdf.pbdf.mijnirma.email",
    ],
  };
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RequestorScheme {
  RequestorScheme({required this.id, required this.demo});

  final String id;

  final bool demo;

  factory RequestorScheme.fromJson(Map<String, dynamic> json) =>
      _$RequestorSchemeFromJson(json);
  Map<String, dynamic> toJson() => _$RequestorSchemeToJson(this);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class AppVersion {
  AppVersion({required this.android, required this.iOS});

  final int android;

  @JsonKey(name: "ios")
  final int iOS;

  factory AppVersion.fromJson(Map<String, dynamic> json) =>
      _$AppVersionFromJson(json);
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class Issuer {
  Issuer({
    required this.id,
    required this.name,
    required this.schemeManagerId,
    required this.contactAddress,
    required this.contactEmail,
  });

  final String id;

  final TranslatedValue name;

  final String schemeManagerId;

  final String contactAddress;

  final String contactEmail;

  factory Issuer.fromJson(Map<String, dynamic> json) => _$IssuerFromJson(json);

  String get fullId => "$schemeManagerId.$id";
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
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
    this.isInCredentialStore = false,
    this.category = const TranslatedValue.empty(),
    this.faqIntro = const TranslatedValue.empty(),
    this.faqPurpose = const TranslatedValue.empty(),
    this.faqContent = const TranslatedValue.empty(),
    this.faqHowto = const TranslatedValue.empty(),
    this.faqSummary = const TranslatedValue.empty(),
    this.logo,
  });

  final String id;

  final TranslatedValue name;

  final String issuerId;

  final String schemeManagerId;

  final bool isSingleton;

  final TranslatedValue description;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue issueUrl;

  @JsonKey(name: "is_ul_issue_url")
  final bool isULIssueUrl;

  final bool disallowDelete;

  final bool isInCredentialStore;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue category;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqIntro;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqPurpose;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqContent;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqHowto;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue faqSummary;

  final String? logo;

  factory CredentialType.fromJson(Map<String, dynamic> json) =>
      _$CredentialTypeFromJson(json);

  String get fullId => "$schemeManagerId.$issuerId.$id";
  String get fullIssuerId => "$schemeManagerId.$issuerId";
  bool get obtainable => issueUrl.isNotEmpty;
}

@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
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

  final String id;

  @JsonKey(fromJson: _parseOptional)
  final bool optional;

  // In case of revocation attributes, Name and Description are not present
  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue name;

  // Default value is set by fromJson of TranslatedValue
  final TranslatedValue description;

  final int index;

  final int? displayIndex;

  final String? displayHint;

  final String credentialTypeId;

  final String issuerId;

  final String schemeManagerId;

  factory AttributeType.fromJson(Map<String, dynamic> json) =>
      _$AttributeTypeFromJson(json);

  String get fullId => "$schemeManagerId.$issuerId.$credentialTypeId.$id";
  String get fullCredentialId => "$schemeManagerId.$issuerId.$credentialTypeId";

  // Helpers for json annotation
  static bool _parseOptional(String? raw) =>
      raw != null && raw.toLowerCase() == "true";
}
