// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogsEvent _$LogsEventFromJson(Map<String, dynamic> json) => LogsEvent(
  logEntries: (json['LogEntries'] as List<dynamic>).map((e) => LogEntry.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$LoadLogsEventToJson(LoadLogsEvent instance) => <String, dynamic>{
  'Before': instance.before,
  'Max': instance.max,
};

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) => LogEntry(
  id: (json['ID'] as num).toInt(),
  type: _toLogEntryType(json['Type'] as String),
  time: _epochSecondsToDateTime((json['Time'] as num).toInt()),
  issuedCredentials: (json['IssuedCredentials'] as List<dynamic>)
      .map((e) => RawCredential.fromJson(e as Map<String, dynamic>))
      .toList(),
  disclosedAttributes: (json['DisclosedCredentials'] as List<dynamic>)
      .map((e) => (e as List<dynamic>).map((e) => DisclosedAttribute.fromJson(e as Map<String, dynamic>)).toList())
      .toList(),
  removedCredentials: (json['RemovedCredentials'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      (e as Map<String, dynamic>).map((k, e) => MapEntry(k, TranslatedValue.fromJson(e as Map<String, dynamic>?))),
    ),
  ),
  serverName: json['ServerName'] == null ? null : RequestorInfo.fromJson(json['ServerName'] as Map<String, dynamic>),
  signedMessage: json['SignedMessage'] == null
      ? null
      : SignedMessage.fromJson(json['SignedMessage'] as Map<String, dynamic>),
);

SignedMessage _$SignedMessageFromJson(Map<String, dynamic> json) => SignedMessage(message: json['message'] as String);

Map<String, dynamic> _$SignedMessageToJson(SignedMessage instance) => <String, dynamic>{'message': instance.message};
