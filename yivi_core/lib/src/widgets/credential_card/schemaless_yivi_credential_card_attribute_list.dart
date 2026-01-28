import "dart:convert";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../models/translated_value.dart";
import "../../theme/theme.dart";
import "../irma_app_bar.dart";

class SchemalessYiviCredentialCardAttributeList extends StatelessWidget {
  final List<schemaless.Attribute> attributes;
  final List<schemaless.Attribute>? compareTo;

  const SchemalessYiviCredentialCardAttributeList(
    this.attributes, {
    this.compareTo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      spacing: theme.smallSpacing,
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        for (final a in attributes)
          _AttributeView(
            attribute: a,
            compareTo: compareTo?.firstWhereOrNull((c) => c.id == a.id)?.value,
          ),
      ],
    );
  }
}

class _AttributeView extends StatelessWidget {
  const _AttributeView({required this.attribute, this.compareTo});
  final schemaless.Attribute attribute;
  final schemaless.AttributeValue? compareTo;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    Text buildLabel(schemaless.Attribute a) => Text(
      a.displayName.translate(lang),
      style: theme.themeData.textTheme.bodyMedium!.copyWith(fontSize: 14),
    );

    Widget buildTextContent(schemaless.Attribute attribute) {
      return Column(
        crossAxisAlignment: .start,
        children: [
          buildLabel(attribute),
          Text(
            attribute.value.data as String,
            style: theme.themeData.textTheme.bodyLarge!.copyWith(
              color: compareTo == null
                  ? theme.dark
                  : attribute.value.data == compareTo!.data
                  ? theme.success
                  : theme.error,
            ),
          ),
        ],
      );
    }

    Widget buildTranslatedTextContent(schemaless.Attribute attribute) {
      final txt = TranslatedValue.fromJson(
        attribute.value.data as Map<String, dynamic>,
      );
      return Column(
        crossAxisAlignment: .start,
        children: [
          buildLabel(attribute),
          Text(
            txt.translate(lang),
            style: theme.themeData.textTheme.bodyLarge!.copyWith(
              color: compareTo == null
                  ? theme.dark
                  : attribute.value.data == compareTo!.data
                  ? theme.success
                  : theme.error,
            ),
          ),
        ],
      );
    }

    Widget buildTappableImage(schemaless.Attribute attribute) {
      final imageContent = TranslatedValue.fromJson(
        attribute.value.data as Map<String, dynamic>,
      ).translate(lang);
      final image = _imageFromRaw(imageContent);
      return Column(
        crossAxisAlignment: .start,
        children: [
          buildLabel(attribute),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: IrmaAppBar(
                      titleString: attribute.displayName.translate(lang),
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
        ],
      );
    }

    return Padding(
      padding: .symmetric(vertical: theme.tinySpacing),
      child: switch (attribute.value.type) {
        .string => buildTextContent(attribute),
        .translatedString => buildTranslatedTextContent(attribute),
        .image => buildTappableImage(attribute),
        .base64Image => buildTappableImage(attribute),
        .object => _buildObject(theme, attribute),
        .boolean => throw UnimplementedError(),
        .integer => throw UnimplementedError(),
        .array => throw UnimplementedError(),
      },
    );
  }

  Widget _buildObject(IrmaThemeData theme, schemaless.Attribute attribute) {
    final obj = attribute.value.data as Map<String, dynamic>;
    final nested = obj.values.map(
      (a) => _AttributeView(
        attribute: schemaless.Attribute.fromJson(a as Map<String, dynamic>),
      ),
    );

    // if there's no human readable name for this attribute section,
    // just make the nested values a flat list
    if (attribute.displayName.isEmpty) {
      return Column(
        spacing: theme.smallSpacing,
        crossAxisAlignment: .start,
        children: [...nested],
      );
    }
    return Text("${attribute.id} (object)");
  }

  Image _imageFromRaw(String raw) {
    return .memory(const Base64Decoder().convert(raw), fit: .fitWidth);
  }
}
