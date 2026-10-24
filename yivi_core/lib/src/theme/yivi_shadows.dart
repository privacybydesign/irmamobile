import "package:flutter/widgets.dart";

import "yivi_corners.dart";
import "yivi_palette.dart";

/// Shadows by role.
class YiviShadows {
  YiviShadows._();

  static const _card = BoxShadow(
    color: Color(0x17000000),
    blurRadius: 6,
    offset: Offset(0, 1),
  );
  static const _cardDark = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 6,
    offset: Offset(0, 1),
  );

  /// The soft shadow under a white card, a pill or a tile: the same in both
  /// themes.
  static const card = [_card];

  /// The card shadow, but darker in the dark theme, for the grouped blocks
  /// (`GlassGroup`), `IrmaCard` and the welcome card.
  static BoxShadow cardIn({required bool dark}) => dark ? _cardDark : _card;

  /// Under the glass lens on the selected tab (tab bar and rail).
  static const lens = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// A white card with the card corner and [card] under it.
  static ShapeDecoration surfaceCard(YiviPalette palette) => ShapeDecoration(
    color: palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: YiviCorners.cardRadius),
    shadows: card,
  );
}
