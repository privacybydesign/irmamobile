import "dart:convert";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/theme.dart";
import "../irma_app_bar.dart";

class YiviCredentialCardAttributeList extends StatelessWidget {
  final List<schemaless.Attribute> attributes;
  final List<schemaless.Attribute>? compareTo;

  const YiviCredentialCardAttributeList(this.attributes, {this.compareTo});

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

    Color valueColor(schemaless.AttributeValue? val) {
      if (compareTo == null) return theme.dark;
      return val?.translatedString == compareTo?.translatedString
          ? theme.success
          : theme.error;
    }

    Text buildTranslatedTextContent(schemaless.Attribute attribute) {
      final txt = attribute.value?.translatedString;
      return Text(
        txt?.translate(lang) ?? "",
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: valueColor(attribute.value),
        ),
      );
    }

    GestureDetector buildTappableImage(schemaless.Attribute attribute) {
      final val = attribute.value;
      final raw = val?.imagePath ?? val?.base64Image ?? "";
      final image = _imageFromRaw(raw);
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
      padding: .symmetric(
        vertical: attribute.value == null ? 0 : theme.tinySpacing,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          buildLabel(attribute),
          if (attribute.value != null)
            switch (attribute.value!.type) {
              .translatedString => buildTranslatedTextContent(attribute),
              .image => buildTappableImage(attribute),
              .base64Image => buildTappableImage(attribute),
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
