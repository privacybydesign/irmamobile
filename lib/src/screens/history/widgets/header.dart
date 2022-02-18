// This code is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/screens/history/util/date_formatter.dart';
import 'package:irmamobile/src/screens/history/widgets/log_icon.dart';
import 'package:irmamobile/src/theme/theme.dart';

class Header extends StatelessWidget {
  final LogEntry logEntry;
  const Header(this.logEntry);

  @override
  Widget build(BuildContext context) {
    final String lang = FlutterI18n.currentLocale(context).languageCode;
    return Container(
      color: IrmaTheme.of(context).grayscale95,
      padding: EdgeInsets.all(IrmaTheme.of(context).defaultSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _getHeaderText(context),
                  style: IrmaTheme.of(context).textTheme.bodyText2.copyWith(
                        fontSize: 14,
                      ),
                ),
                if (logEntry.serverName != null)
                  Text(
                    logEntry.serverName.name.translate(lang),
                    style: IrmaTheme.of(context).textTheme.headline3.copyWith(),
                  ),
                Text(
                  formatDate(logEntry.time, lang),
                  style: IrmaTheme.of(context).textTheme.bodyText2.copyWith(
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ),
          LogIcon(logEntry.type),
        ],
      ),
    );
  }

  String _getHeaderText(BuildContext context) {
    switch (logEntry.type) {
      case LogEntryType.removal:
        return FlutterI18n.translate(context, "history.type.removal.header");
      case LogEntryType.disclosing:
        return FlutterI18n.translate(context, "history.type.disclosing.header");
      case LogEntryType.issuing:
        return FlutterI18n.translate(context, "history.type.issuing.header");
      case LogEntryType.signing:
        return FlutterI18n.translate(context, "history.type.signing.header");
    }
    return "";
  }
}
