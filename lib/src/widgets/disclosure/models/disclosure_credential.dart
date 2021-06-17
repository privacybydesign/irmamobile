import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/translated_value.dart';

class DisclosureCredential {
  final Con<Attribute> attributes;
  final String id;
  final TranslatedValue issuer;
  final CredentialInfo credentialInfo;
  final bool isLast;
  final bool obtainable;

  bool get satisfiable => present && !expired && !revoked;
  bool get expired => attributes.first.expired;
  bool get revoked => attributes.first.revoked;
  bool get notRevokable => attributes.first.notRevokable;
  bool get present => attributes.first.credentialHash != '';
  bool get hasValues => attributes.first.value.raw != null;

  DisclosureCredential({@required this.attributes, @required this.isLast})
      : assert(isLast != null &&
            attributes != null &&
            attributes.isNotEmpty &&
            attributes.every((attr) =>
                attr.credentialInfo.credentialType.fullId == attributes.first.credentialInfo.credentialType.fullId)),
        id = attributes.first.credentialInfo.fullId,
        issuer = attributes.first.credentialInfo.issuer.name,
        credentialInfo = attributes.first.credentialInfo,
        obtainable = attributes.last.credentialInfo.credentialType.issueUrl?.isNotEmpty ?? false;
}
