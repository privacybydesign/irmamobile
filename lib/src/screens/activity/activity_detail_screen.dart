import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';
import '../../theme/theme.dart';
import '../../util/date_formatter.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/irma_bottom_bar.dart';
import '../../widgets/translated_text.dart';
import 'widgets/activity_detail_disclose.dart';
import 'widgets/activity_detail_issuance.dart';
import 'widgets/activity_detail_removal.dart';
import 'widgets/activity_detail_signing.dart';

class ActivityDetailScreen extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailScreen({required this.logEntry, required this.irmaConfiguration});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Scaffold(
      appBar: IrmaAppBar(
          title: TranslatedText(
        'home.nav_bar.activity',
        style: theme.themeData.textTheme.headline2,
      )),
      bottomNavigationBar:
          IrmaBottomBar(primaryButtonLabel: 'home.button_back', onPrimaryPressed: () => Navigator.of(context).pop()),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(builder: (context) {
              switch (logEntry.type) {
                case LogEntryType.disclosing:
                  return ActivityDetailDisclose(
                    logEntry: logEntry,
                    irmaConfiguration: irmaConfiguration,
                  );
                case LogEntryType.signing:
                  return ActivityDetailSigning(
                    logEntry: logEntry,
                    irmaConfiguration: irmaConfiguration,
                  );
                case LogEntryType.issuing:
                  return ActivityDetailIssuance(
                    logEntry: logEntry,
                    irmaConfiguration: irmaConfiguration,
                  );
                case LogEntryType.removal:
                  return ActivityDetailRemoval(
                    logEntry: logEntry,
                    irmaConfiguration: irmaConfiguration,
                  );
              }
            }),
            //Always add the timestamp on the bottom
            SizedBox(height: IrmaTheme.of(context).smallSpacing),
            Center(
                child: Text(
              formatDate(
                logEntry.time,
                FlutterI18n.currentLocale(context)!.languageCode,
              ),
              style: IrmaTheme.of(context).themeData.textTheme.caption,
            ))
          ],
        ),
      ),
    );
  }
}
