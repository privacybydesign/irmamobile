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

class ActivityDetailsScreenArgs {
  final LogInfo logEntry;
  final IrmaConfiguration irmaConfiguration;

  ActivityDetailsScreenArgs({required this.logEntry, required this.irmaConfiguration});
}

class ActivityDetailsScreen extends StatelessWidget {
  final LogInfo logEntry;
  final IrmaConfiguration irmaConfiguration;

  ActivityDetailsScreen({
    required ActivityDetailsScreenArgs args,
  })  : logEntry = args.logEntry,
        irmaConfiguration = args.irmaConfiguration;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(
        titleTranslationKey: 'home.nav_bar.activity',
      ),
      body: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(theme.defaultSpacing),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    return switch (logEntry.type) {
                      LogType.disclosure || LogType.signature => ActivityDetailDisclosure(
                          logEntry: logEntry,
                          irmaConfiguration: irmaConfiguration,
                        ),
                      LogType.issuance => ActivityDetailIssuance(
                          logEntry: logEntry,
                          irmaConfiguration: irmaConfiguration,
                        ),
                      LogType.removal => ActivityDetailRemoval(
                          logEntry: logEntry,
                          irmaConfiguration: irmaConfiguration,
                        )
                    };
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
      ),
    );
  }
}
