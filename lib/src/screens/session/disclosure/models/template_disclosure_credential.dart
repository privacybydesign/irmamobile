import 'package:collection/collection.dart';
import 'package:irmamobile/src/models/attribute_value.dart';

import '../../../../models/attributes.dart';
import '../../../../models/credentials.dart';
import 'disclosure_credential.dart';

/// Template of a DisclosureCredential that needs to be obtained first.
class TemplateDisclosureCredential extends DisclosureCredential {
  TemplateDisclosureCredential({required List<Attribute> attributes}) : super(attributes: attributes);

  bool matchesCredential(Credential credential) =>
      credentialType.fullId == credential.info.fullId &&
      attributes.every((templAttr) => credential.attributeList.any((credAttr) =>
          templAttr.attributeType.fullId == credAttr.attributeType.fullId &&
          (templAttr.value is NullValue || templAttr.value.raw == credAttr.value.raw)));

  bool matchesDisclosureCredential(DisclosureCredential dc) =>
      credentialType.fullId == dc.fullId &&
      attributes.every((templAttr) => dc.attributes.any((credAttr) =>
          templAttr.attributeType.fullId == credAttr.attributeType.fullId &&
          (templAttr.value is NullValue || templAttr.value.raw == credAttr.value.raw)));

  @override
  DisclosureCredential? copyAndMerge(DisclosureCredential other) {
    if (other is! TemplateDisclosureCredential || fullId != other.fullId) return null;

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
    return TemplateDisclosureCredential(attributes: mergedAttributes);
  }

  /// Returns a new template that exactly matches the current template, but leaves out the attribute value constraints.
  TemplateDisclosureCredential copyWithoutValueConstraints() => TemplateDisclosureCredential(
        attributes: attributes
            .map((attr) => Attribute(
                  credentialInfo: attr.credentialInfo,
                  attributeType: attr.attributeType,
                  value: NullValue(),
                ))
            .toList(),
      );
}
