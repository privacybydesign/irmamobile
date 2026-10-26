import "package:flutter/widgets.dart";

/// Shadows by role. The page and what lies on it (cards, rows, groups,
/// keys) are flat: a block stands out by its colour, one step lighter than
/// what it lies on, and by [YiviEdges.block] when the system asks for more
/// contrast. Only what floats above the page casts a shadow: the glass bars,
/// buttons and toasts (`palette.glassShadow`), sheets, and a card while it is
/// lifted (dragged, or flying in).
class YiviShadows {
  YiviShadows._();

  /// Under the glass lens on the selected tab (tab bar and rail).
  static const lens = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
