// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogsEvent _$LogsEventFromJson(Map<String, dynamic> json) {
  return LogsEvent(
    logEntries: (json['LogEntries'] as List)
        ?.map((e) => e == null ? null : LogEntry.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$LogsEventToJson(LogsEvent instance) => <String, dynamic>{
      'LogEntries': instance.logEntries,
    };

LoadLogsEvent _$LoadLogsEventFromJson(Map<String, dynamic> json) {
  return LoadLogsEvent(
    before: json['Before'] as int,
    max: json['Max'] as int,
  );
}

Map<String, dynamic> _$LoadLogsEventToJson(LoadLogsEvent instance) => <String, dynamic>{
      'Before': instance.before,
      'Max': instance.max,
    };

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) {
  return LogEntry(
    id: json['ID'] as int,
    type: json['Type'] as String,
    time: json['Time'] as String,
    serverName:
        json['ServerName'] == null ? null : TranslatedValue.fromJson(json['ServerName'] as Map<String, dynamic>),
    issuedCredentials: (json['IssuedCredentials'] as List)
        ?.map((e) => e == null ? null : RawCredential.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    disclosedAttributes: (json['DisclosedCredentials'] as List)
        ?.map((e) => (e as List)
            ?.map((e) => e == null ? null : DisclosedAttribute.fromJson(e as Map<String, dynamic>))
            ?.toList())
        ?.toList(),
    signedMessage: json['SignedMessage'] as String,
    removedCredentials: (json['RemovedCredentials'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e == null ? null : TranslatedValue.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$LogEntryToJson(LogEntry instance) => <String, dynamic>{
      'ID': instance.id,
      'Type': instance.type,
      'Time': instance.time,
      'ServerName': instance.serverName,
      'IssuedCredentials': instance.issuedCredentials,
      'DisclosedCredentials': instance.disclosedAttributes,
      'SignedMessage': instance.signedMessage,
      'RemovedCredentials': instance.removedCredentials,
    };

SignedMessage _$SignedMessageFromJson(Map<String, dynamic> json) {
  return SignedMessage(
    message: json['Message'] as String,
    timestamp: json['Timestamp'] as int,
  );
}

Map<String, dynamic> _$SignedMessageToJson(SignedMessage instance) => <String, dynamic>{
      'Message': instance.message,
      'Timestamp': instance.timestamp,
    };
