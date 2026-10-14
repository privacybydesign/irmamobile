import "package:material_ui/material_ui.dart";

import "../../../theme/theme.dart";

class QROverlay extends CustomPainter {
  // the width of the view box as a ratio of the screen width
  static const _widthFactor = 0.78;

  // the view box never gets wider than this
  static const _maxWindowSize = 320.0;

  // minimum offset to the bottom of the screen as a ratio of the total height
  static const _minBottomOffsetFactor = 0.05;

  // offset to the top of the screen as a ratio of the total height
  final double topOffsetFactor;

  // the irma theme
  final IrmaThemeData theme;

  // QR code found
  final bool found;

  // wrong QR code found
  final bool error;

  QROverlay({
    required this.found,
    required this.error,
    required this.theme,
    required this.topOffsetFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // hole size
    double windowSize = size.width * _widthFactor;
    if (windowSize > _maxWindowSize) windowSize = _maxWindowSize;
    final maxWindowHeight =
        size.height - size.height * (topOffsetFactor + _minBottomOffsetFactor);
    if (windowSize > maxWindowHeight) {
      windowSize = maxWindowHeight;
    }

    // hole coordinates
    final left = (size.width - windowSize) / 2;
    final right = left + windowSize;
    final top = size.height * topOffsetFactor;
    final bottom = top + windowSize;
    final cornerSize = windowSize * 0.19;
    final radius = windowSize * 0.13;
    final window = RRect.fromLTRBR(
      left,
      top,
      right,
      bottom,
      Radius.circular(radius),
    );

    // colors
    final Color green = theme.success;
    final Color red = theme.error;

    Color overlayColor = const Color(0xFF121417);
    Color cornerColor = Colors.white;

    if (error) {
      overlayColor = const Color(0xFF961414);
      cornerColor = const Color(0xFFFF6B6B);
    } else if (found) {
      overlayColor = const Color(0xFF006E2A);
      cornerColor = const Color(0xFF3DDC84);
    }

    // Punch the scan window out of the dimming overlay using BlendMode.clear.
    // This must happen inside its own offscreen layer: BlendMode.clear writes
    // fully-transparent pixels into the layer it draws into, so without
    // saveLayer it would clear against the opaque root surface and the hole
    // would render as solid black (the camera preview is a sibling Flutter
    // texture drawn below this painter, not a platform view behind the
    // surface). saveLayer gives us a real RGBA buffer whose transparent hole
    // composites correctly over the camera texture.
    canvas.saveLayer(Offset.zero & size, Paint());

    // transparent overlay
    final paint = Paint()
      ..color = overlayColor.withAlpha(140)
      ..style = PaintingStyle.fill;
    final Path path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // add a hole in the overlay
    final clearPaint = Paint()
      ..color = const Color(0x00000000)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.clear;
    canvas.drawRRect(window, clearPaint);

    canvas.restore();

    // add rounded corner brackets that follow the window's corners
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final r = Radius.circular(radius);
    final Path corners = Path()
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
    canvas.drawPath(corners, cornerPaint);

    if (error) {
      // paint error icon
      final iconPaint = Paint()
        ..color = red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset((left + right) / 2, (top + bottom) / 2),
        windowSize * 0.2,
        iconPaint,
      );
      final iconShapePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final Path iconShape = Path();
      iconShape.moveTo(
        (left + right) / 2 - windowSize * 0.06,
        (top + bottom) / 2 - windowSize * 0.06,
      );
      iconShape.lineTo(
        (left + right) / 2 + windowSize * 0.06,
        (top + bottom) / 2 + windowSize * 0.06,
      );
      iconShape.moveTo(
        (left + right) / 2 - windowSize * 0.06,
        (top + bottom) / 2 + windowSize * 0.06,
      );
      iconShape.lineTo(
        (left + right) / 2 + windowSize * 0.06,
        (top + bottom) / 2 - windowSize * 0.06,
      );
      canvas.drawPath(iconShape, iconShapePaint);
    } else if (found) {
      // paint found icon
      final iconPaint = Paint()
        ..color = green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset((left + right) / 2, (top + bottom) / 2),
        windowSize * 0.2,
        iconPaint,
      );
      final iconShapePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 12
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final Path iconShape = Path();
      iconShape.moveTo(
        (left + right) / 2 - windowSize * 0.11,
        (top + bottom) / 2,
      );
      iconShape.lineTo(
        (left + right) / 2,
        (top + bottom) / 2 + windowSize * 0.08,
      );
      iconShape.lineTo(
        (left + right) / 2 + windowSize * 0.09,
        (top + bottom) / 2 - windowSize * 0.09,
      );
      canvas.drawPath(iconShape, iconShapePaint);
    }
  }

  @override
  bool shouldRepaint(QROverlay oldDelegate) {
    return oldDelegate.found != found || oldDelegate.error != error;
  }
}
