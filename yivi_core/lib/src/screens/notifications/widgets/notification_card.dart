import "package:flutter/material.dart" hide Notification;
import "package:flutter_i18n/flutter_i18n.dart";
import "package:intl/intl.dart";

import "../../../theme/theme.dart";
import "../../../util/language.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/irma_avatar.dart";
import "../../../widgets/irma_card.dart";
import "../models/credential_status_notification.dart";
import "../models/notification.dart";
import "../models/notification_translated_content.dart";

class NotificationCard extends StatelessWidget {
  final Notification notification;
  final Function()? onTap;

  const NotificationCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    String title = "";
    String contentMessage = "";
    Widget? logo;

    final notification =
        this.notification; // To prevent the need for type casting.
    final localizedTimeStamp = FlutterI18n.translate(
      context,
      "credential.date_at_time",
      translationParams: {
        "date": DateFormat.yMMMMd(lang).format(notification.timestamp),
        "time": DateFormat.jm(lang).format(notification.timestamp),
      },
    );

    if (notification is CredentialStatusNotification) {
      final translatedCredName = getTranslation(
        context,
        notification.credentialName,
      );
      final translatedIssuerName = getTranslation(
        context,
        notification.issuerName,
      );

      logo = notification.logoImage != null
          ? Base64Image(base64: notification.logoImage!.base64)
          : null;
      final content = notification.content as InternalTranslatedContent;

      title = FlutterI18n.translate(
        context,
        content.titleTranslationKey,
        translationParams: {"credentialName": translatedCredName},
      );

      contentMessage = FlutterI18n.translate(
        context,
        content.messageTranslationKey,
        translationParams: {
          "credentialName": translatedCredName,
          "issuerName": translatedIssuerName,
        },
      );
    }

    return IrmaCard(
      onTap: onTap,
      child: Stack(
        children: [
          if (!notification.read)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primary,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IrmaAvatar(size: 52, initials: "i", logoImage: logo),
                    SizedBox(width: context.yivi.spacing.small),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(localizedTimeStamp),
                          Text(title, style: context.yivi.activity.cardTitle),
                          Text(
                            contentMessage,
                            style: context.yivi.card.notificationBody,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
