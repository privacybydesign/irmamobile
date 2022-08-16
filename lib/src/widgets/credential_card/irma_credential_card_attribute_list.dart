import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute_value.dart';
import '../../models/attributes.dart';
import '../../theme/theme.dart';
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

    return Row(
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final attribute in attributesWithValue) ...[
                Text(
                  attribute.attributeType.name.translate(lang),
                  style: theme.themeData.textTheme.caption!.copyWith(
                    color: theme.neutralDark,
                  ),
                ),
                SizedBox(height: theme.tinySpacing),
                Builder(
                  builder: (context) {
                    if (attribute.value is PhotoValue) {
                      //If attribute is photo show link
                      return GestureDetector(
                        onTap: () {
                          //TODO Implement open Photo.
                          // Feedback.forTap(context); // TODO add haptic feedback
                        },
                        child: TranslatedText(
                          //TODO: Add translation
                          'Image',
                          textAlign: TextAlign.start,
                          style: theme.textTheme.bodyText2!.copyWith(decoration: TextDecoration.underline),
                        ),
                      );
                    } else if (attribute.value is TextValue) {
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
                    //If value is null or default return empty container
                    return Container();
                  },
                ),
                //If this is not the last item add some padding
                if (attributesWithValue.last != attribute)
                  SizedBox(
                    height: theme.smallSpacing,
                  )
              ]
            ],
          ),
        )
      ],
    );
  }
}
