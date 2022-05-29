import '../../../../models/attributes.dart';
import '../../../../models/credentials.dart';
import 'disclosure_credential.dart';
import 'template_disclosure_credential.dart';

/// DisclosureCredential that is choosable and only contains the attributes that are going to be disclosed in the session.
class ChoosableDisclosureCredential extends DisclosureCredential {
  /// Indicates whether the backing credential was already present when the disclosure session started.
  final bool previouslyAdded;

  ChoosableDisclosureCredential({required List<Attribute> attributes, required this.previouslyAdded})
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
          .toList(),
      previouslyAdded: false,
    );
  }

  bool get expired => attributes.first.expired;
  bool get revoked => attributes.first.revoked;
  bool get notRevokable => attributes.first.notRevokable;
  String get credentialHash => attributes.first.credentialHash;

  @override
  List<Object?> get props => [...super.props, credentialHash];

  @override
  DisclosureCredential? copyAndMerge(DisclosureCredential other) {
    // ChoosableDisclosureCredentials can only be merged when they match exactly.
    if (other is! ChoosableDisclosureCredential ||
        credentialHash != other.credentialHash ||
        attributes.length != other.attributes.length) return null;

    for (int i = 0; i < attributes.length; i++) {
      if (attributes[i].attributeType.fullId != other.attributes[i].attributeType.fullId ||
          attributes[i].value.raw != other.attributes[i].value.raw) return null;
    }
    return this;
  }
}
