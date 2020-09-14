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
    type: _toLogEntryType(json['Type'] as String),
    time: _epochSecondsToDateTime(json['Time'] as int),
    serverName: json['ServerName'] == null ? null : RequestorInfo.fromJson(json['ServerName'] as Map<String, dynamic>),
    issuedCredentials: (json['IssuedCredentials'] as List)
        ?.map((e) => e == null ? null : RawCredential.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    disclosedAttributes: (json['DisclosedCredentials'] as List)
        ?.map((e) => (e as List)
            ?.map((e) => e == null ? null : DisclosedAttribute.fromJson(e as Map<String, dynamic>))
            ?.toList())
        ?.toList(),
    signedMessage:
        json['SignedMessage'] == null ? null : SignedMessage.fromJson(json['SignedMessage'] as Map<String, dynamic>),
    removedCredentials: (json['RemovedCredentials'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          k,
          (e as Map<String, dynamic>)?.map(
            (k, e) => MapEntry(k, e == null ? null : TranslatedValue.fromJson(e as Map<String, dynamic>)),
          )),
    ),
  );
}

Map<String, dynamic> _$LogEntryToJson(LogEntry instance) => <String, dynamic>{
      'ID': instance.id,
      'Type': _$LogEntryTypeEnumMap[instance.type],
      'Time': instance.time?.toIso8601String(),
      'ServerName': instance.serverName,
      'IssuedCredentials': instance.issuedCredentials,
      'DisclosedCredentials': instance.disclosedAttributes,
      'RemovedCredentials': instance.removedCredentials,
      'SignedMessage': instance.signedMessage,
    };

const _$LogEntryTypeEnumMap = {
  LogEntryType.disclosing: 'disclosing',
  LogEntryType.signing: 'signing',
  LogEntryType.issuing: 'issuing',
  LogEntryType.removal: 'removal',
};

SignedMessage _$SignedMessageFromJson(Map<String, dynamic> json) {
  return SignedMessage(
    message: json['message'] as String,
  );
}

Map<String, dynamic> _$SignedMessageToJson(SignedMessage instance) => <String, dynamic>{
      'message': instance.message,
    };
