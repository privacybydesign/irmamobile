import "package:material_ui/material_ui.dart";

import "../../../models/log_entry.dart";
import "../../../models/session_state.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "../../../widgets/credential_card/card_attribute_list.dart";

/// The values of [card] as the disclosure screens show them: the app's
/// attribute list without a card around it, the name above each value. A
/// card shared without values is one row: its name above "Alleen dat je dit
/// kaartje hebt". A value [requestor] keeps gets a marker.
class DisclosureValueList extends StatelessWidget {
  final SelectableCredentialInstance card;
  final String requestor;

  /// Whether nested values fold (the overview and the change page); never in
  /// a sheet, where cards are compared.
  final bool foldable;

  const DisclosureValueList({
    super.key,
    required this.card,
    required this.requestor,
    this.foldable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (card.attributes.isEmpty) {
      final palette = YiviPalette.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.name, style: attributeLabelStyle(context)),
            Text(
              context.tr("share.values.bare"),
              style: attributeValueStyle(context, palette.text),
            ),
          ],
        ),
      );
    }
    return CardAttributeList(
      card.attributes,
      credentialId: card.credentialId,
      namespaced: card.format == CredentialFormat.msoMdoc,
      disclosure: true,
      foldable: foldable,
      ageDisplay: AgeDisplay.collapsed,
      keptLabel: context.tr("share.keep.marker_label", {
        "requestor": requestor,
      }),
    );
  }
}
