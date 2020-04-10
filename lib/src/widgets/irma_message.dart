import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

enum IrmaMessageType {
  valid,
  invalid,
  alert,
  info,
}

class IrmaMessage extends StatelessWidget {
  final String title;
  final String description;
  final IrmaMessageType type;
  final Color iconColor;

  const IrmaMessage(this.title, this.description, {this.type = IrmaMessageType.info, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor = Colors.white;

    IconData icon;
    switch (type) {
      case IrmaMessageType.valid:
        backgroundColor = IrmaTheme.of(context).interactionValid;
        icon = IrmaIcons.valid;
        break;
      case IrmaMessageType.invalid:
        backgroundColor = IrmaTheme.of(context).interactionInvalid;
        icon = IrmaIcons.invalid;
        break;
      case IrmaMessageType.alert:
        backgroundColor = IrmaTheme.of(context).interactionAlert;
        icon = IrmaIcons.alert;
        foregroundColor = IrmaTheme.of(context).primaryDark;
        break;
      case IrmaMessageType.info:
        backgroundColor = IrmaTheme.of(context).interactionInformation;
        icon = IrmaIcons.info;
        foregroundColor = IrmaTheme.of(context).primaryDark;
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
                    Text(
                      title,
                      style: IrmaTheme.of(context).textTheme.body2.copyWith(color: foregroundColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 11),
                      child: Text(
                        description,
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
