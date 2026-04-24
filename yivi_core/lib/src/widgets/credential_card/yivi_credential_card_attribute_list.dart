import "dart:convert";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../models/translated_value.dart";
import "../../theme/theme.dart";
import "../irma_app_bar.dart";

class YiviCredentialCardAttributeList extends StatelessWidget {
  final List<schemaless.Attribute> attributes;
  final List<schemaless.Attribute>? compareTo;

  const YiviCredentialCardAttributeList(this.attributes, {this.compareTo});

  /// Returns the parent claim path if this attribute is an array element
  /// (i.e., the last element of claimPath is an int), or null otherwise.
  static List<dynamic>? _arrayParentPath(schemaless.Attribute a) {
    if (a.claimPath.length >= 2 && a.claimPath.last is int) {
      return a.claimPath.sublist(0, a.claimPath.length - 1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final sorted = [...attributes]
      ..sort((a, b) {
        final aIsImage =
            a.value?.type == schemaless.AttributeType.image ||
            a.value?.type == schemaless.AttributeType.base64Image;
        final bIsImage =
            b.value?.type == schemaless.AttributeType.image ||
            b.value?.type == schemaless.AttributeType.base64Image;
        if (aIsImage == bIsImage) return 0;
        return aIsImage ? 1 : -1;
      });

    // Group consecutive array elements (claimPath ending with int) under a
    // single label, so they render identically to the old nested array style.
    final children = <Widget>[];
    var i = 0;
    while (i < sorted.length) {
      final parentPath = _arrayParentPath(sorted[i]);
      if (parentPath != null) {
        // Collect all consecutive attributes that share this parent path.
        final group = <schemaless.Attribute>[];
        while (i < sorted.length) {
          final p = _arrayParentPath(sorted[i]);
          if (p != null && listEquals(p, parentPath)) {
            group.add(sorted[i]);
            i++;
          } else {
            break;
          }
        }
        children.add(
          _ArrayAttributeGroupView(attributes: group, compareTo: compareTo),
        );
      } else if (sorted[i].value == null && i + 1 < sorted.length) {
        // Valueless attribute that precedes array elements: use it as the
        // section header for the following array/object group.
        final header = sorted[i];
        i++;
        final group = <schemaless.Attribute>[];
        final expectedParent = header.claimPath;
        while (i < sorted.length) {
          final p = _arrayParentPath(sorted[i]);
          if (p != null && listEquals(p, expectedParent)) {
            group.add(sorted[i]);
            i++;
          } else {
            break;
          }
        }
        if (group.isNotEmpty) {
          children.add(
            _ArrayAttributeGroupView(
              attributes: group,
              compareTo: compareTo,
              sectionHeader: header.displayName,
            ),
          );
        } else {
          // No array elements followed; render as a regular attribute.
          children.add(
            _AttributeView(
              attribute: header,
              compareTo: compareTo
                  ?.firstWhereOrNull(
                    (c) => listEquals(c.claimPath, header.claimPath),
                  )
                  ?.value,
            ),
          );
        }
      } else {
        children.add(
          _AttributeView(
            attribute: sorted[i],
            compareTo: compareTo
                ?.firstWhereOrNull(
                  (c) => listEquals(c.claimPath, sorted[i].claimPath),
                )
                ?.value,
          ),
        );
        i++;
      }
    }

    return Column(
      spacing: theme.smallSpacing,
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: children,
    );
  }
}

class IndentPointer {
  int indentLevel = 0;

  void increase() => indentLevel++;
  String getIndenting() => (indentLevel > 0 ? "${" " * indentLevel}-" : "");
}

class _AttributeView extends StatelessWidget {
  const _AttributeView({required this.attribute, this.compareTo});
  final schemaless.Attribute attribute;
  final schemaless.AttributeValue? compareTo;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Padding(
      padding: .symmetric(
        vertical: attribute.value == null ? 0 : theme.tinySpacing,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          buildLabel(attribute, theme, lang),
          buildContentForAttribute(attribute, context, theme, lang),
        ],
      ),
    );
  }

  Image _imageFromRaw(String raw) {
    return .memory(const Base64Decoder().convert(raw), fit: .fitWidth);
  }

  Text buildLabel(schemaless.Attribute a, IrmaThemeData theme, String lang) =>
      Text(
        a.displayName.translate(lang),
        style: theme.themeData.textTheme.bodyMedium!.copyWith(fontSize: 14),
      );

  Color valueColor(schemaless.AttributeValue? val, IrmaThemeData theme) {
    if (compareTo == null) return theme.dark;
    return val?.string == compareTo?.string ? theme.success : theme.error;
  }

  Text buildTextContent(
    schemaless.AttributeValue val,
    IrmaThemeData theme,
  ) {
    return Text(
      val.string ?? "",
      style: theme.themeData.textTheme.bodyLarge!.copyWith(
        color: valueColor(val, theme),
      ),
    );
  }

  Text buildBooleanContent(
    schemaless.AttributeValue val,
    IrmaThemeData theme,
  ) {
    final boolVal = val.boolValue;

    // TODO: localize yes/no values
    final localizedTxt = boolVal == null ? "" : (boolVal ? "Yes" : "No");

    return Text(
      localizedTxt,
      style: theme.themeData.textTheme.bodyLarge!.copyWith(
        color: valueColor(val, theme),
      ),
    );
  }

  Text buildIntegerContent(
    schemaless.AttributeValue val,
    IrmaThemeData theme,
  ) {
    return Text(
      val.intValue?.toString() ?? "",
      style: theme.themeData.textTheme.bodyLarge!.copyWith(
        color: valueColor(val, theme),
      ),
    );
  }

  Widget buildTappableImage(
    schemaless.Attribute attribute,
    BuildContext context,
    IrmaThemeData theme,
    String lang,
  ) {
    final val = attribute.value;
    final raw = val?.imagePath ?? val?.base64Image ?? "";
    final image = _imageFromRaw(raw);
    return Padding(
      padding: EdgeInsets.only(top: theme.tinySpacing),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: IrmaAppBar(
                  titleString: attribute.displayName.translate(
                    lang,
                    fallbackLang: "",
                  ),
                ),
                body: SingleChildScrollView(child: Center(child: image)),
              ),
            ),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 66, maxHeight: 100),
          child: image,
        ),
      ),
    );
  }

  Widget buildContentForAttribute(
    schemaless.Attribute attribute,
    BuildContext context,
    IrmaThemeData theme,
    String lang,
  ) {
    if (attribute.value == null) return const SizedBox.shrink();
    return switch (attribute.value!.type) {
      .string => buildTextContent(attribute.value!, theme),
      .boolean => buildBooleanContent(attribute.value!, theme),
      .integer => buildIntegerContent(attribute.value!, theme),
      .image => buildTappableImage(attribute, context, theme, lang),
      .base64Image => buildTappableImage(attribute, context, theme, lang),
    };
  }
}

/// Renders a group of array element attributes under a single label,
/// with each value indented with a dash prefix (matching the old nested array style).
class _ArrayAttributeGroupView extends StatelessWidget {
  const _ArrayAttributeGroupView({
    required this.attributes,
    this.compareTo,
    this.sectionHeader,
  });
  final List<schemaless.Attribute> attributes;
  final List<schemaless.Attribute>? compareTo;
  final TranslatedValue? sectionHeader;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    // Use the section header if provided, otherwise fall back to the first
    // element's display name.
    final label =
        (sectionHeader ?? attributes.first.displayName).translate(lang);

    return Padding(
      padding: .symmetric(vertical: theme.tinySpacing),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(
            label,
            style: theme.themeData.textTheme.bodyMedium!.copyWith(fontSize: 14),
          ),
          for (final attr in attributes) _buildIndentedValue(attr, theme, lang),
        ],
      ),
    );
  }

  Widget _buildIndentedValue(
    schemaless.Attribute attr,
    IrmaThemeData theme,
    String lang,
  ) {
    final indenting = IndentPointer()..increase();

    Color valueColor(schemaless.AttributeValue? val) {
      if (compareTo == null) return theme.dark;
      final match = compareTo?.firstWhereOrNull(
        (c) => listEquals(c.claimPath, attr.claimPath),
      );
      if (match == null) return theme.error;
      return val?.string == match.value?.string ? theme.success : theme.error;
    }

    if (attr.value == null) return const SizedBox.shrink();

    final val = attr.value!;
    final prepend = indenting.getIndenting();
    final String text;

    switch (val.type) {
      case schemaless.AttributeType.string:
        text = "$prepend ${val.string ?? ""}";
      case schemaless.AttributeType.integer:
        text = "$prepend ${val.intValue?.toString() ?? ""}";
      case schemaless.AttributeType.boolean:
        // TODO: localize yes/no values
        final localizedTxt = val.boolValue == null
            ? ""
            : (val.boolValue! ? "Yes" : "No");
        text = "$prepend $localizedTxt";
      case schemaless.AttributeType.image:
      case schemaless.AttributeType.base64Image:
        // Images in arrays are unlikely but fall back to non-indented rendering.
        text = "$prepend ${val.string ?? ""}";
    }

    return Text(
      text,
      style: theme.themeData.textTheme.bodyLarge!.copyWith(
        color: valueColor(val),
      ),
    );
  }
}
