import "package:material_ui/material_ui.dart";

/// The dimmed camera around the scan window and the window's corner
/// brackets, as in the design: a 300 pt window with 40 pt corners and 56 pt
/// brackets, dimmed in dark grey, or green after a Yivi QR code and red after
/// another code.
class QROverlay extends CustomPainter {
  /// Where the window is, in the painter's coordinates.
  final Rect window;

  /// QR code found
  final bool found;

  /// wrong QR code found
  final bool error;

  QROverlay({required this.window, required this.found, required this.error});

  static const _designSize = 300.0;

  @override
  void paint(Canvas canvas, Size size) {
    // The corners and brackets keep the design's proportions in a smaller
    // window.
    final scale = window.width / _designSize;
    final radius = 40 * scale;
    final cornerSize = 56 * scale;
    final rrect = RRect.fromRectAndRadius(window, Radius.circular(radius));

    final (overlayColor, cornerColor) = error
        ? (const Color(0x8C961414), const Color(0xFFFF6B6B))
        : found
        ? (const Color(0x8C006E2A), const Color(0xFF3DDC84))
        : (const Color(0x8C121417), Colors.white);

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

    // Corner brackets that follow the window's rounded corners.
    final left = window.left, top = window.top;
    final right = window.right, bottom = window.bottom;
    final r = Radius.circular(radius);
    final corners = Path()
      ..moveTo(left, top + cornerSize)
      ..lineTo(left, top + radius)
      ..arcToPoint(Offset(left + radius, top), radius: r)
      ..lineTo(left + cornerSize, top)
      ..moveTo(right - cornerSize, top)
      ..lineTo(right - radius, top)
      ..arcToPoint(Offset(right, top + radius), radius: r)
      ..lineTo(right, top + cornerSize)
      ..moveTo(right, bottom - cornerSize)
      ..lineTo(right, bottom - radius)
      ..arcToPoint(Offset(right - radius, bottom), radius: r)
      ..lineTo(right - cornerSize, bottom)
      ..moveTo(left + cornerSize, bottom)
      ..lineTo(left + radius, bottom)
      ..arcToPoint(Offset(left, bottom - radius), radius: r)
      ..lineTo(left, bottom - cornerSize);
    canvas.drawPath(
      corners,
      Paint()
        ..color = cornerColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(QROverlay old) =>
      old.window != window || old.found != found || old.error != error;
}
