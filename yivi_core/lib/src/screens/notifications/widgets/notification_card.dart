import "package:collection/collection.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:material_ui/material_ui.dart" hide Notification;

import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../theme/yivi_tone.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/surfaces/avatar.dart";
import "../../../widgets/surfaces/base64_image.dart";
import "../../../widgets/surfaces/surface_card.dart";
import "../../data/card_transition/card_slots.dart";
import "../models/credential_status_notification.dart";
import "../models/notification.dart";

class NotificationCard extends ConsumerWidget {
  final Notification notification;

  /// Called with the context of the card picture, so the detail view can
  /// open from it.
  final void Function(BuildContext pictureContext) onTap;

  /// Whether the detail pane shows this notification's card: the row gets a
  /// red border.
  final bool selected;

  const NotificationCard({
    required this.notification,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final lang = context.lang;

    String title = "";
    String contentMessage = "";
    Widget? picture;
    IconData? icon;
    Color iconColor = palette.heading;

    final notification =
        this.notification; // To prevent the need for type casting.
    final localizedTimeStamp = context.tr("credential.date_at_time", {
      "date": DateFormat.yMMMMd(lang).format(notification.timestamp),
      "time": DateFormat.jm(lang).format(notification.timestamp),
    });

    if (notification is CredentialStatusNotification) {
      title = context.tr(notification.titleKey, {
        "credentialName": notification.credentialName,
      });
      contentMessage = context.tr(notification.messageKey, {
        "credentialName": notification.credentialName,
        "issuerName": notification.issuerName,
      });
      final (kindIcon, tone) = notification.type.look;
      icon = kindIcon;
      iconColor = palette.tone(tone).$2;

      final card = (ref.watch(
        walletCardsProvider,
      )).firstWhereOrNull((c) => c.hash == notification.credentialHash);
      if (card != null) {
        final greyed =
            notification.type != CredentialStatusNotificationType.expiringSoon;
        picture = CardSlot(
          hash: card.hash,
          view: CardSlotView.notifications,
          // An expired card is shown washed out; opened, the card flies as it
          // is in the wallet (the grey goes at take-off).
          child: CardSlotPicture(
            child: CredentialCardArt(
              credential: card,
              width: 64,
              greyedOut: greyed,
            ),
          ),
        );
      } else {
        picture = Avatar(
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
      button: true,
      label: [
        title,
        contentMessage,
        localizedTimeStamp,
      ].where((s) => s.isNotEmpty).join(", "),
      excludeSemantics: true,
      child: Builder(
        builder: (pictureContext) => SurfaceCard(
          selected: selected,
          onTap: () => onTap(pictureContext),
          padding: const EdgeInsets.all(YiviSpace.x16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: YiviSpace.x16,
            children: [
              ?(picture == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: YiviSpace.x4),
                      child: picture,
                    )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedTimeStamp,
                      style: palette.body(12).copyWith(color: palette.heading),
                    ),
                    const SizedBox(height: YiviSpace.x2),
                    Row(
                      spacing: YiviSpace.x4,
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
                    const SizedBox(height: YiviSpace.x2),
                    Text(contentMessage, style: palette.body(14)),
                  ],
                ),
              ),
              if (!notification.read)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: YiviSpace.x4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The icon and tone of each kind of notification: on its card and in the
/// picture of the empty Notifications tab.
extension NotificationLook on CredentialStatusNotificationType {
  (IconData, YiviTone) get look => switch (this) {
    CredentialStatusNotificationType.expiringSoon => (
      Icons.schedule,
      YiviTone.warning,
    ),
    CredentialStatusNotificationType.expired => (
      Icons.warning_amber_rounded,
      YiviTone.danger,
    ),
    CredentialStatusNotificationType.revoked => (Icons.block, YiviTone.danger),
  };
}
