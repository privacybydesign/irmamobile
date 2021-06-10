import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/theme/theme.dart';

// The Offstage in the Carousel widget requires this being a StatelessWidget. Otherwise the
// size calculations cannot be done reliably anymore.
class TearLine extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const TearLine({Key key, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          height: 17,
          width: constraints.maxWidth,
          padding: padding,
          child: Opacity(
            // TODO: Check whether we can remove Opacity
            opacity: 0.8,
            child: CustomPaint(
              painter: _TearLinePainter(
                lineColor: IrmaTheme.of(context).grayscale95,
              ),
            ),
          ),
        ),
      );
}

class _TearLinePainter extends CustomPainter {
  final Color lineColor;

  _TearLinePainter({this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Check number of repaints.
    final paint = Paint();
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    paint.color = lineColor;
    paint.strokeWidth = 5;

    double dxCurrent = 0;
    int zigZagWidth = 0;
    while (dxCurrent < size.width) {
      final dxEnd = dxCurrent + 30;
      if (dxEnd > size.width) dxCurrent = size.width;
      paintZigZag(
        canvas,
        paint,
        Offset(dxCurrent, size.height / 2),
        Offset(dxEnd, size.height / 2),
        2,
        zigZagWidth.toDouble() + 1, // Always add 1 to prevent width being 0 (that would become a straight line)
      );
      zigZagWidth = (zigZagWidth + 2) % 5;
      dxCurrent = dxEnd;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint, because the parent widget size might have changed.
    return false; //TODO: check
  }
}
