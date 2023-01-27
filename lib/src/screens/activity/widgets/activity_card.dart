import 'package:flutter/material.dart';

import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';

import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../widgets/irma_avatar.dart';
import '../../../widgets/irma_card.dart';
import '../../../widgets/translated_text.dart';
import '../activity_detail_screen.dart';

class ActivityCard extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityCard({
    required this.logEntry,
    required this.irmaConfiguration,
  });

  @override
  Widget build(BuildContext context) {
    final String lang = FlutterI18n.currentLocale(context)!.languageCode;
    final theme = IrmaTheme.of(context);

    String title = '';
    String subtitleTranslationKey = '';
    String? logo;

    if (logEntry.type == LogEntryType.removal) {
      final credType = irmaConfiguration.credentialTypes[logEntry.removedCredentials.keys.first]!;
      title = irmaConfiguration.issuers[credType.fullIssuerId]!.name.translate(lang);
      subtitleTranslationKey = 'activity.data_deleted';
      if (credType.logo != null) {
        logo = credType.logo;
      }
    } else {
      if (logEntry.serverName != null) {
        title = logEntry.serverName!.name.translate(lang);
        if (logEntry.serverName!.logo != null) {
          logo = logEntry.serverName!.logo;
        }
      }

      if (logEntry.type == LogEntryType.issuing) {
        subtitleTranslationKey = 'activity.data_received';
      } else if (logEntry.type == LogEntryType.disclosing) {
        subtitleTranslationKey = 'activity.data_shared';
      } else if (logEntry.type == LogEntryType.signing) {
        subtitleTranslationKey = 'activity.message_signed';
      }
    }

    return IrmaCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ActivityDetailScreen(
            logEntry: logEntry,
            irmaConfiguration: irmaConfiguration,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IrmaAvatar(
                  size: 52,
                  logoPath: logo,
                  initials: title[0],
                ),
                SizedBox(
                  width: theme.smallSpacing,
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        'credential.date_at_time',
                        translationParams: {
                          'date': DateFormat.yMMMMd(lang).format(logEntry.time),
                          'time': DateFormat.jm(lang).format(logEntry.time),
                        },
                        style: theme.textTheme.bodyText2!.copyWith(
                          fontSize: 14,
                          fontFamily: theme.secondaryFontFamily,
                          color: theme.neutralExtraDark,
                        ),
                      ),
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.themeData.textTheme.headline4!.copyWith(
                          color: theme.dark,
                        ),
                      ),
                      TranslatedText(
                        subtitleTranslationKey,
                        style: theme.themeData.textTheme.bodyText2!.copyWith(
                          fontSize: 14,
                          color: theme.dark,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade700,
          ),
        ],
      ),
    );
  }
}
