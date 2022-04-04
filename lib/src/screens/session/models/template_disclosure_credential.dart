import 'package:collection/collection.dart';

import '../../../models/attributes.dart';
import '../../../models/credentials.dart';
import 'choosable_disclosure_credential.dart';
import 'disclosure_credential.dart';

/// Template of a DisclosureCredential that needs to be obtained first.
class TemplateDisclosureCredential extends DisclosureCredential {
  /// List of DisclosureCredentials that match the template.
  final UnmodifiableListView<ChoosableDisclosureCredential> presentMatching;

  /// List of DisclosureCredentials with the same credential type that are present, but do not match with the template.
  final UnmodifiableListView<ChoosableDisclosureCredential> presentNonMatching;

  factory TemplateDisclosureCredential({
    required List<Attribute> attributes,
    required Iterable<Credential> credentials,
  }) {
    final presentCreds = credentials.where((cred) => cred.info.fullId == attributes.first.credentialInfo.fullId);
    return TemplateDisclosureCredential._fromChoosableDisclosureCredentials(
      attributes: attributes,
      // Only include the attributes that are included in the template.
      choosableDisclosureCredentials: presentCreds.map(
        (cred) => ChoosableDisclosureCredential(
          attributes: cred.attributeList
              .where((attr1) => attributes.any((attr2) => attr1.attributeType.fullId == attr2.attributeType.fullId))
              .toList(),
        ),
      ),
    );
  }

  TemplateDisclosureCredential._({
    required List<Attribute> attributes,
    List<ChoosableDisclosureCredential> presentMatching = const [],
    List<ChoosableDisclosureCredential> presentNonMatching = const [],
  })  : presentMatching = UnmodifiableListView(presentMatching),
        presentNonMatching = UnmodifiableListView(presentNonMatching),
        super(attributes: attributes);

  factory TemplateDisclosureCredential._fromChoosableDisclosureCredentials({
    required List<Attribute> attributes,
    required Iterable<ChoosableDisclosureCredential> choosableDisclosureCredentials,
  }) {
    assert(choosableDisclosureCredentials.every((cred) =>
        cred.fullId == choosableDisclosureCredentials.first.fullId &&
        cred.attributes.every((credAttr) =>
            attributes.any((templateAttr) => credAttr.attributeType.fullId == templateAttr.attributeType.fullId))));

    final Map<bool, List<ChoosableDisclosureCredential>> mapped = groupBy(
        choosableDisclosureCredentials,
        // Group based on whether the credentials match the template or not.
        (cred) => attributes.every((templateAttr) =>
            templateAttr.value.raw == null ||
            cred.attributes.any((credAttr) =>
                credAttr.attributeType.fullId == templateAttr.attributeType.fullId &&
                credAttr.value.raw == templateAttr.value.raw)));

    return TemplateDisclosureCredential._(
      attributes: attributes,
      presentMatching: mapped[true] ?? [],
      presentNonMatching: mapped[false] ?? [],
    );
  }

  /// Indicates whether a credential is present that matches the template.
  bool get obtained => presentMatching.isNotEmpty;

  /// Returns a copy with presentMatching and presentNonMatching being refreshed using the given credentials.
  TemplateDisclosureCredential copyWith({required Iterable<Credential> credentials}) =>
      TemplateDisclosureCredential(attributes: attributes, credentials: credentials);

  /// Returns a new template with the merged contents of this and the given other template, if they don't contradict.
  /// Returns null otherwise.
  TemplateDisclosureCredential? copyAndMerge(TemplateDisclosureCredential other) {
    if (fullId != other.fullId) return null;

    final attributesMap = [...attributes, ...other.attributes].groupSetsBy((attr) => attr.attributeType.fullId);
    final List<Attribute> mergedAttributes = [];
    for (final attrSet in attributesMap.values) {
      // If the expected attribute values of a specific attribute type differ, then the instances cannot be merged.
      final attr = attrSet.where((attr) => attr.value.raw != null);
      if (attr.length > 1) {
        return null;
      } else if (attr.length == 1) {
        mergedAttributes.add(attr.first);
      } else {
        // There are no specific values requested, so we can simply show the first one.
        mergedAttributes.add(attrSet.first);
      }
    }
    final creds = [...presentMatching, ...presentNonMatching];
    final otherCreds = [...other.presentMatching, ...other.presentNonMatching];
    return TemplateDisclosureCredential._fromChoosableDisclosureCredentials(
      attributes: mergedAttributes,
      choosableDisclosureCredentials: creds.map((cred) {
        final otherCred = otherCreds.firstWhere((cred2) => cred.credentialHash == cred2.credentialHash);
        return ChoosableDisclosureCredential(
          // DisclosureCredentials don't contain all attributes, but only the attributes involved in the template.
          // Therefore, we have to check the present credentials from both this and the other template to find a
          // particular attribute.
          attributes: mergedAttributes
              .map((attr1) => [...cred.attributes, ...otherCred.attributes]
                  .firstWhere((attr2) => attr1.attributeType.fullId == attr2.attributeType.fullId))
              .toList(),
        );
      }),
    );
  }
}
