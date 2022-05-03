import '../../../models/attributes.dart';
import '../../../models/credentials.dart';
import 'disclosure_credential.dart';
import 'template_disclosure_credential.dart';

/// DisclosureCredential that is choosable and only contains the attributes that are going to be disclosed in the session.
class ChoosableDisclosureCredential extends DisclosureCredential {
  ChoosableDisclosureCredential({required List<Attribute> attributes})
      : assert(attributes.every((attr) => attr.credentialHash.isNotEmpty)),
        super(attributes: attributes);

  /// Converts the given credential to a ChoosableDisclosureCredential using the given template.
  factory ChoosableDisclosureCredential.fromTemplate({
    required TemplateDisclosureCredential template,
    required Credential credential,
  }) {
    assert(credential.info.fullId == template.fullId);
    return ChoosableDisclosureCredential(
        attributes: credential.attributeList
            .where((credAttr) =>
                template.attributes.any((templAttr) => templAttr.attributeType.fullId == credAttr.attributeType.fullId))
            .toList());
  }

  bool get expired => attributes.first.expired;
  bool get revoked => attributes.first.revoked;
  bool get notRevokable => attributes.first.notRevokable;
  String get credentialHash => attributes.first.credentialHash;
}
