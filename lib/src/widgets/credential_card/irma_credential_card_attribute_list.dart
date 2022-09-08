import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../theme/theme.dart';
import '../irma_app_bar.dart';
import '../translated_text.dart';

class IrmaCredentialCardAttributeList extends StatelessWidget {
  final List<Attribute> attributes;
  final List<Attribute>? compareTo;

  const IrmaCredentialCardAttributeList(
    this.attributes, {
    this.compareTo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final attributesWithValue = attributes.where((attr) =>
        attr.value is! NullValue &&
        (compareTo?.any((attrComp) =>
                attrComp.value is! NullValue && attr.attributeType.fullId == attrComp.attributeType.fullId) ??
            true));

    Text buildLabel(Attribute attribute) => Text(
          attribute.attributeType.name.translate(lang),
          style: theme.themeData.textTheme.caption!.copyWith(
            color: theme.neutralDark,
          ),
        );

    TranslatedText buildTextContent(Attribute attribute) {
      final Attribute? compareValue =
          compareTo?.firstWhereOrNull((e) => e.attributeType.fullId == attribute.attributeType.fullId);
      return TranslatedText(
        (attribute.value as TextValue).translated.translate(lang),
        style: theme.themeData.textTheme.bodyText1!.copyWith(
          color: compareValue == null || compareValue.value is NullValue
              ? theme.dark
              : attribute.value.raw == compareValue.value.raw
                  ? theme.success
                  : theme.error,
        ),
      );
    }

    GestureDetector buildTappableImage(Attribute attribute) {
      final image = (attribute.value as PhotoValue).image;
      //If attribute is photo show link
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: IrmaAppBar(
                  title: attribute.attributeType.name.translate(lang),
                  leadingAction: Navigator.of(context).pop,
                ),
                body: SingleChildScrollView(
                  child: Center(child: image),
                ),
              ),
            ),
          );
        },
        child: ConstrainedBox(
          child: image,
          constraints: const BoxConstraints(
            maxWidth: 66,
            maxHeight: 100,
          ),
        ),
      );
    }

    final photoValueAttrs = attributesWithValue.where((a) => a.value is PhotoValue);
    final groupedByAttrTypeName = groupBy(photoValueAttrs.toList(), (Attribute a) => a.attributeType.name);

    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        direction: Axis.vertical,
        spacing: theme.smallSpacing,
        children: [
          ...(attributesWithValue.where((a) => a.value is TextValue)).map((attribute) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel(attribute),
                buildTextContent(attribute),
              ],
            );
          }).toList(),
          ...groupedByAttrTypeName.keys
              .map((e) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: theme.defaultSpacing),
                      Container(
                        height: 1,
                        width: constraints.maxWidth * 0.8,
                        decoration: BoxDecoration(
                          color: theme.neutralExtraLight,
                        ),
                      ),
                      SizedBox(height: theme.defaultSpacing),
                      buildLabel(groupedByAttrTypeName[e]![0]),
                      SizedBox(height: theme.tinySpacing),
                      Wrap(
                        direction: Axis.horizontal,
                        spacing: theme.tinySpacing,
                        children: groupedByAttrTypeName[e]!.map((a) => buildTappableImage(a)).toList(),
                      ),
                    ],
                  ))
              .toList(),
        ],
      ),
    );
  }
}
