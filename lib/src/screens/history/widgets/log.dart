import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/screens/history/util/date_formatter.dart';
import 'package:irmamobile/src/screens/history/widgets/log_icon.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

enum LogType { disclosing, issuing, removal, signing }

extension LogTypeParser on String {
  LogType toLogType() => LogType.values.firstWhere(
        (v) => v.toString() == 'LogType.$this',
        orElse: () => null,
      );
}

class Log extends StatelessWidget {
  final LogType type;
  final int dataCount;
  final String subTitle;
  final DateTime _eventDate = DateTime.now();
  final VoidCallback onTap;

  Log({this.type, this.subTitle, this.dataCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
                child: LogIcon(type),
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
                      formatDate(_eventDate),
                      style: IrmaTheme.of(context).textTheme.body1.copyWith(
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(IrmaIcons.chevronRight),
            ],
          ),
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
}
