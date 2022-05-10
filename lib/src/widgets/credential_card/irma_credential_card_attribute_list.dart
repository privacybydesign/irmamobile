import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../theme/theme.dart';
import '../translated_text.dart';

class IrmaCredentialCardAttributeList extends StatelessWidget {
  final List<Attribute> attributes;
  final List<Attribute>? compareToAttributes;

  const IrmaCredentialCardAttributeList(
    this.attributes, {
    this.compareToAttributes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Column(
      children: [
        for (final attribute in attributes.where((att) => att.value is! NullValue))
          Padding(
            padding: EdgeInsets.only(bottom: theme.tinySpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    attribute.attributeType.name.translate(lang),
                    textAlign: TextAlign.start,
                    style: theme.themeData.textTheme.caption,
                  ),
                ),
                SizedBox(
                  width: theme.smallSpacing,
                ),
                Flexible(
                  child: Builder(
                    builder: (context) {
                      if (attribute.value is PhotoValue) {
                        //If attribute is photo show link
                        return GestureDetector(
                          onTap: () {
                            //TODO Implement open Photo.
                          },
                          child: TranslatedText(
                            //TODO: Add translation
                            'Image',
                            textAlign: TextAlign.start,
                            style: theme.textTheme.bodyText2!.copyWith(decoration: TextDecoration.underline),
                          ),
                        );
                      } else if (attribute.value is TextValue || attribute.value is YesNoValue) {
                        final Attribute? compareValue = compareToAttributes
                            ?.firstWhereOrNull((e) => e.attributeType.id == attribute.attributeType.id);
                        return TranslatedText(
                          (attribute.value as TextValue).translated.translate(lang),
                          textAlign: TextAlign.end,
                          style: theme.themeData.textTheme.caption!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: compareValue == null || compareValue.value is NullValue
                                ? Colors.grey.shade700
                                : attribute.value.raw == compareValue.value.raw
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        );
                      }
                      //If value is null or default return empty container
                      return Container();
                    },
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}
