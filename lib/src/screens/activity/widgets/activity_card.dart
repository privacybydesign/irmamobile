import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:intl/intl.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
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
    File logoFile = File('');

    switch (logEntry.type) {
      case LogEntryType.disclosing:
      case LogEntryType.signing:
        if (logEntry.serverName != null) {
          title = logEntry.serverName!.name.translate(lang);
          if (logEntry.serverName!.logo != null) {
            logoFile = File(logEntry.serverName!.logo!);
          }
        }
        subtitleTranslationKey =
            logEntry.type == LogEntryType.disclosing ? 'activity.data_shared' : 'activity.message_signed';
        break;
      case LogEntryType.issuing:
        final cred = Credential.fromRaw(
          irmaConfiguration: irmaConfiguration,
          rawCredential: logEntry.issuedCredentials.first,
        );
        if (irmaConfiguration.issuers[cred.info.issuer.fullId] != null) {
          title = irmaConfiguration.issuers[cred.info.issuer.fullId]!.name.translate(lang);
        }
        subtitleTranslationKey = 'activity.data_received';
        if (cred.info.credentialType.logo != null) {
          logoFile = File(
            cred.info.credentialType.logo!,
          );
        }
        break;
      case LogEntryType.removal:
        final credType = irmaConfiguration.credentialTypes[logEntry.removedCredentials.keys.first]!;
        title = irmaConfiguration.issuers[credType.fullIssuerId]!.name.translate(lang);
        subtitleTranslationKey = 'activity.data_deleted';
        if (credType.logo != null) {
          logoFile = File(
            credType.logo!,
          );
        }
        break;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(
                    right: theme.smallSpacing,
                    top: theme.smallSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(theme.smallSpacing),
                    height: 56,
                    width: 56,
                    child: logoFile.existsSync()
                        ? SizedBox(height: 24, child: Image.file(logoFile, excludeFromSemantics: true))
                        : null,
                  ),
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
                        style: theme.themeData.textTheme.caption!.copyWith(color: theme.neutral),
                      ),
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.themeData.textTheme.caption!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TranslatedText(
                        subtitleTranslationKey,
                        style: theme.themeData.textTheme.caption,
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
