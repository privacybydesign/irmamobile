import "dart:typed_data";
import "dart:ui";

// A reflection on a laminated document clips the camera's highlights: where it
// crosses the MRZ, part of a line turns pure white and the characters under it wash
// out. On a clean MRZ the card's background stays well below clipping. Measured on a
// Galaxy S9, the worst tile of a clean MRZ had no clipped pixels at all, while 15 of
// 16 frames with a reflection on the MRZ had 21% to 57% clipped pixels in theirs.

/// Pixels at or above this brightness count as clipped.
const clippedBrightness = 250;

/// An MRZ tile with more than this share of clipped pixels has a reflection on it.
const glareTileShare = 0.10;

/// Each MRZ line is split into this many tiles: a reflection usually covers part of
/// a line, which a measurement over the whole line would average away.
const _tilesPerLine = 8;

/// Whether a reflection washes out part of the MRZ.
///
/// [luminance] is the camera frame's brightness plane as it comes from the sensor,
/// [width] by [height] pixels with [bytesPerRow] bytes per row. [rotation] is the
/// clockwise rotation in degrees that turns it upright, and [lineBoxes] are the MRZ
/// lines in that upright frame, as the OCR reports them.
bool mrzHasGlare({
  required Uint8List luminance,
  required int width,
  required int height,
  required int bytesPerRow,
  required int rotation,
  required List<Rect> lineBoxes,
}) {
  for (final box in lineBoxes) {
    final tileWidth = box.width / _tilesPerLine;
    for (var t = 0; t < _tilesPerLine; t++) {
      final tile = Rect.fromLTRB(
        box.left + t * tileWidth,
        box.top,
        box.left + (t + 1) * tileWidth,
        box.bottom,
      );
      final share = _clippedShare(
        luminance,
        width,
        height,
        bytesPerRow,
        rotation,
        tile,
      );
      if (share > glareTileShare) return true;
    }
  }
  return false;
}

/// Share of clipped pixels in [tile], given in upright coordinates. Samples every
/// other pixel in both directions, which is plenty for a share.
double _clippedShare(
  Uint8List luminance,
  int width,
  int height,
  int bytesPerRow,
  int rotation,
  Rect tile,
) {
  final uprightWidth = rotation % 180 == 0 ? width : height;
  final uprightHeight = rotation % 180 == 0 ? height : width;
  final left = tile.left.floor().clamp(0, uprightWidth);
  final right = tile.right.ceil().clamp(0, uprightWidth);
  final top = tile.top.floor().clamp(0, uprightHeight);
  final bottom = tile.bottom.ceil().clamp(0, uprightHeight);

  var sampled = 0;
  var clipped = 0;
  for (var y = top; y < bottom; y += 2) {
    for (var x = left; x < right; x += 2) {
      // Upright (x, y) back to the sensor frame, undoing the clockwise rotation.
      final (sx, sy) = switch (rotation) {
        90 => (y, height - 1 - x),
        180 => (width - 1 - x, height - 1 - y),
        270 => (width - 1 - y, x),
        _ => (x, y),
      };
      sampled++;
      if (luminance[sy * bytesPerRow + sx] >= clippedBrightness) clipped++;
    }
  }
  return sampled == 0 ? 0 : clipped / sampled;
}

/// Decides when the scanner shows its glare hint: once two of the last three
/// frames had glare on the MRZ, and until three frames in a row had none. A single
/// frame does not flip it, so the hint does not flicker while the document moves.
class GlareHint {
  final _recent = <bool>[];
  bool _showing = false;

  bool get showing => _showing;

  /// Records whether the latest frame had glare and returns whether to show the
  /// hint.
  bool update(bool glare) {
    _recent.add(glare);
    if (_recent.length > 3) _recent.removeAt(0);
    final withGlare = _recent.where((g) => g).length;
    if (!_showing && withGlare >= 2) {
      _showing = true;
    } else if (_showing && _recent.length == 3 && withGlare == 0) {
      _showing = false;
    }
    return _showing;
  }

  /// Forgets the frames seen so far. Call this when a new scan starts.
  void reset() {
    _recent.clear();
    _showing = false;
  }
}
