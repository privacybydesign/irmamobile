import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../theme/yivi_palette.dart";
import "../dashed_outline_painter.dart";
import "card_tile.dart";
import "credential_type_thumbnail.dart";

/// The picture of a card that is not in the app yet: the card itself,
/// faded (40%, less colour), under a "+" in a small white circle; a dashed
/// box when the type has no picture. A block sign when it cannot be added.
class FadedCardArt extends StatelessWidget {
  final CredentialDescriptor? descriptor;
  final bool canAdd;

  const FadedCardArt({super.key, required this.descriptor, this.canAdd = true});

  /// Less colour: 60% saturation, as the prototype's `saturate(.6)`.
  static const _saturate = ColorFilter.matrix([
    0.7364, 0.2862, 0.0288, 0, 0, //
    0.0852, 0.9372, 0.0288, 0, 0, //
    0.0852, 0.2862, 0.6798, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final d = descriptor;
    final mark = canAdd
        ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.92),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, size: 16, color: palette.link),
          )
        : Icon(Icons.block_rounded, size: 18, color: palette.secondaryText);
    return SizedBox(
      width: CardTile.miniWidth,
      height: CardTile.miniHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (d != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: ColorFiltered(
                  colorFilter: _saturate,
                  child: CredentialTypeThumbnail(
                    descriptor: d,
                    width: CardTile.miniWidth,
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: CustomPaint(
                painter: DashedOutlinePainter(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                  color: palette.secondaryText.withValues(alpha: 0.6),
                  dash: 4,
                  period: 7,
                ),
              ),
            ),
          mark,
        ],
      ),
    );
  }
}
