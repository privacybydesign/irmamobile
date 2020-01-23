import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/history/util/date_formatter.dart';
import 'package:irmamobile/src/screens/history/widgets/log.dart';
import 'package:irmamobile/src/screens/history/widgets/log_icon.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Header extends StatelessWidget {
  final String issuer;
  final DateTime eventDate;
  final LogType logType;

  const Header(this.issuer, this.eventDate, this.logType);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: IrmaTheme.of(context).grayscale95,
      padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _getHeaderText(context),
                style: IrmaTheme.of(context).textTheme.body1.copyWith(
                      fontSize: 14,
                    ),
              ),
              Text(
                issuer,
                style: IrmaTheme.of(context).textTheme.display2.copyWith(),
              ),
              Text(
                formatDate(eventDate),
                style: IrmaTheme.of(context).textTheme.body1.copyWith(
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          LogIcon(logType),
        ],
      ),
    );
  }

  String _getHeaderText(BuildContext context) {
    switch (logType) {
      case LogType.removal:
        return FlutterI18n.translate(context, "history.type.removal");
      case LogType.disclosing:
        return FlutterI18n.translate(context, "history.type.disclosing.header");
      case LogType.issuing:
        return FlutterI18n.translate(context, "history.type.issuing.header");
      case LogType.signing:
        return FlutterI18n.translate(context, "history.type.signing.header");
    }
    return "";
  }
}
