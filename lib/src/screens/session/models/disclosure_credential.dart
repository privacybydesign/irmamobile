import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/screens/session/models/abstract_disclosure_credential.dart';

/// Credential instance that only contains the attributes that are going to be disclosed in the session.
class DisclosureCredential extends AbstractDisclosureCredential {
  DisclosureCredential({required List<Attribute> attributes})
      : assert(attributes.every((attr) => attr.credentialHash.isNotEmpty)),
        super(attributes: attributes);

  bool get expired => attributes.first.expired;
  bool get revoked => attributes.first.revoked;
  bool get notRevokable => attributes.first.notRevokable;
}
