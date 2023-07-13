import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';

import '../../models/irma_configuration.dart';
import '../../models/log_entry.dart';
import '../../theme/theme.dart';
import '../../widgets/irma_app_bar.dart';
import '../../widgets/translated_text.dart';

import 'widgets/activity_detail_disclosure.dart';
import 'widgets/activity_detail_issuance.dart';
import 'widgets/activity_detail_removal.dart';

class ActivityDetailScreen extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityDetailScreen({
    required this.logEntry,
    required this.irmaConfiguration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Scaffold(
      backgroundColor: theme.backgroundSecondary,
      appBar: const IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.activity',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  switch (logEntry.type) {
                    case LogEntryType.signing:
                    case LogEntryType.disclosing:
                      return ActivityDetailDisclosure(
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
                },
              ),
              //Always add the timestamp of the activity on the bottom
              SizedBox(height: theme.smallSpacing),
              Center(
                child: TranslatedText(
                  'credential.date_at_time',
                  key: const Key('activity_timestamp'),
                  translationParams: {
                    'date': DateFormat.yMMMMd(lang).format(logEntry.time),
                    'time': DateFormat.jm(lang).format(logEntry.time),
                  },
                  style: theme.themeData.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
