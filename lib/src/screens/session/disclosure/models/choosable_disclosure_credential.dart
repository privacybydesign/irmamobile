import '../../../../models/attribute.dart';
import '../../../../models/credentials.dart';
import 'disclosure_credential.dart';
import 'template_disclosure_credential.dart';

/// DisclosureCredential that is choosable and only contains the attributes that are going to be disclosed in the session.
class ChoosableDisclosureCredential extends DisclosureCredential {
  final String credentialHash;

  /// Indicates whether the backing credential was already present when the disclosure session started.
  final bool previouslyAdded;

  /// Specifies the identifiers that uniquely identify this DisclosureCredential. The identifier order is based on the
  /// order in the RequestVerificationPermission session event. irmago expects this exact order to be used in callbacks.
  final List<AttributeIdentifier> identifiers;

  ChoosableDisclosureCredential({
    required CredentialInfo info,
    required List<Attribute> attributes,
    required bool expired,
    required bool revoked,
    required this.credentialHash,
    required this.previouslyAdded,
  })  : identifiers = attributes
            .map((attr) => AttributeIdentifier(
                  type: attr.attributeType.fullId,
                  credentialHash: credentialHash,
                ))
            .toList(),
        super(info: info, expired: expired, revoked: revoked, attributes: attributes);

  /// Converts the given credential to a ChoosableDisclosureCredential using the given template.
  factory ChoosableDisclosureCredential.fromTemplate({
    required TemplateDisclosureCredential template,
    required Credential credential,
  }) {
    assert(credential.info.fullId == template.fullId);
    return ChoosableDisclosureCredential(
      info: credential.info,
      attributes: credential.attributes
          .where((credAttr) =>
              template.attributes.any((templAttr) => templAttr.attributeType.fullId == credAttr.attributeType.fullId))
          .toList(),
      expired: credential.expired,
      revoked: credential.revoked,
      credentialHash: credential.hash,
      previouslyAdded: false,
    );
  }

  @override
  List<Object?> get props => [...super.props, credentialHash];
}
