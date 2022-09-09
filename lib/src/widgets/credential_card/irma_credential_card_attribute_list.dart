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

    final textValueAttrs = attributesWithValue.where((a) => a.value is TextValue);
    final photoValueAttrs = attributesWithValue.where((a) => a.value is PhotoValue);

    Text buildLabel(Attribute a) => Text(
          a.attributeType.name.translate(lang),
          style: theme.themeData.textTheme.caption!.copyWith(
            color: theme.neutralDark,
          ),
        );

    TranslatedText buildTextContent(Attribute attribute, TextValue attrValue) {
      final Attribute? compareValue =
          compareTo?.firstWhereOrNull((e) => e.attributeType.fullId == attribute.attributeType.fullId);
      return TranslatedText(
        attrValue.translated.translate(lang),
        style: theme.themeData.textTheme.bodyText1!.copyWith(
          color: compareValue == null || compareValue.value is NullValue
              ? theme.dark
              : attribute.value.raw == compareValue.value.raw
                  ? theme.success
                  : theme.error,
        ),
      );
    }

    GestureDetector buildTappableImage(Attribute attribute, Image image) {
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

    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        direction: Axis.vertical,
        spacing: theme.smallSpacing,
        children: [
          for (Attribute a in textValueAttrs)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel(a),
                buildTextContent(a, a.value as TextValue),
              ],
            ),
          for (Attribute a in photoValueAttrs)
            Column(
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
                buildLabel(a),
                SizedBox(height: theme.tinySpacing),
                buildTappableImage(a, (a.value as PhotoValue).image),
              ],
            ),
        ],
      ),
    );
  }
}
