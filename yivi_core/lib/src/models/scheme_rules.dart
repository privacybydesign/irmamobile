import "package:flutter/foundation.dart" show TargetPlatform;
import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "scheme_rules.g.dart";

/// What the app needs from the schemes, sent by the bridge at start and after
/// every scheme change: the lowest app build they accept, and the credential
/// types whose issue URL is a universal link (opened by the OS, which may hand
/// it to a registered app).
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class SchemeRulesEvent extends Event {
  SchemeRulesEvent({
    required this.minimumAppVersion,
    required this.ulIssueCredentialIds,
  });

  final AppVersion minimumAppVersion;

  final Set<String> ulIssueCredentialIds;

  factory SchemeRulesEvent.fromJson(Map<String, dynamic> json) =>
      _$SchemeRulesEventFromJson(json);
}

/// An app build number per platform.
@JsonSerializable(createToJson: false)
class AppVersion {
  AppVersion({required this.android, required this.ios});

  final int android;

  final int ios;

  /// The build for [platform]; 0 off Android and iOS.
  int forPlatform(TargetPlatform platform) => switch (platform) {
    TargetPlatform.android => android,
    TargetPlatform.iOS => ios,
    _ => 0,
  };

  factory AppVersion.fromJson(Map<String, dynamic> json) =>
      _$AppVersionFromJson(json);
}
