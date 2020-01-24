import 'package:json_annotation/json_annotation.dart';

class SignedMessage {
  const SignedMessage(
    this.ldContext,
    this.message,
  );

  @JsonKey(name: '@context')
  final String ldContext;

  @JsonKey(name: 'message')
  final String message;
}
