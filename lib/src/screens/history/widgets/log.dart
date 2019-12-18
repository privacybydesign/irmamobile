import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

enum LogType { disclosing, issuing, removal, signing }

class Log extends StatelessWidget {
  final LogType type;
  final int dataCount;
  final String subTitle;
  final DateTime _eventDate = DateTime.now();
  final _dateFormat = DateFormat.yMMMMd().addPattern(" - ").add_jm();

  Log({this.type, this.subTitle, this.dataCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 32,
              width: 32,
              child: SvgPicture.asset(_eventIconAssetName()),
            ),
            SizedBox(
              width: IrmaTheme.of(context).defaultSpacing,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _title(context, dataCount),
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(
                          fontSize: 14,
                        ),
                  ),
                  Text(
                    subTitle,
                    style: IrmaTheme.of(context).textTheme.display2,
                  ),
                  Text(
                    _date(),
                    style: IrmaTheme.of(context).textTheme.body1.copyWith(
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
            Icon(IrmaIcons.chevronRight),
          ],
        ),
      ),
    );
  }

  String _title(BuildContext context, int eventCount) {
    switch (type) {
      case LogType.removal:
        return FlutterI18n.translate(context, "history.type.removal");
      case LogType.disclosing:
        return FlutterI18n.plural(context, "history.type.disclosing.data", eventCount);
      case LogType.issuing:
        return FlutterI18n.plural(context, "history.type.issuing.data", eventCount);
      case LogType.signing:
        return FlutterI18n.plural(context, "history.type.signing.data", eventCount);
    }
    return "";
  }

  String _eventIconAssetName() {
    switch (type) {
      case LogType.removal:
        return "assets/history/removal.svg";
      case LogType.disclosing:
        return "assets/history/disclosing.svg";
      case LogType.issuing:
        return "assets/history/issuing.svg";
      case LogType.signing:
        return "assets/history/signing.svg";
    }
    return "";
  }

  String _date() {
    return _dateFormat.format(_eventDate);
  }
}
