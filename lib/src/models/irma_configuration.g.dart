// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'irma_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
      'SchemeManagers': instance.schemeManagers.map((k, e) => MapEntry(k, e.toJson())),
      'Issuers': instance.issuers.map((k, e) => MapEntry(k, e.toJson())),
      'CredentialTypes': instance.credentialTypes.map((k, e) => MapEntry(k, e.toJson())),
      'AttributeTypes': instance.attributeTypes.map((k, e) => MapEntry(k, e.toJson())),
      'Path': instance.path,
    };

SchemeManager _$SchemeManagerFromJson(Map<String, dynamic> json) {
  return SchemeManager(
    id: json['ID'] as String,
    name: Map<String, String>.from(json['Name'] as Map),
    url: json['URL'] as String,
    description: Map<String, String>.from(json['Description'] as Map),
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
      'MinimumAppVersion': instance.minimumAppVersion.toJson(),
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
    name: Map<String, String>.from(json['Name'] as Map),
    shortName: Map<String, String>.from(json['ShortName'] as Map),
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
    name: Map<String, String>.from(json['Name'] as Map),
    shortName: Map<String, String>.from(json['ShortName'] as Map),
    issuerId: json['IssuerID'] as String,
    schemeManagerId: json['SchemeManagerID'] as String,
    isSingleton: json['IsSingleton'] as bool,
    description: Map<String, String>.from(json['Description'] as Map),
    issueUrl: (json['IssueURL'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
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
    };

AttributeType _$AttributeTypeFromJson(Map<String, dynamic> json) {
  return AttributeType(
    id: json['ID'] as String,
    optional: json['Optional'] as String,
    name: Map<String, String>.from(json['Name'] as Map),
    description: Map<String, String>.from(json['Description'] as Map),
    index: json['Index'] as int,
    displayIndex: json['DisplayIndex'] as int,
    credentialTypeId: json['CredentialTypeID'] as String,
    issuerId: json['issuerId'] as String,
    schemeManagerId: json['schemeManagerId'] as String,
  );
}

Map<String, dynamic> _$AttributeTypeToJson(AttributeType instance) => <String, dynamic>{
      'ID': instance.id,
      'Optional': instance.optional,
      'Name': instance.name,
      'Description': instance.description,
      'Index': instance.index,
      'DisplayIndex': instance.displayIndex,
      'CredentialTypeID': instance.credentialTypeId,
      'issuerId': instance.issuerId,
      'schemeManagerId': instance.schemeManagerId,
    };
