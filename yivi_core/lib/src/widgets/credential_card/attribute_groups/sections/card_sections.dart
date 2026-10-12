import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../../theme/theme.dart";
import "../../yivi_credential_card_attribute_list.dart";
import "../attribute_comparison.dart";
import "../attribute_group.dart";
import "../attribute_image.dart";
import "../attribute_value_formatting.dart";
import "../requested_value.dart";
import "card_layout.dart";

/// One section after assigning attributes: what it will draw.
class AssembledSection {
  /// Null for the trailing section of attributes no section claimed.
  final String? titleKey;
  final List<AttributeGroup> groups;
  final List<schemaless.Attribute> fields;

  /// Drawn below [fields].
  final List<AttributeGroup> trailing;

  /// Attributes for the generic attribute list (trailing section only).
  final List<schemaless.Attribute> rest;

  const AssembledSection({
    required this.titleKey,
    this.groups = const [],
    this.fields = const [],
    this.trailing = const [],
    this.rest = const [],
  });

  bool get isEmpty =>
      groups.isEmpty && fields.isEmpty && trailing.isEmpty && rest.isEmpty;
}

/// Assigns [attributes] to the sections of [layout]: each section's groups
/// and trailing groups claim first, then its named fields; what is left forms
/// a trailing untitled section. Sections with nothing in them are dropped.
/// Pure.
List<AssembledSection> assembleSections(
  CardLayout layout,
  List<schemaless.Attribute> attributes, {
  List<schemaless.Attribute>? compareTo,
}) {
  var remaining = attributes;
  final result = <AssembledSection>[];

  List<AttributeGroup> claimAll(List<AttributeGroupRenderer> renderers) {
    final groups = <AttributeGroup>[];
    for (final renderer in renderers) {
      final group = renderer.claim(remaining, compareTo: compareTo);
      if (group == null) continue;
      final claimed = {
        for (final a in group.claimed) claimPathKey(a.claimPath),
      };
      remaining = [
        for (final a in remaining)
          if (!claimed.contains(claimPathKey(a.claimPath))) a,
      ];
      groups.add(group);
    }
    return groups;
  }

  for (final section in layout.sections) {
    final groups = claimAll(section.groups);
    final trailing = claimAll(section.trailingGroups);

    final byId = {
      for (final a in remaining)
        if (a.claimPath.length == 1 && a.claimPath.first is String)
          a.claimPath.first as String: a,
    };
    final fields = [for (final id in section.fieldIds) ?byId[id]];
    final taken = {for (final a in fields) claimPathKey(a.claimPath)};
    remaining = [
      for (final a in remaining)
        if (!taken.contains(claimPathKey(a.claimPath))) a,
    ];

    final assembled = AssembledSection(
      titleKey: section.titleKey,
      groups: groups,
      fields: fields,
      trailing: trailing,
    );
    if (!assembled.isEmpty) result.add(assembled);
  }

  if (remaining.isNotEmpty) {
    result.add(AssembledSection(titleKey: null, rest: remaining));
  }
  return result;
}

/// An identity credential's attributes drawn as titled sections.
class CardSections extends StatelessWidget {
  final List<schemaless.Attribute> attributes;
  final CardLayout layout;
  final List<schemaless.Attribute>? compareTo;
  final bool disclosure;

  const CardSections({
    super.key,
    required this.attributes,
    required this.layout,
    this.compareTo,
    this.disclosure = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final sections = assembleSections(layout, attributes, compareTo: compareTo);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        for (final (i, section) in sections.indexed) ...[
          if (i > 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: theme.defaultSpacing),
              child: Container(height: 1, color: theme.neutralExtraLight),
            ),
          _Section(
            key: Key("card_section_${section.titleKey ?? "rest"}"),
            section: section,
            compareTo: compareTo,
            disclosure: disclosure,
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final AssembledSection section;
  final List<schemaless.Attribute>? compareTo;
  final bool disclosure;

  const _Section({
    super.key,
    required this.section,
    required this.compareTo,
    required this.disclosure,
  });

  Widget _group(AttributeGroup group) => AttributeGroupScope(
    isFirst: true,
    isLast: true,
    inSection: true,
    isDisclosure: disclosure,
    child: Builder(builder: group.build),
  );

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final title = section.titleKey;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: theme.smallSpacing,
      children: [
        if (title != null)
          Text(
            FlutterI18n.translate(context, title).toUpperCase(),
            style: attributeEyebrowStyle(theme),
          ),
        for (final group in section.groups) _group(group),
        if (section.fields.isNotEmpty)
          FieldGrid(fields: section.fields, compareTo: compareTo),
        for (final group in section.trailing) _group(group),
        if (section.rest.isNotEmpty)
          YiviCredentialCardAttributeList(
            section.rest,
            compareTo: compareTo,
            renderers: const [],
          ),
      ],
    );
  }
}

/// Attributes in two columns, each a label above its value.
class FieldGrid extends StatelessWidget {
  final List<schemaless.Attribute> fields;
  final List<schemaless.Attribute>? compareTo;

  const FieldGrid({super.key, required this.fields, this.compareTo});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: theme.smallSpacing + theme.tinySpacing,
      children: [
        for (var i = 0; i < fields.length; i += 2)
          Row(
            crossAxisAlignment: .start,
            spacing: theme.defaultSpacing,
            children: [
              Expanded(child: _Field(fields[i], compareTo: compareTo)),
              Expanded(
                child: i + 1 < fields.length
                    ? _Field(fields[i + 1], compareTo: compareTo)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final schemaless.Attribute attribute;
  final List<schemaless.Attribute>? compareTo;

  const _Field(this.attribute, {this.compareTo});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final value = attribute.value;
    final color = comparisonColor(
      theme,
      compareAttribute(attribute, compareTo),
    );
    final style = attributeValueStyle(theme, color);

    final Widget valueWidget = switch (value?.type) {
      null => const SizedBox.shrink(),
      schemaless.AttributeType.image || schemaless.AttributeType.base64Image =>
        TappableAttributeImage(attribute: attribute),
      schemaless.AttributeType.boolean => Text(
        formatAttributeBool(context, value!.boolValue),
        style: style,
      ),
      schemaless.AttributeType.integer => Text(
        value!.intValue?.toString() ?? "",
        style: style,
      ),
      schemaless.AttributeType.string => Text(
        value!.string ?? "",
        style: style,
      ),
    };

    return WithRequestedValueChip(
      key: Key("field_${attribute.claimPath.join(".")}"),
      attributes: [attribute],
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(
            attribute.effectiveDisplayName,
            style: attributeLabelStyle(theme),
          ),
          valueWidget,
        ],
      ),
    );
  }
}
