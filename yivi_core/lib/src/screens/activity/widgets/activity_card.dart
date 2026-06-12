import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";

import "../../../models/log_entry.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../util/string.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_card.dart";
import "../../../widgets/translated_text.dart";

class ActivityCard extends StatelessWidget {
  final LogInfo logEntry;

  const ActivityCard({required this.logEntry});

  @override
  Widget build(BuildContext context) {
    final String lang = FlutterI18n.currentLocale(context)!.languageCode;
    final theme = IrmaTheme.of(context);

    String title = "";
    String subtitleTranslationKey = "";
    String semanticLabel = "";
    Widget? logoImage;

    final localizedTimeStamp = _formatActivityTimestamp(
      context,
      logEntry.time.toLocal(),
      lang,
    );

    if (logEntry.type == LogType.removal) {
      final firstCred = logEntry.removalLog!.credentials.first;
      title = firstCred.issuer.name.translate(lang);
      subtitleTranslationKey = "activity.data_deleted";
      semanticLabel = FlutterI18n.translate(
        context,
        "activity.data_deleted_semantics",
        translationParams: {"issuerName": title, "date": localizedTimeStamp},
      );

      logoImage = firstCred.image != null
          ? Base64Image(base64: firstCred.image!.base64)
          : null;
    } else {
      if (logEntry.type == LogType.issuance) {
        final serverName =
            logEntry.issuanceLog!.issuer?.name.translate(lang) ?? "";
        title = serverName;
        final issuerImage = logEntry.issuanceLog!.issuer?.image;
        logoImage = issuerImage != null
            ? Base64Image(base64: issuerImage.base64)
            : null;
        subtitleTranslationKey = "activity.data_received";
        semanticLabel = FlutterI18n.translate(
          context,
          "activity.data_received_semantics",
          translationParams: {"otherParty": title, "date": localizedTimeStamp},
        );
      } else if (logEntry.type == LogType.disclosure) {
        final serverName =
            logEntry.disclosureLog!.verifier?.name.translate(lang) ?? "";
        title = serverName;
        final verifierImage = logEntry.disclosureLog!.verifier?.image;
        logoImage = verifierImage != null
            ? Base64Image(base64: verifierImage.base64)
            : null;

        subtitleTranslationKey = "activity.data_shared";
        semanticLabel = FlutterI18n.translate(
          context,
          "activity.data_shared_semantics",
          translationParams: {"otherParty": title, "date": localizedTimeStamp},
        );
      } else if (logEntry.type == LogType.signature) {
        final serverName =
            logEntry.signedMessageLog!.verifier?.name.translate(lang) ?? "";
        title = serverName;
        final verifierImage = logEntry.signedMessageLog!.verifier?.image;
        logoImage = verifierImage != null
            ? Base64Image(base64: verifierImage.base64)
            : null;
        subtitleTranslationKey = "activity.message_signed";
        semanticLabel = FlutterI18n.translate(
          context,
          "activity.signed_message_semantics",
          translationParams: {"otherParty": title, "date": localizedTimeStamp},
        );
      }

      title = title.replaceBreakingHyphens();
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: IrmaCard(
        margin: EdgeInsets.zero,
        child: Material(
          child: InkWell(
            onTap: () => context.pushActivityDetailsScreen(logInfo: logEntry),
            child: Semantics(
              excludeSemantics: true,
              child: Padding(
                padding: EdgeInsets.all(theme.defaultSpacing),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IrmaAvatar(
                      size: 52,
                      logoImage: logoImage,
                      initials: title != "" ? title[0] : null,
                    ),
                    SizedBox(width: theme.smallSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.themeData.textTheme.headlineMedium!
                                .copyWith(fontSize: 18, color: theme.dark),
                          ),
                          TranslatedText(
                            subtitleTranslationKey,
                            style: theme.themeData.textTheme.bodyMedium!
                                .copyWith(
                                  fontSize: 14,
                                  color: theme.neutralExtraDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: theme.smallSpacing),
                    TranslatedText(
                      localizedTimeStamp,
                      style: theme.themeData.textTheme.bodyMedium!.copyWith(
                        fontSize: 14,
                        color: theme.neutralExtraDark,
                      ),
                    ),
                    SizedBox(width: theme.tinySpacing),
                    Icon(Icons.chevron_right, color: Colors.grey.shade700),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatActivityTimestamp(
  BuildContext context,
  DateTime time,
  String lang,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entryDay = DateTime(time.year, time.month, time.day);
  final daysAgo = today.difference(entryDay).inDays;

  if (daysAgo == 0) return DateFormat.jm(lang).format(time);
  if (daysAgo == 1) return FlutterI18n.translate(context, "activity.yesterday");
  return DateFormat.yMMMMd(lang).format(time);
}
