import 'package:flutter/cupertino.dart';
import 'package:irmamobile/src/theme/theme.dart';

// The Offstage in the Carousel widget requires this widget to persist a constant height.
class TearLine extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  // TODO: Use margin
  const TearLine({Key key, this.margin}) : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Container(
          height: 17,
          width: constraints.maxWidth,
          margin: margin,

          /// Wrap the CustomPaint in a Opacity to make the line color less dominant
          child: Opacity(
            opacity: 0.8,
            child: CustomPaint(
              painter: _TearLinePainter(
                lineColor: IrmaTheme.of(context).primaryLight,
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
  bool shouldRepaint(_TearLinePainter prev) {
    return prev.lineColor != lineColor;
  }
}
