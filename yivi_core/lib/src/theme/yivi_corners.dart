import "package:flutter/widgets.dart";

/// Corner radii by role. Corners are plain circular arcs (no squircles):
/// draw them with [RoundedRectangleBorder] and clip with [ClipRRect].
class YiviCorners {
  YiviCorners._();

  /// Cards, grouped blocks, and picture and camera boxes.
  static const card = 12.0;

  /// Panes beside a list: on a tablet, and in phone landscape.
  static const pane = 18.0;

  /// Sheets and dialogs.
  static const sheet = 20.0;

  /// Large icon tiles (about 90 to 100 points).
  static const iconTile = 20.0;

  /// Small card pictures in a list.
  static const thumbnail = 6.0;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
}
