import '../../../models/attributes.dart';
import 'disclosure_credential.dart';

/// DisclosureCredential that is choosable and only contains the attributes that are going to be disclosed in the session.
class ChoosableDisclosureCredential extends DisclosureCredential {
  ChoosableDisclosureCredential({required List<Attribute> attributes})
      : assert(attributes.every((attr) => attr.credentialHash.isNotEmpty)),
        super(attributes: attributes);

  bool get expired => attributes.first.expired;
  bool get revoked => attributes.first.revoked;
  bool get notRevokable => attributes.first.notRevokable;
  String get credentialHash => attributes.first.credentialHash;
}
