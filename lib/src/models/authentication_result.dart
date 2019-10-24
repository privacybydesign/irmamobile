import 'package:json_annotation/json_annotation.dart';

part 'authentication_result.g.dart';

abstract class AuthenticationResult {}

@JsonSerializable()
class AuthenticationResultSuccess extends AuthenticationResult {}

@JsonSerializable()
class AuthenticationResultFailed extends AuthenticationResult {
  @JsonKey(name: "RemainingAttempts")
  final int remainingAttempts;

  @JsonKey(name: "BlockedDuration")
  final int blockedDuration;

  AuthenticationResultFailed({this.remainingAttempts, this.blockedDuration});
  factory AuthenticationResultFailed.fromJson(Map<String, dynamic> json) => _$AuthenticationResultFailedFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationResultFailedToJson(this);
}

@JsonSerializable()
class AuthenticationResultError extends AuthenticationResult {
  @JsonKey(name: "Error")
  final String error;

  AuthenticationResultError({this.error});
  factory AuthenticationResultError.fromJson(Map<String, dynamic> json) => _$AuthenticationResultErrorFromJson(json);
  Map<String, dynamic> toJson() => _$AuthenticationResultErrorToJson(this);
}
