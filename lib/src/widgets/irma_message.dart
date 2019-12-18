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
  String title;
  String description;
  IrmaMessageType type;

  IrmaMessage(this.title, this.description, {this.type = IrmaMessageType.info});

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
        break;
    }
    return Container(
      child: Card(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 11, 0),
              child: Icon(
                icon,
                size: 16.0,
                color: foregroundColor,
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
