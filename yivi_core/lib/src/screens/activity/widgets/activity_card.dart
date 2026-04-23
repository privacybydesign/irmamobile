import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";

import "../../../models/log_entry.dart";
import "../../../theme/theme.dart";
import "../../../util/navigation.dart";
import "../../../util/string.dart";
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
    Image? logoImage;

    final localizedTimeStamp = FlutterI18n.translate(
      context,
      "credential.date_at_time",
      translationParams: {
        "date": DateFormat.yMMMMd(lang).format(logEntry.time),
        "time": DateFormat.jm(lang).format(logEntry.time),
      },
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

      logoImage = firstCred.image?.getImageFromBase64();
    } else {
      if (logEntry.type == LogType.issuance) {
        final serverName =
            logEntry.issuanceLog!.issuer?.name.translate(lang) ?? "";
        title = serverName;
        logoImage = logEntry.issuanceLog!.issuer?.image?.getImageFromBase64();
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
        logoImage =
            logEntry.disclosureLog!.verifier?.image?.getImageFromBase64();

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
        logoImage =
            logEntry.signedMessageLog!.verifier?.image?.getImageFromBase64();
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IrmaAvatar(
                            size: 52,
                            logoImage: logoImage,
                            initials: title != "" ? title[0] : null,
                          ),
                          SizedBox(width: theme.smallSpacing),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TranslatedText(localizedTimeStamp),
                                Text(
                                  title,
                                  style: theme
                                      .themeData
                                      .textTheme
                                      .headlineMedium!
                                      .copyWith(color: theme.dark),
                                ),
                                TranslatedText(
                                  subtitleTranslationKey,
                                  style: theme.themeData.textTheme.bodyMedium!
                                      .copyWith(
                                        fontSize: 14,
                                        color: theme.dark,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
