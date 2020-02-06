import 'package:flutter/foundation.dart';
import 'package:irmamobile/src/models/attributes.dart';

@Deprecated("Refactor to not use this class")
class VerifierCredential {
  final String issuer;
  final Attributes attributes;

  VerifierCredential({
    @required this.issuer,
    @required this.attributes,
  })  : assert(issuer != null),
        assert(attributes != null);
}
