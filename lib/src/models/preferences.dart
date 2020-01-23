import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:json_annotation/json_annotation.dart';

part 'preferences.g.dart';

@JsonSerializable()
class Preferences {
  @JsonKey(name: "EnableCrashReporting")
  final bool enableCrashReporting;

  @JsonKey(name: "QrScannerOnStartup")
  final bool qrScannerOnStartup;

  const Preferences({@required this.enableCrashReporting, @required this.qrScannerOnStartup});

  factory Preferences.fromJson(Map<String, dynamic> json) => _$PreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$PreferencesToJson(this);
}

@JsonSerializable()
class PreferencesEvent extends Event {
  PreferencesEvent({this.preferences});

  @JsonKey(name: 'Preferences')
  Preferences preferences;

  factory PreferencesEvent.fromJson(Map<String, dynamic> json) => _$PreferencesEventFromJson(json);
  Map<String, dynamic> toJson() => _$PreferencesEventToJson(this);
}
