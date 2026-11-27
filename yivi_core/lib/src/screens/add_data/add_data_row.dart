import "package:material_ui/material_ui.dart";

import "../../models/credential_store.dart";
import "../../theme/yivi_palette.dart";
import "../../util/i18n.dart";
import "../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../widgets/surfaces/list_row.dart";

/// One credential type to add: its card, small (with a check when the user
/// has one already, [owned]), its name, and the issuer, after "Needs NFC"
/// for documents. Greyed out when it needs NFC the device lacks.
class AddDataRow extends StatelessWidget {
  final CredentialStoreItem item;

  /// Needs NFC the device does not have: greyed out, with the reason under
  /// the name and as a screen-reader hint.
  final bool nfcBlocked;

  /// The user has a card of this type already.
  final bool owned;

  /// The e-mail card, while no address is linked: adding it also secures the
  /// app, and the row says so.
  final bool securesApp;
  final VoidCallback onTap;

  const AddDataRow({
    super.key,
    required this.item,
    required this.nfcBlocked,
    required this.owned,
    required this.onTap,
    this.securesApp = false,
  });

  /// Where a divider between rows starts: past the card.
  static const dividerIndent =
      ListRow.side + CredentialTypeThumbnail.defaultWidth + ListRow.gap;

  @override
  Widget build(BuildContext context) {
    final credential = item.credential;
    final subtitle = nfcBlocked
        ? context.tr("data.add.nfc_unsupported.hint")
        : credential.issuer.name;

    return Opacity(
      opacity: nfcBlocked ? 0.5 : 1,
      child: ListRow(
        key: Key("${credential.credentialId}_tile"),
        leading: CredentialTypeThumbnail(
          descriptor: credential,
          owned: owned && !nfcBlocked,
          greyedOut: nfcBlocked,
        ),
        title: credential.name,
        titleWeight: FontWeight.w600,
        subtitle: subtitle,
        subtitleKey: Key("${credential.credentialId}_subtitle"),
        subtitleMaxLines: nfcBlocked ? 3 : 1,
        below: securesApp && !nfcBlocked ? const SecuresAppChip() : null,
        semanticsLabel: [
          credential.name,
          subtitle,
          if (owned && !nfcBlocked) context.tr("data.add.in_your_app"),
          if (securesApp && !nfcBlocked) context.tr("secure.chip"),
        ].join(", "),
        onTap: onTap,
      ),
    );
  }
}

/// "Also secures your app": a small green tag with a shield.
class SecuresAppChip extends StatelessWidget {
  /// Centred in its row, under centred words; else at the start.
  final bool center;

  const SecuresAppChip({super.key, this.center = false});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ExcludeSemantics(
      child: Align(
        alignment: center
            ? AlignmentDirectional.center
            : AlignmentDirectional.centerStart,
        child: DecoratedBox(
          key: const Key("secures_app_chip"),
          decoration: BoxDecoration(
            color: palette.successSurface,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: palette.successText,
                ),
                Text(
                  context.tr("secure.chip"),
                  style: palette
                      .body(12, weight: FontWeight.w600)
                      .copyWith(color: palette.successText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
