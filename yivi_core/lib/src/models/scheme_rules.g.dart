// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheme_rules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchemeRulesEvent _$SchemeRulesEventFromJson(Map<String, dynamic> json) =>
    SchemeRulesEvent(
      minimumAppVersion: AppVersion.fromJson(
        json['minimum_app_version'] as Map<String, dynamic>,
      ),
      ulIssueCredentialIds: (json['ul_issue_credential_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
    );

AppVersion _$AppVersionFromJson(Map<String, dynamic> json) => AppVersion(
  android: (json['android'] as num).toInt(),
  ios: (json['ios'] as num).toInt(),
);
