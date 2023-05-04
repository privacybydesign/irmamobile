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
    String semanticLabel = '';
    String? logo;

    final localizedTimeStamp = FlutterI18n.translate(
      context,
      'credential.date_at_time',
      translationParams: {
        'date': DateFormat.yMMMMd(lang).format(logEntry.time),
        'time': DateFormat.jm(lang).format(logEntry.time),
      },
    );

    if (logEntry.type == LogEntryType.removal) {
      final credType = irmaConfiguration.credentialTypes[logEntry.removedCredentials.keys.first]!;
      title = irmaConfiguration.issuers[credType.fullIssuerId]!.name.translate(lang);
      subtitleTranslationKey = 'activity.data_deleted';
      semanticLabel = FlutterI18n.translate(
        context,
        'activity.data_deleted_semantics',
        translationParams: {
          'issuerName': title,
          'date': localizedTimeStamp,
        },
      );

      if (credType.logo != null) {
        logo = credType.logo;
      }
    } else {
      String? serverName;
      if (logEntry.serverName != null) {
        serverName = logEntry.serverName!.name.translate(lang);
        title = serverName;
        if (logEntry.serverName!.logoPath != null) {
          logo = logEntry.serverName!.logoPath;
        }
      }

      if (logEntry.type == LogEntryType.issuing) {
        subtitleTranslationKey = 'activity.data_received';
        semanticLabel = FlutterI18n.translate(
          context,
          'activity.data_received_semantics',
          translationParams: {
            'otherParty': title,
            'date': localizedTimeStamp,
          },
        );
      } else if (logEntry.type == LogEntryType.disclosing) {
        subtitleTranslationKey = 'activity.data_shared';
        semanticLabel = FlutterI18n.translate(
          context,
          'activity.data_shared_semantics',
          translationParams: {
            'otherParty': title,
            'date': localizedTimeStamp,
          },
        );
      } else if (logEntry.type == LogEntryType.signing) {
        subtitleTranslationKey = 'activity.message_signed';
        semanticLabel = FlutterI18n.translate(
          context,
          'activity.signed_message_semantics',
          translationParams: {
            'otherParty': title,
            'date': localizedTimeStamp,
          },
        );
      }
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: IrmaCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(
              logEntry: logEntry,
              irmaConfiguration: irmaConfiguration,
            ),
          ),
        ),
        child: Semantics(
          excludeSemantics: true,
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
                      initials: title != '' ? title[0] : null,
                    ),
                    SizedBox(
                      width: theme.smallSpacing,
                    ),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(localizedTimeStamp),
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.themeData.textTheme.headlineMedium!.copyWith(
                              color: theme.dark,
                            ),
                          ),
                          TranslatedText(
                            subtitleTranslationKey,
                            style: theme.themeData.textTheme.bodyMedium!.copyWith(
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
        ),
      ),
    );
  }
}
