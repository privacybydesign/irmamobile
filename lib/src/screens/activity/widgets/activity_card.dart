import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../models/credentials.dart';
import '../../../models/irma_configuration.dart';
import '../../../models/log_entry.dart';
import '../../../theme/theme.dart';
import '../../../util/date_formatter.dart';
import '../../../widgets/translated_text.dart';
import '../activity_detail_screen.dart';
import '../../../widgets/card/irma_card.dart';

class ActivityCard extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityCard({required this.logEntry, required this.irmaConfiguration});

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
      case LogEntryType.removal:
        if (irmaConfiguration.issuers[logEntry.issuedCredentials.first.fullIssuerId] != null) {
          title = irmaConfiguration.issuers[logEntry.issuedCredentials.first.fullIssuerId]!.name.translate(lang);
        }
        subtitleTranslationKey =
            logEntry.type == LogEntryType.issuing ? 'activity.data_received' : 'activity.data_deleted';
        logoFile = File(
          Credential.fromRaw(irmaConfiguration: irmaConfiguration, rawCredential: logEntry.issuedCredentials.first)
              .info
              .credentialType
              .logo!,
        );
    }

    return IrmaCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(
                  logEntry: logEntry,
                  irmaConfiguration: irmaConfiguration,
                )),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: theme.tinySpacing),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(8),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(theme.smallSpacing),
                  height: 48,
                  width: 48,
                  child: logoFile.existsSync()
                      ? SizedBox(height: 24, child: Image.file(logoFile, excludeFromSemantics: true))
                      : null,
                ),
              ),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.themeData.textTheme.caption!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatDate(logEntry.time, lang),
                      style: theme.themeData.textTheme.bodyText2!.copyWith(fontSize: 12),
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
      ]),
    );
  }
}
