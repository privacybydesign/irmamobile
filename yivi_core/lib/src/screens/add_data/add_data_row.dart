import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../theme/yivi_palette.dart";
import "../../util/i18n.dart";
import "../../widgets/credential_card/credential_type_thumbnail.dart";

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
  static const dividerIndent = 16.0 + 56 + 14;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final credential = item.credential;
    final subtitle = nfcBlocked
        ? context.tr("data.add.nfc_unsupported.hint")
        : credential.issuer.name;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: [
        credential.name,
        subtitle,
        if (owned && !nfcBlocked) context.tr("data.add.in_your_app"),
      ].join(", "),
      onTap: onTap,
      child: Opacity(
        opacity: nfcBlocked ? 0.5 : 1,
        child: InkWell(
          key: Key("${credential.credentialId}_tile"),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                spacing: 14,
                children: [
                  CredentialTypeThumbnail(
                    descriptor: credential,
                    owned: owned && !nfcBlocked,
                    greyedOut: nfcBlocked,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.name,
                          style: palette
                              .display(15.5)
                              .copyWith(height: 21 / 15.5, color: palette.text),
                        ),
                        Text(
                          subtitle,
                          key: Key("${credential.credentialId}_subtitle"),
                          maxLines: nfcBlocked ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .body(13)
                              .copyWith(color: palette.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: palette.faint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
