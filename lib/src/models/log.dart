import 'package:irmamobile/src/models/credentials.dart';
import 'package:json_annotation/json_annotation.dart';

import 'disclosed_attribute.dart';

class Log {
  const Log(
      {this.id,
      this.type,
      this.time,
      this.serverName,
      this.issuedCredentials,
      this.disclosedAttributes,
      this.signedMessage,
      this.removedCredentials});

  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'time')
  final DateTime time;

  @JsonKey(name: 'serverName')
  final String serverName;

  @JsonKey(name: 'issuedCredentials')
  final Credentials issuedCredentials;

  @JsonKey(name: 'disclosedCredentials')
  final List<DisclosedAttribute> disclosedAttributes;

  @JsonKey(name: 'signedMessage')
  final String signedMessage;

  @JsonKey(name: 'removedCredentials')
  final Map<String, String> removedCredentials;
}
