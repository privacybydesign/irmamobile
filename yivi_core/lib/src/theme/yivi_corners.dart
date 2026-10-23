import "package:flutter/widgets.dart";

/// Corner radii by role. Corners are plain circular arcs (no squircles):
/// draw them with [RoundedRectangleBorder] and clip with [ClipRRect].
class YiviCorners {
  YiviCorners._();

  /// Cards, grouped blocks, and picture and camera boxes.
  static const card = 12.0;

  /// Panes beside a list: on a tablet, and in phone landscape.
  static const pane = 18.0;

  /// Sheets (and the tablet's form-sheet pages): concentric with the round
  /// 44 close and back buttons 16 in from their edges (22 + 16), as a native
  /// iOS sheet.
  static const sheet = 38.0;

  /// Dialogs and tip bubbles.
  static const dialog = 20.0;

  /// Large icon tiles (about 90 to 100 points).
  static const iconTile = 20.0;

  /// Small card pictures in a list.
  static const thumbnail = 6.0;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
}
