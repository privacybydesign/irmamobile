import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'session.g.dart';

class MissingSessionPointer implements Exception {
  String errorMessage() {
    return 'URI does not contain a sessionpointer';
  }
}

@JsonSerializable()
class SessionPointer {
  SessionPointer({this.u, this.irmaqr});

  @JsonKey(name: 'u')
  String u;

  @JsonKey(name: 'irmaqr')
  String irmaqr;

  factory SessionPointer.fromString(String content) {
    final prefixes = [
      "irma://qr/json/",
      "https://irma.app/-pilot/session#",
      "",
    ];

    try {
      String jsonString;
      for (final prefix in prefixes) {
        if (content.startsWith(prefix) && content.length > prefix.length) {
          jsonString = Uri.decodeComponent(content.substring(prefix.length));
          break;
        }
      }

      if (jsonString == null) {
        throw MissingSessionPointer();
      }

      return SessionPointer.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      throw MissingSessionPointer();
    }
  }

  factory SessionPointer.fromJson(Map<String, dynamic> json) => _$SessionPointerFromJson(json);
  Map<String, dynamic> toJson() => _$SessionPointerToJson(this);
}

@JsonSerializable()
class SessionError {
  SessionError({
    this.errorType,
    this.wrappedError,
    this.info,
    this.stack,
    this.remoteStatus,
    this.remoteError,
  });

  @JsonKey(name: 'ErrorType')
  String errorType;

  @JsonKey(name: 'WrappedError')
  String wrappedError;

  @JsonKey(name: 'Info')
  String info;

  @JsonKey(name: 'Stack')
  String stack;

  @JsonKey(name: 'RemoteStatus')
  String remoteStatus;

  @JsonKey(name: 'RemoteError')
  String remoteError;

  factory SessionError.fromJson(Map<String, dynamic> json) => _$SessionErrorFromJson(json);
  Map<String, dynamic> toJson() => _$SessionErrorToJson(this);
}
