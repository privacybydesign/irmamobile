import "package:json_annotation/json_annotation.dart";

import "event.dart";

part "scheme_events.g.dart";

@JsonSerializable(fieldRename: FieldRename.snake)
class InstallSchemeEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "InstallSchemeEvent";

  final String url;

  final String publicKey;

  InstallSchemeEvent({required this.url, required this.publicKey});

  factory InstallSchemeEvent.fromJson(Map<String, dynamic> json) =>
      _$InstallSchemeEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$InstallSchemeEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RemoveSchemeEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "RemoveSchemeEvent";

  final String schemeId;

  RemoveSchemeEvent({required this.schemeId});

  factory RemoveSchemeEvent.fromJson(Map<String, dynamic> json) =>
      _$RemoveSchemeEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RemoveSchemeEventToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RemoveRequestorSchemeEvent extends Event implements BridgeEvent {
  @override
  String get wireName => "RemoveRequestorSchemeEvent";

  final String schemeId;

  RemoveRequestorSchemeEvent({required this.schemeId});

  factory RemoveRequestorSchemeEvent.fromJson(Map<String, dynamic> json) =>
      _$RemoveRequestorSchemeEventFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$RemoveRequestorSchemeEventToJson(this);
}
