import "package:material_ui/material_ui.dart";

import "../../../../theme/yivi_palette.dart";

const _grid = 200.0;

/// A face inside the corners of a camera frame, for the face check intro, as
/// drawn on the canvas: link-blue corners, a face with hair, and a red shirt.
class FaceFrameIllustration extends StatelessWidget {
  const FaceFrameIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    // Decorative: the intro text next to it says the same.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _grid,
        child: CustomPaint(
          painter: _FaceFramePainter(link: YiviPalette.of(context).link),
        ),
      ),
    );
  }
}

class _FaceFramePainter extends CustomPainter {
  _FaceFramePainter({required this.link});

  final Color link;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);

    // The four corners of the camera frame.
    const r = Radius.circular(16);
    canvas.drawPath(
      Path()
        ..moveTo(20, 56)
        ..lineTo(20, 36)
        ..arcToPoint(const Offset(36, 20), radius: r)
        ..lineTo(56, 20)
        ..moveTo(144, 20)
        ..lineTo(164, 20)
        ..arcToPoint(const Offset(180, 36), radius: r)
        ..lineTo(180, 56)
        ..moveTo(180, 144)
        ..lineTo(180, 164)
        ..arcToPoint(const Offset(164, 180), radius: r)
        ..lineTo(144, 180)
        ..moveTo(56, 180)
        ..lineTo(36, 180)
        ..arcToPoint(const Offset(20, 164), radius: r)
        ..lineTo(20, 144),
      Paint()
        ..color = link
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Face, hair, eyes and mouth.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 92), width: 76, height: 92),
      Paint()..color = const Color(0xFFF1D8C6),
    );
    canvas.drawPath(
      Path()
        ..moveTo(62, 84)
        ..cubicTo(64, 54, 84, 40, 100, 40)
        ..cubicTo(116, 40, 136, 54, 138, 84)
        ..cubicTo(132, 68, 120, 60, 100, 60)
        ..cubicTo(80, 60, 68, 68, 62, 84)
        ..close(),
      Paint()..color = const Color(0xFF5B3A29),
    );
    final eye = Paint()..color = const Color(0xFF3A2C22);
    canvas.drawCircle(const Offset(86, 94), 4, eye);
    canvas.drawCircle(const Offset(114, 94), 4, eye);
    canvas.drawPath(
      Path()
        ..moveTo(90, 116)
        ..cubicTo(96, 121, 104, 121, 110, 116),
      Paint()
        ..color = const Color(0xFFB5655A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Shoulders in a red shirt.
    canvas.drawPath(
      Path()
        ..moveTo(54, 176)
        ..cubicTo(60, 154, 78, 142, 100, 142)
        ..cubicTo(122, 142, 140, 154, 146, 176)
        ..close(),
      Paint()..color = const Color(0xFFBA3354),
    );
  }

  @override
  bool shouldRepaint(_FaceFramePainter oldDelegate) => oldDelegate.link != link;
}
