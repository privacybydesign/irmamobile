import '../../../../models/attribute.dart';
import '../../../../models/attribute_value.dart';
import '../../../../models/credentials.dart';
import 'disclosure_credential.dart';

/// Template of a DisclosureCredential that needs to be obtained first.
class TemplateDisclosureCredential extends DisclosureCredential {
  TemplateDisclosureCredential({
    required super.info,
    required List<Attribute> super.attributes,
  });

  bool matchesCredential(Credential credential) =>
      credentialType.fullId == credential.info.fullId &&
      attributes.every((templAttr) => credential.attributes.any((credAttr) =>
          templAttr.attributeType.fullId == credAttr.attributeType.fullId &&
          (templAttr.value is NullValue || templAttr.value.raw == credAttr.value.raw)));

  bool matchesDisclosureCredential(DisclosureCredential dc) =>
      credentialType.fullId == dc.fullId &&
      attributes.every((templAttr) => dc.attributes.any((credAttr) =>
          templAttr.attributeType.fullId == credAttr.attributeType.fullId &&
          (templAttr.value is NullValue || templAttr.value.raw == credAttr.value.raw)));

  /// Returns a new template that exactly matches the current template, but leaves out the attribute value constraints.
  TemplateDisclosureCredential copyWithoutValueConstraints() => TemplateDisclosureCredential(
        info: info,
        attributes: attributes
            .map((attr) => Attribute(
                  attributeType: attr.attributeType,
                  value: NullValue(),
                ))
            .toList(),
      );
}
