import "dart:typed_data";
import "dart:ui";

import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/mrz_glare.dart";

/// An upright frame as rows of brightness values.
typedef _Image = List<List<int>>;

_Image _blank(int width, int height, int value) =>
    List.generate(height, (_) => List.filled(width, value));

void _fill(_Image image, Rect area, int value) {
  for (var y = area.top.toInt(); y < area.bottom.toInt(); y++) {
    for (var x = area.left.toInt(); x < area.right.toInt(); x++) {
      image[y][x] = value;
    }
  }
}

/// Rotates [image] a quarter turn clockwise.
_Image _rotateClockwise(_Image image) {
  final height = image.length;
  final width = image.first.length;
  return List.generate(
    width,
    (y) => List.generate(height, (x) => image[height - 1 - x][y]),
  );
}

/// Whether [mrzHasGlare] sees glare when the sensor delivers [upright] such that
/// it needs [rotation] degrees clockwise to be upright again.
bool _hasGlare(_Image upright, int rotation, List<Rect> lineBoxes) {
  var sensor = upright;
  for (var i = 0; i < (360 - rotation) % 360 ~/ 90; i++) {
    sensor = _rotateClockwise(sensor);
  }
  final height = sensor.length;
  final width = sensor.first.length;
  // Rows padded beyond the frame width, as camera planes often are.
  final bytesPerRow = width + 7;
  final luminance = Uint8List(bytesPerRow * height);
  for (var y = 0; y < height; y++) {
    luminance.setRange(y * bytesPerRow, y * bytesPerRow + width, sensor[y]);
  }
  return mrzHasGlare(
    luminance: luminance,
    width: width,
    height: height,
    bytesPerRow: bytesPerRow,
    rotation: rotation,
    lineBoxes: lineBoxes,
  );
}

void main() {
  // An upright frame with one MRZ line; its 8 tiles are 10 pixels wide.
  const lineBox = Rect.fromLTRB(10, 20, 90, 30);

  group("mrzHasGlare", () {
    for (final rotation in [0, 90, 180, 270]) {
      test("finds a reflection on the MRZ at $rotation degrees", () {
        final frame = _blank(100, 50, 200);
        _fill(frame, const Rect.fromLTRB(40, 20, 44, 30), 255);
        expect(_hasGlare(frame, rotation, [lineBox]), isTrue);
      });

      test("ignores a reflection off the MRZ at $rotation degrees", () {
        final frame = _blank(100, 50, 200);
        _fill(frame, const Rect.fromLTRB(40, 0, 60, 15), 255);
        expect(_hasGlare(frame, rotation, [lineBox]), isFalse);
      });
    }

    test("does not count bright pixels below clipping", () {
      final frame = _blank(100, 50, clippedBrightness - 1);
      expect(_hasGlare(frame, 90, [lineBox]), isFalse);
    });

    test("ignores a few clipped pixels in a tile", () {
      // A 2x2 speck: 1 of the 25 pixels sampled in its tile, below 10%.
      final frame = _blank(100, 50, 200);
      _fill(frame, const Rect.fromLTRB(40, 20, 42, 22), 255);
      expect(_hasGlare(frame, 0, [lineBox]), isFalse);
    });

    test("finds nothing without MRZ lines", () {
      final frame = _blank(100, 50, 255);
      expect(_hasGlare(frame, 90, []), isFalse);
    });

    test("stays inside the frame for a box reaching past its edge", () {
      final frame = _blank(100, 50, 200);
      _fill(frame, const Rect.fromLTRB(90, 40, 100, 50), 255);
      expect(
        _hasGlare(frame, 90, [const Rect.fromLTRB(60, 40, 140, 70)]),
        isTrue,
      );
    });
  });

  group("GlareHint", () {
    test("does not show for a single frame with glare", () {
      final hint = GlareHint();
      expect(hint.update(Reflection.present), isFalse);
      expect(hint.update(Reflection.absent), isFalse);
      expect(hint.update(Reflection.absent), isFalse);
    });

    test("shows once two of the last three frames had glare", () {
      final hint = GlareHint();
      hint.update(Reflection.present);
      hint.update(Reflection.absent);
      expect(hint.update(Reflection.present), isTrue);
    });

    test("stays until three frames in a row had none", () {
      final hint = GlareHint();
      hint.update(Reflection.present);
      hint.update(Reflection.present);
      expect(hint.update(Reflection.absent), isTrue);
      expect(hint.update(Reflection.absent), isTrue);
      expect(hint.update(Reflection.absent), isFalse);
    });

    test("starts over after a reset", () {
      final hint = GlareHint();
      hint.update(Reflection.present);
      hint.update(Reflection.present);
      hint.reset();
      expect(hint.showing, isFalse);
      expect(hint.update(Reflection.present), isFalse);
    });
  });
}
