import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../theme/theme.dart';
import '../translated_text.dart';

class IrmaCredentialCardAttributeList extends StatelessWidget {
  final List<Attribute> attributes;

  const IrmaCredentialCardAttributeList(this.attributes);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Column(
      children: [
        for (final attribute in attributes)
          if (attribute.value.runtimeType != NullValue)
            Padding(
              padding: EdgeInsets.only(bottom: theme.tinySpacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      attribute.attributeType.name.translate(lang),
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.clip,
                      style: theme.themeData.textTheme.caption,
                    ),
                  ),
                  SizedBox(
                    width: theme.smallSpacing,
                  ),
                  Flexible(
                      //If attribute is photo show link
                      child: attribute.value is PhotoValue
                          ? GestureDetector(
                              onTap: () {
                                //TODO Implement open Photo.
                              },
                              child: TranslatedText(
                                //TODO: Add translation
                                'Image',
                                textAlign: TextAlign.start,
                                style: theme.textTheme.bodyText2!.copyWith(decoration: TextDecoration.underline),
                              ),
                            )
                          : Text(
                              (attribute.value is YesNoValue
                                      ? attribute.value as YesNoValue
                                      : attribute.value as TextValue)
                                  .translated
                                  .translate(lang),
                              textAlign: TextAlign.end,
                              style: theme.themeData.textTheme.caption!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ))),
                ],
              ),
            )
      ],
    );
  }
}
