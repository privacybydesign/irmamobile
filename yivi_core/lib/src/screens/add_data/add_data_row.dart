import "package:material_ui/material_ui.dart";

import "../../models/credential_store.dart";
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
  final VoidCallback onTap;

  const AddDataRow({
    super.key,
    required this.item,
    required this.nfcBlocked,
    required this.owned,
    required this.onTap,
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
        subtitle: subtitle,
        subtitleKey: Key("${credential.credentialId}_subtitle"),
        subtitleMaxLines: nfcBlocked ? 3 : 1,
        semanticsLabel: [
          credential.name,
          subtitle,
          if (owned && !nfcBlocked) context.tr("data.add.in_your_app"),
        ].join(", "),
        onTap: onTap,
      ),
    );
  }
}
