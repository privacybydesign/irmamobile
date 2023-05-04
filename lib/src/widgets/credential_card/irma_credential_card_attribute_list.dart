import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/attribute.dart';
import '../../models/attribute_value.dart';
import '../../theme/theme.dart';
import '../irma_app_bar.dart';
import '../irma_divider.dart';
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
          style: theme.themeData.textTheme.bodyMedium,
        );

    TranslatedText buildTextContent(Attribute attribute, TextValue attrValue) {
      final Attribute? compareValue =
          compareTo?.firstWhereOrNull((e) => e.attributeType.fullId == attribute.attributeType.fullId);
      return TranslatedText(
        attrValue.translated.translate(lang),
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (Attribute a in textValueAttrs)
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLabel(a),
                buildTextContent(a, a.value as TextValue),
              ],
            ),
          ),
        for (Attribute a in photoValueAttrs)
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a == photoValueAttrs.first) const IrmaDivider(),
                buildLabel(a),
                SizedBox(height: theme.tinySpacing),
                buildTappableImage(a, (a.value as PhotoValue).image),
              ],
            ),
          ),
      ],
    );
  }
}
