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
