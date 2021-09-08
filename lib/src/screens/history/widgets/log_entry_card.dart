// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/screens/history/util/date_formatter.dart';
import 'package:irmamobile/src/screens/history/widgets/log_icon.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class LogEntryCard extends StatelessWidget {
  final IrmaConfiguration irmaConfiguration;
  final LogEntry logEntry;
  final VoidCallback onTap;

  LogEntryCard({this.irmaConfiguration, this.logEntry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String lang = FlutterI18n.currentLocale(context).languageCode;
    String title = "";
    String subtitle = "";

    switch (logEntry.type) {
      case LogEntryType.disclosing:
        title = FlutterI18n.plural(context, "history.type.disclosing.data", logEntry.disclosedAttributes.length);
        subtitle = logEntry.serverName.name[lang];
        break;
      case LogEntryType.signing:
        title = FlutterI18n.plural(context, "history.type.signing.data", logEntry.disclosedAttributes.length);
        subtitle = logEntry.serverName.name[lang];
        break;
      case LogEntryType.issuing:
        title = FlutterI18n.plural(context, "history.type.issuing.data", logEntry.issuedCredentials.length);
        subtitle = irmaConfiguration.issuers[logEntry.issuedCredentials.first.fullIssuerId].name[lang];
        break;
      case LogEntryType.removal:
        title = FlutterI18n.plural(context, "history.type.removal.data", logEntry.removedCredentials.length);
        subtitle = irmaConfiguration.credentialTypes[logEntry.removedCredentials.keys.first].name[lang];
        break;
    }

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
                child: LogIcon(logEntry.type),
              ),
              SizedBox(
                width: IrmaTheme.of(context).defaultSpacing,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: IrmaTheme.of(context).textTheme.body1.copyWith(
                            fontSize: 14,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: IrmaTheme.of(context).textTheme.display2,
                    ),
                    Text(
                      formatDate(logEntry.time, lang),
                      style: IrmaTheme.of(context).textTheme.body1.copyWith(
                            fontSize: 14,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: IrmaTheme.of(context).defaultSpacing,
              ),
              Icon(
                IrmaIcons.chevronRight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
