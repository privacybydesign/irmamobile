import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/log_entry.dart';
import 'package:irmamobile/src/screens/activity/activity_detail_screen.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/date_formatter.dart';
import 'package:irmamobile/src/widgets/translated_text.dart';

class ActivityCard extends StatelessWidget {
  final LogEntry logEntry;
  final IrmaConfiguration irmaConfiguration;

  const ActivityCard({required this.logEntry, required this.irmaConfiguration});

  @override
  Widget build(BuildContext context) {
    final String lang = FlutterI18n.currentLocale(context)!.languageCode;

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
                .logo!);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailScreen(logEntry: logEntry, irmaConfiguration: irmaConfiguration),
          )),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 4)]),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Container(
                        padding: const EdgeInsets.all(8.0),
                        height: 48,
                        width: 48,
                        child: logoFile.existsSync()
                            ? SizedBox(height: 24, child: Image.file(logoFile, excludeFromSemantics: true))
                            : null),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            overflow: TextOverflow.ellipsis,
                            style: IrmaTheme.of(context)
                                .themeData
                                .textTheme
                                .caption!
                                .copyWith(fontWeight: FontWeight.bold)),
                        Text(formatDate(logEntry.time, lang),
                            style: IrmaTheme.of(context).themeData.textTheme.bodyText2!.copyWith(fontSize: 12)),
                        TranslatedText(subtitleTranslationKey, style: IrmaTheme.of(context).themeData.textTheme.caption)
                      ],
                    ),
                  )
                ],
              ),
            ),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.chevron_right),
            )
          ],
        ),
      ),
    );
  }
}
