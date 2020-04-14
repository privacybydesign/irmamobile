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
    // Use lookahead and lookbehinds to block out the non-JSON part of the string
    final regexps = [
      RegExp("(?<=^irma:\/\/qr\/json\/).*"),
      RegExp("(?<=^intent:\/\/qr\/json\/).*(?=#)"),
      RegExp("(?<=^https:\/\/irma\.app\/-\/session#).*"),
      RegExp("(?<=^https:\/\/irma\.app\/-pilot\/session#).*"),
      RegExp(".*"),
    ];

    try {
      String jsonString;
      for (final regex in regexps) {
        final String match = regex.stringMatch(content);
        if (match != null && match.isNotEmpty) {
          jsonString = Uri.decodeComponent(match);
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
  int remoteStatus;

  @JsonKey(name: 'RemoteError')
  RemoteError remoteError;

  factory SessionError.fromJson(Map<String, dynamic> json) => _$SessionErrorFromJson(json);
  Map<String, dynamic> toJson() => _$SessionErrorToJson(this);

  @override
  String toString() => [
        if (remoteStatus != null) "$remoteStatus ",
        "$errorType",
        if (info?.isNotEmpty ?? false) " ($info)",
        if (wrappedError?.isNotEmpty ?? false) ": $wrappedError",
        if (remoteError != null) "\n${jsonEncode(remoteError..stacktrace = null)}",
      ].join();
}

@JsonSerializable()
class RemoteError {
  RemoteError({this.status, this.errorName, this.description, this.message, this.stacktrace});

  @JsonKey(name: 'status')
  int status;

  @JsonKey(name: 'error')
  String errorName;

  @JsonKey(name: 'description')
  String description;

  @JsonKey(name: 'message')
  String message;

  @JsonKey(name: 'stacktrace')
  String stacktrace;

  factory RemoteError.fromJson(Map<String, dynamic> json) => _$RemoteErrorFromJson(json);
  Map<String, dynamic> toJson() => _$RemoteErrorToJson(this);
}
