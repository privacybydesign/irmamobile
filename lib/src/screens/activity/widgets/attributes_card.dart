import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/attributes.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';

class AttributesCard extends StatelessWidget {
  final List<Attribute> attributes;

  const AttributesCard(this.attributes);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final attributesGroupdByCredential = groupBy(attributes, (Attribute att) => att.credentialInfo.fullId);

    List<Widget> _buildAttributeList(List<Attribute> attributes) {
      final List<Widget> widgets = [];

      for (final att in attributes) {
        widgets.add(Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: theme.tinySpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    att.attributeType.name.translate(lang),
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: theme.themeData.textTheme.caption,
                  ),
                ),
                SizedBox(width: theme.smallSpacing),
                Expanded(
                  child: Text(att.value.raw.toString(),
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.clip,
                      style: IrmaTheme.of(context)
                          .themeData
                          .textTheme
                          .caption!
                          .copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                )
              ],
            ),
          ),
        ));
      }
      return widgets;
    }

    return Column(
      children: [
        for (var key in attributesGroupdByCredential.keys)
          Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 4)]),
              padding: EdgeInsets.symmetric(
                  vertical: IrmaTheme.of(context).smallSpacing, horizontal: IrmaTheme.of(context).defaultSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: IrmaTheme.of(context).smallSpacing),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 40,
                            child: CircleAvatar(
                                backgroundColor: Colors.grey.shade300,
                                radius: 18,
                                child: Builder(builder: (context) {
                                  final credentialLogo =
                                      attributesGroupdByCredential[key]?.first.credentialInfo.credentialType.logo;
                                  if (credentialLogo != null && credentialLogo != '') {
                                    return SizedBox(
                                        height: 24,
                                        child: Image.file(File(credentialLogo), excludeFromSemantics: true));
                                  }
                                  return Container();
                                }))),
                        SizedBox(
                          width: IrmaTheme.of(context).smallSpacing,
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTranslation(context,
                                    attributesGroupdByCredential[key]!.first.credentialInfo.credentialType.name),
                                style: theme.themeData.textTheme.bodyText1,
                              ),
                              Text(
                                getTranslation(
                                    context, attributesGroupdByCredential[key]!.first.credentialInfo.issuer.name),
                                overflow: TextOverflow.ellipsis,
                                style: theme.themeData.textTheme.caption,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildAttributeList(attributesGroupdByCredential[key]!),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  )
                ],
              ))
      ],
    );
  }
}
