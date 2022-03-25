import '../../../models/attributes.dart';
import 'abstract_disclosure_credential.dart';
import 'disclosure_credential.dart';

/// Template of a DisclosureCredential that needs to be obtained first.
class DisclosureCredentialTemplate extends AbstractDisclosureCredential {
  /// List of DisclosureCredentials that match the template.
  final List<DisclosureCredential> presentMatching;

  /// List of DisclosureCredentials with the same credential type that are present, but do not match with the template.
  final List<DisclosureCredential> presentNonMatching;

  DisclosureCredentialTemplate({
    required List<Attribute> attributes,
    this.presentMatching = const [],
    this.presentNonMatching = const [],
  }) : super(attributes: attributes);

  /// Indicates whether a credential is present that matches the template.
  bool get obtained => presentMatching.isNotEmpty;
}
