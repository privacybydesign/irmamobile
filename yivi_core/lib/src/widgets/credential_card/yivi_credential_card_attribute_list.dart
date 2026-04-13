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

    return Column(
      spacing: theme.smallSpacing,
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        for (final a in sorted)
          _AttributeView(
            attribute: a,
            compareTo: compareTo?.firstWhereOrNull((c) => c.id == a.id)?.value,
          ),
      ],
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
    final indenting = IndentPointer();

    return Padding(
      padding: .symmetric(
        vertical: attribute.value == null ? 0 : theme.tinySpacing,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          buildLabel(attribute, theme, lang),
          buildContentForAttribute(attribute, context, theme, lang, indenting),
        ],
      ),
    );
  }

  Image _imageFromRaw(String raw) {
    return .memory(const Base64Decoder().convert(raw), fit: .fitWidth);
  }

  Text buildLabel(schemaless.Attribute a, IrmaThemeData theme, String lang) => Text(
      a.displayName.translate(lang),
      style: theme.themeData.textTheme.bodyMedium!.copyWith(fontSize: 14),
    );

    Color valueColor(schemaless.AttributeValue? val, IrmaThemeData theme) {
      if (compareTo == null) return theme.dark;
      return val?.translatedString == compareTo?.translatedString
          ? theme.success
          : theme.error;
    }

    Text buildTranslatedTextContent(schemaless.AttributeValue val, IrmaThemeData theme, String lang, IndentPointer indenting) {
      final txt = val.translatedString;
      final prepend = indenting.getIndenting();
      return Text(
        "$prepend ${txt?.translate(lang) ?? ""}",
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: valueColor(val, theme),
        ),
      );
    }

    Text buildTextContent(schemaless.AttributeValue val, IrmaThemeData theme, String lang, IndentPointer indenting) {
      final txt = val.string;
      final prepend = indenting.getIndenting();
      return Text(
        "$prepend ${txt ?? ""}",
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: valueColor(val, theme),
        ),
      );
    }

    Text buildBooleanContent(schemaless.AttributeValue val, IrmaThemeData theme, String lang, IndentPointer indenting) {
      final boolVal = val.boolValue;
      
      // TODO: localize yes/no values
      final localizedTxt = boolVal == null ? "" : (boolVal ? "Yes" : "No");
      final prepend = indenting.getIndenting();

      return Text(
        "$prepend $localizedTxt",
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: valueColor(val, theme),
        ),
      );
    }

    Text buildIntegerContent(schemaless.AttributeValue val, IrmaThemeData theme, String lang, IndentPointer indenting) {
      final intVal = val.intValue;
      final prepend = indenting.getIndenting();
      return Text(
        "$prepend ${intVal?.toString() ?? ""}",
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: valueColor(val, theme),
        ),
      );
    }

    Widget buildArrayContent(schemaless.AttributeValue val, BuildContext context, IrmaThemeData theme, String lang, IndentPointer indenting) {
      final arr = val.array ?? [];
      indenting.increase();
      return Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          for (final item in arr)
            buildContentAttributeValue(item, context, theme, lang, indenting),
        ],
      );
    }

    Widget buildTappableImage(schemaless.Attribute attribute, BuildContext context, IrmaThemeData theme, String lang) {
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
                    titleString: attribute.displayName.translate(lang, fallbackLang: ""),
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

    Widget buildContentForAttribute(schemaless.Attribute attribute, BuildContext context, IrmaThemeData theme, String lang, IndentPointer indenting) {
      if (attribute.value != null) {
        return switch (attribute.value!.type) {
          .translatedString || .string || .boolean || .integer || .array => buildContentAttributeValue(attribute.value!, context, theme, lang, indenting),
          .image => buildTappableImage(attribute, context, theme, lang),
          .base64Image => buildTappableImage(attribute, context, theme, lang),
          .object => throw UnimplementedError(),
        };
      }
      return const SizedBox.shrink();
    }

    Widget buildContentAttributeValue(schemaless.AttributeValue val, BuildContext context, IrmaThemeData theme, String lang, IndentPointer indenting) {
      return switch (val.type) {
        .translatedString => buildTranslatedTextContent(val, theme, lang, indenting),
        .string => buildTextContent(val, theme, lang, indenting),
        .boolean => buildBooleanContent(val, theme, lang, indenting),
        .integer => buildIntegerContent(val, theme, lang, indenting),
        .object => throw UnimplementedError(),
        .array => buildArrayContent(val, context, theme, lang, indenting),
        // Are handled at buildContentForAttribute
        .image => throw UnimplementedError(),
        .base64Image => throw UnimplementedError(),
      };
    }
}
