import "dart:convert";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/theme.dart";
import "../irma_app_bar.dart";
import "../irma_divider.dart";
import "../translated_text.dart";

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

    Text buildTextContent(schemaless.Attribute attribute) {
      return Text(
        attribute.value.data as String,
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: compareTo == null
              ? theme.dark
              : attribute.value.data == compareTo!.data
              ? theme.success
              : theme.error,
        ),
      );
    }

    TranslatedText buildTranslatedTextContent(schemaless.Attribute attribute) {
      return TranslatedText(
        attribute.value.translatedValue().translate(lang),
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: compareTo == null
              ? theme.dark
              : attribute.value.data == compareTo!.data
              ? theme.success
              : theme.error,
        ),
      );
    }

    GestureDetector buildTappableImage(schemaless.Attribute attribute) {
      final image = _imageFromRaw(attribute.value.data as String);
      return GestureDetector(
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
      );
    }

    return Padding(
      padding: .symmetric(vertical: theme.tinySpacing),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          buildLabel(attribute),
          switch (attribute.value.type) {
            .string => buildTextContent(attribute),
            .translatedString => buildTranslatedTextContent(attribute),
            .image => buildTappableImage(attribute),
            .boolean => throw UnimplementedError(),
            .integer => throw UnimplementedError(),
            .object => throw UnimplementedError(),
            .array => throw UnimplementedError(),
          },
        ],
      ),
    );
  }

  Image _imageFromRaw(String raw) {
    return .memory(const Base64Decoder().convert(raw), fit: .fitWidth);
  }
}
