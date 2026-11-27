import "package:material_ui/material_ui.dart";

import "../../../../theme/theme.dart";

const _grid = 200.0;

/// A face inside the corners of a camera frame, for the face check intro.
class FaceFrameIllustration extends StatelessWidget {
  const FaceFrameIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    // Decorative: the intro text next to it says the same.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _grid,
        child: CustomPaint(
          painter: _FaceFramePainter(theme: IrmaTheme.of(context)),
        ),
      ),
    );
  }
}

class _FaceFramePainter extends CustomPainter {
  _FaceFramePainter({required this.theme});

  final IrmaThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);

    canvas.drawCircle(
      const Offset(100, 100),
      92,
      Paint()..color = theme.backgroundTertiary,
    );

    const corner = Radius.circular(6);
    final path = Path()
      // Frame corners, clockwise from the top left.
      ..moveTo(52, 76)
      ..lineTo(52, 58)
      ..arcToPoint(const Offset(58, 52), radius: corner)
      ..lineTo(76, 52)
      ..moveTo(124, 52)
      ..lineTo(142, 52)
      ..arcToPoint(const Offset(148, 58), radius: corner)
      ..lineTo(148, 76)
      ..moveTo(148, 124)
      ..lineTo(148, 142)
      ..arcToPoint(const Offset(142, 148), radius: corner)
      ..lineTo(124, 148)
      ..moveTo(76, 148)
      ..lineTo(58, 148)
      ..arcToPoint(const Offset(52, 142), radius: corner)
      ..lineTo(52, 124)
      // Eyes.
      ..moveTo(82, 88)
      ..lineTo(82, 94)
      ..moveTo(118, 88)
      ..lineTo(118, 94)
      // Nose.
      ..moveTo(100, 90)
      ..lineTo(100, 108)
      ..lineTo(94, 108)
      // Mouth.
      ..moveTo(84, 124)
      ..cubicTo(93, 131, 107, 131, 116, 124);
    canvas.drawPath(
      path,
      Paint()
        ..color = theme.link
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FaceFramePainter oldDelegate) =>
      oldDelegate.theme != theme;
}
