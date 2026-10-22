import "package:material_ui/material_ui.dart";

/// The dimmed camera around the scan window and the window's corner
/// brackets: dimmed in dark grey, or green after a Yivi QR code and red
/// after another code, with the window itself lightly tinted to match.
class QROverlay extends CustomPainter {
  /// Where the window is, in the painter's coordinates.
  final Rect window;

  /// QR code found
  final bool found;

  /// wrong QR code found
  final bool error;

  /// How far the brackets are moved sideways, for the shake after a wrong
  /// code.
  final double shake;

  QROverlay({
    required this.window,
    required this.found,
    required this.error,
    this.shake = 0,
  });

  static const radius = 16.0;
  static const _bracket = 38.0;
  static const _stroke = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      window,
      const Radius.circular(radius),
    );

    final (overlayColor, tint, cornerColor) = error
        ? (
            const Color(0x9E300808),
            const Color(0x29BD1919),
            const Color(0xFFFF6B6B),
          )
        : found
        ? (
            const Color(0x9E062816),
            const Color(0x3821915A),
            const Color(0xFF3DD07A),
          )
        : (const Color(0x940A0C0E), null, Colors.white);

    // Punch the scan window out of the dimming overlay using BlendMode.clear.
    // This must happen inside its own offscreen layer: BlendMode.clear writes
    // fully-transparent pixels into the layer it draws into, so without
    // saveLayer it would clear against the opaque root surface and the hole
    // would render as solid black (the camera preview is a sibling Flutter
    // texture drawn below this painter, not a platform view behind the
    // surface). saveLayer gives us a real RGBA buffer whose transparent hole
    // composites correctly over the camera texture.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = overlayColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0x00000000)
        ..blendMode = BlendMode.clear,
    );
    canvas.restore();
    if (tint != null) canvas.drawRRect(rrect, Paint()..color = tint);

    // Corner brackets just outside the window, round its corners.
    final frame = window.inflate(_stroke / 2).shift(Offset(shake, 0));
    final r = radius + _stroke / 2;
    final rr = Radius.circular(r);
    final left = frame.left, top = frame.top;
    final right = frame.right, bottom = frame.bottom;
    final corners = Path()
      ..moveTo(left, top + _bracket)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: rr)
      ..lineTo(left + _bracket, top)
      ..moveTo(right - _bracket, top)
      ..lineTo(right - r, top)
      ..arcToPoint(Offset(right, top + r), radius: rr)
      ..lineTo(right, top + _bracket)
      ..moveTo(right, bottom - _bracket)
      ..lineTo(right, bottom - r)
      ..arcToPoint(Offset(right - r, bottom), radius: rr)
      ..lineTo(right - _bracket, bottom)
      ..moveTo(left + _bracket, bottom)
      ..lineTo(left + r, bottom)
      ..arcToPoint(Offset(left, bottom - r), radius: rr)
      ..lineTo(left, bottom - _bracket);
    canvas.drawPath(
      corners,
      Paint()
        ..color = cornerColor
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(QROverlay old) =>
      old.window != window ||
      old.found != found ||
      old.error != error ||
      old.shake != shake;
}
