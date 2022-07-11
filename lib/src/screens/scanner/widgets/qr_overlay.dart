import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/theme.dart';

class QROverlay extends CustomPainter {
  // the width of the view box as a ratio of the screen width
  static const _widthFactor = 0.9;

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

  QROverlay({required this.found, required this.error, required this.theme, required this.topOffsetFactor});

  @override
  void paint(Canvas canvas, Size size) {
    // hole size
    double windowSize = size.width * _widthFactor;
    final maxWindowHeight = size.height - size.height * (topOffsetFactor + _minBottomOffsetFactor);
    if (windowSize > maxWindowHeight) {
      windowSize = maxWindowHeight;
    }

    // hole coordinates
    final left = (size.width - windowSize) / 2;
    final right = left + windowSize;
    final top = size.height * topOffsetFactor;
    final bottom = top + windowSize;
    final cornerSize = windowSize * 0.15;

    // colors
    final Color green = theme.success;
    final Color red = theme.error;

    Color overlayColor = Colors.grey.shade800;
    Color cornerColor = Colors.white;

    if (error) {
      overlayColor = red;
      cornerColor = red;
    } else if (found) {
      overlayColor = green;
      cornerColor = green;
    }

    // transparent overlay
    final paint = Paint()
      ..color = overlayColor.withOpacity(0.5)
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
    final Path hole = Path();
    hole.moveTo(left, top);
    hole.lineTo(right, top);
    hole.lineTo(right, bottom);
    hole.lineTo(left, bottom);
    hole.close();
    canvas.drawPath(hole, clearPaint);

    // add decorative corners to the hole
    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path corners = Path();
    corners.moveTo(left, top + cornerSize);
    corners.lineTo(left, top);
    corners.lineTo(left + cornerSize, top);
    corners.moveTo(right - cornerSize, top);
    corners.lineTo(right, top);
    corners.lineTo(right, top + cornerSize);
    corners.moveTo(right, bottom - cornerSize);
    corners.lineTo(right, bottom);
    corners.lineTo(right - cornerSize, bottom);
    corners.moveTo(left + cornerSize, bottom);
    corners.lineTo(left, bottom);
    corners.lineTo(left, bottom - cornerSize);
    canvas.drawPath(corners, cornerPaint);

    if (error) {
      // paint error icon
      final iconPaint = Paint()
        ..color = red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset((left + right) / 2, (top + bottom) / 2), windowSize * 0.2, iconPaint);
      final iconShapePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final Path iconShape = Path();
      iconShape.moveTo((left + right) / 2 - windowSize * 0.06, (top + bottom) / 2 - windowSize * 0.06);
      iconShape.lineTo((left + right) / 2 + windowSize * 0.06, (top + bottom) / 2 + windowSize * 0.06);
      iconShape.moveTo((left + right) / 2 - windowSize * 0.06, (top + bottom) / 2 + windowSize * 0.06);
      iconShape.lineTo((left + right) / 2 + windowSize * 0.06, (top + bottom) / 2 - windowSize * 0.06);
      canvas.drawPath(iconShape, iconShapePaint);
    } else if (found) {
      // paint found icon
      final iconPaint = Paint()
        ..color = green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset((left + right) / 2, (top + bottom) / 2), windowSize * 0.2, iconPaint);
      final iconShapePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 12
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final Path iconShape = Path();
      iconShape.moveTo((left + right) / 2 - windowSize * 0.11, (top + bottom) / 2);
      iconShape.lineTo((left + right) / 2, (top + bottom) / 2 + windowSize * 0.08);
      iconShape.lineTo((left + right) / 2 + windowSize * 0.09, (top + bottom) / 2 - windowSize * 0.09);
      canvas.drawPath(iconShape, iconShapePaint);
    }
  }

  @override
  bool shouldRepaint(QROverlay oldDelegate) {
    return oldDelegate.found != found || oldDelegate.error != error;
  }
}
