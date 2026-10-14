import "package:collection/collection.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart" hide Notification;

import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/irma_avatar.dart";
import "../../data/wallet/card_hero.dart";
import "../models/credential_status_notification.dart";
import "../models/notification.dart";
import "../models/notification_translated_content.dart";

class NotificationCard extends ConsumerWidget {
  final Notification notification;

  /// Called with the context of the card picture, so the detail view can
  /// open from it.
  final void Function(BuildContext pictureContext)? onTap;

  const NotificationCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    String title = "";
    String contentMessage = "";
    Widget? picture;
    IconData? icon;
    Color iconColor = palette.heading;

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
      final content = notification.content as InternalTranslatedContent;
      title = FlutterI18n.translate(
        context,
        content.titleTranslationKey,
        translationParams: {"credentialName": notification.credentialName},
      );
      contentMessage = FlutterI18n.translate(
        context,
        content.messageTranslationKey,
        translationParams: {
          "credentialName": notification.credentialName,
          "issuerName": notification.issuerName,
        },
      );
      (icon, iconColor) = switch (notification.type) {
        CredentialStatusNotificationType.expiringSoon => (
          Icons.schedule,
          palette.warningText,
        ),
        CredentialStatusNotificationType.expired => (
          Icons.warning_amber_rounded,
          palette.danger,
        ),
        CredentialStatusNotificationType.revoked => (
          Icons.block,
          palette.danger,
        ),
      };

      final card =
          (ref.watch(schemalessCredentialOrderControllerProvider).value ??
                  const [])
              .firstWhereOrNull((c) => c.hash == notification.credentialHash);
      if (card != null) {
        final greyed =
            notification.type != CredentialStatusNotificationType.expiringSoon;
        picture = greyed
            // An expired card is not the one in the list any more; keep it
            // out of the hero flight and just show it washed out.
            ? CredentialCardArt(credential: card, width: 64, greyedOut: true)
            : CardHero(credential: card, width: 64);
      } else {
        picture = IrmaAvatar(
          size: 48,
          initials: "i",
          logoImage: notification.logoImage == null
              ? null
              : Base64Image(
                  base64: notification.logoImage!.base64,
                  mimeType: notification.logoImage!.mimeType,
                ),
        );
      }
    }

    return Semantics(
      button: onTap != null,
      label: [
        title,
        contentMessage,
        localizedTimeStamp,
      ].where((s) => s.isNotEmpty).join(", "),
      excludeSemantics: true,
      child: Material(
        color: palette.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Builder(
          builder: (pictureContext) => InkWell(
            onTap: onTap == null ? null : () => onTap!(pictureContext),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  ?(picture == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: picture,
                        )),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedTimeStamp,
                          style: palette
                              .body(12)
                              .copyWith(color: palette.heading),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          spacing: 4,
                          children: [
                            if (icon != null)
                              Icon(icon, size: 16, color: iconColor),
                            Flexible(
                              child: Text(
                                title,
                                style: palette
                                    .display(16)
                                    .copyWith(color: palette.text),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(contentMessage, style: palette.body(14)),
                      ],
                    ),
                  ),
                  if (!notification.read)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
