import "dart:math";

import "package:material_ui/material_ui.dart";

import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/slot_registry.dart";
import "card_transition_layer.dart";
import "choreography.dart";

/// Where the Data tab's stack draws its cards, by place: what a card
/// transition measures when one is tapped.
abstract final class StackCards {
  static final slots = SlotRegistry<int>();

  /// The cards' hashes, by place, as the stack last built them.
  static List<String> hashes = const [];

  /// The snapshot for opening the card at [picked], or null when the stack
  /// is not all laid out (then the card opens without this transition).
  static TransitionSnapshot? snapshot(BuildContext context, int picked) {
    final rects = <Rect>[];
    for (var i = 0; i < hashes.length; i++) {
      final slot = slots[i];
      final box = slot != null && slot.mounted ? slot.findRenderObject() : null;
      if (box is! RenderBox || !box.hasSize || !box.attached) return null;
      rects.add(box.localToGlobal(Offset.zero) & box.size);
    }
    if (picked < 0 || picked >= rects.length) return null;
    final screen = MediaQuery.sizeOf(context);
    final width = min(
      screen.width - 32,
      OpenCardLayer.detailsMaxWidth,
    ).toDouble();
    return TransitionSnapshot(
      picked: picked,
      cards: rects,
      target: Rect.fromLTWH(
        (screen.width - width) / 2,
        MediaQuery.paddingOf(context).top + IrmaAppBar.contentTop,
        width,
        width / CredentialCardArt.aspectRatio,
      ),
      screenHeight: screen.height,
    );
  }
}
