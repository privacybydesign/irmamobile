import "package:flutter/widgets.dart";

import "yivi_palette.dart";

/// Outlines of the flat blocks on a page.
class YiviEdges {
  YiviEdges._();

  /// The outline of a block (a card, a group, a key) on the page: none, as
  /// its colour sets it off; with Increase Contrast on, a line of at least
  /// 3:1 on the page, the sheet and the block itself.
  static BorderSide block(BuildContext context) =>
      MediaQuery.highContrastOf(context)
      ? BorderSide(
          color: YiviPalette.of(context).isDark
              ? const Color(0xFF7A7C80)
              : const Color(0xFF7F8387),
        )
      : BorderSide.none;
}
