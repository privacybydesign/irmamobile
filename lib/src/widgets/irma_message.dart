// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

enum IrmaMessageType {
  valid,
  invalid,
  alert,
  info,
}

class IrmaMessage extends StatelessWidget {
  final String titleKey;
  final Map<String, String> titleParams;
  final String descriptionKey;
  final Map<String, String> descriptionParams;
  final IrmaMessageType type;

  const IrmaMessage(this.titleKey, this.descriptionKey,
      {this.type = IrmaMessageType.info, this.titleParams = const {}, this.descriptionParams = const {}});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor = Colors.white;
    Color iconColor = Colors.white;
    IconData icon;

    switch (type) {
      case IrmaMessageType.valid:
        backgroundColor = IrmaTheme.of(context).notificationSuccessBg;
        foregroundColor = IrmaTheme.of(context).primaryDark;
        iconColor = IrmaTheme.of(context).interactionValid;
        icon = IrmaIcons.valid;
        break;
      case IrmaMessageType.invalid:
        backgroundColor = IrmaTheme.of(context).notificationErrorBg;
        foregroundColor = IrmaTheme.of(context).primaryDark;
        iconColor = IrmaTheme.of(context).interactionInvalid;
        icon = IrmaIcons.invalid;
        break;
      case IrmaMessageType.alert:
        backgroundColor = IrmaTheme.of(context).notificationWarningBg;
        foregroundColor = IrmaTheme.of(context).primaryDark;
        iconColor = IrmaTheme.of(context).interactionAlert;
        icon = IrmaIcons.alert;
        break;
      case IrmaMessageType.info:
        backgroundColor = IrmaTheme.of(context).notificationInfoBg;
        foregroundColor = IrmaTheme.of(context).primaryDark;
        iconColor = IrmaTheme.of(context).interactionInformation;
        icon = IrmaIcons.info;
        break;
    }
    return Container(
      child: Container(
        decoration:
            BoxDecoration(color: backgroundColor, borderRadius: const BorderRadius.all(const Radius.circular(12.0))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Container(
                child: CircleAvatar(
                  child: Icon(
                    icon,
                    size: 26.0,
                    color: backgroundColor,
                  ),
                  backgroundColor: iconColor,
                ),
                width: 26.0,
                height: 26.0,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TranslatedText(
                      titleKey,
                      style: IrmaTheme.of(context).textTheme.body2.copyWith(color: foregroundColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 11),
                      child: TranslatedText(
                        descriptionKey,
                        translationParams: descriptionParams,
                        style: IrmaTheme.of(context).textTheme.body1.copyWith(color: foregroundColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
