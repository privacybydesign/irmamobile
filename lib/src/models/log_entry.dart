import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/event.dart';
import 'package:irmamobile/src/models/translated_value.dart';
import 'package:json_annotation/json_annotation.dart';

import 'disclosed_attribute.dart';

part 'log_entry.g.dart';

@JsonSerializable()
class LogsEvent extends Event {
  LogsEvent({this.logEntries});

  @JsonKey(name: 'LogEntries')
  final List<LogEntry> logEntries;

  factory LogsEvent.fromJson(Map<String, dynamic> json) => _$LogsEventFromJson(json);
  Map<String, dynamic> toJson() => _$LogsEventToJson(this);
}

@JsonSerializable()
class LoadLogsEvent extends Event {
  LoadLogsEvent({this.before = 0, this.max});

  @JsonKey(name: 'Before')
  final int before;

  @JsonKey(name: 'Max')
  final int max;

  factory LoadLogsEvent.fromJson(Map<String, dynamic> json) => _$LoadLogsEventFromJson(json);
  Map<String, dynamic> toJson() => _$LoadLogsEventToJson(this);
}

@JsonSerializable()
class LogEntry {
  const LogEntry(
      {this.id,
      this.type,
      this.time,
      this.serverName,
      this.issuedCredentials,
      this.disclosedAttributes,
      this.signedMessage,
      this.removedCredentials});

  @JsonKey(name: 'ID')
  final int id;

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'Time')
  final String time; // TODO: Shouldn't this be an int?

  @JsonKey(name: 'ServerName')
  final TranslatedValue serverName;

  @JsonKey(name: 'IssuedCredentials')
  final List<RawCredential> issuedCredentials;

  @JsonKey(name: 'DisclosedCredentials')
  final List<List<DisclosedAttribute>> disclosedAttributes;

  @JsonKey(name: 'SignedMessage')
  final String signedMessage;

  @JsonKey(name: 'RemovedCredentials')
  final Map<String, TranslatedValue> removedCredentials;

  factory LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LogEntryToJson(this);
}

@JsonSerializable()
class SignedMessage {
  SignedMessage({this.message, this.timestamp});

  @JsonKey(name: 'Message')
  final String message;

  @JsonKey(name: 'Timestamp')
  final int timestamp;

  factory SignedMessage.fromJson(Map<String, dynamic> json) => _$SignedMessageFromJson(json);
  Map<String, dynamic> toJson() => _$SignedMessageToJson(this);
}
