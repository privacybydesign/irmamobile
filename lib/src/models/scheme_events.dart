import 'package:json_annotation/json_annotation.dart';

import 'event.dart';

part 'scheme_events.g.dart';

@JsonSerializable()
class InstallSchemeEvent extends Event {
  @JsonKey(name: 'URL')
  final String url;

  @JsonKey(name: 'PublicKey')
  final String publicKey;

  InstallSchemeEvent({required this.url, required this.publicKey});

  factory InstallSchemeEvent.fromJson(Map<String, dynamic> json) => _$InstallSchemeEventFromJson(json);
  Map<String, dynamic> toJson() => _$InstallSchemeEventToJson(this);
}

@JsonSerializable()
class RemoveSchemeEvent extends Event {
  @JsonKey(name: 'SchemeID')
  final String schemeId;

  RemoveSchemeEvent({required this.schemeId});

  factory RemoveSchemeEvent.fromJson(Map<String, dynamic> json) => _$RemoveSchemeEventFromJson(json);
  Map<String, dynamic> toJson() => _$RemoveSchemeEventToJson(this);
}
