import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:path_drawing/path_drawing.dart';

class ArrowBackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      body: CustomPaint(
        painter: ArrowBack(context),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
            child: Container(
              color: IrmaTheme.of(context).primaryLight,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: IrmaTheme.of(context).textTheme.body1.copyWith(),
                  children: <TextSpan>[
                    TextSpan(
                      text: FlutterI18n.translate(context, 'arrow_back.info_1'),
                    ),
                    TextSpan(
                      text: FlutterI18n.translate(context, 'arrow_back.safari'),
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: FlutterI18n.translate(context, 'arrow_back.info_2'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ArrowBack extends CustomPainter {
  BuildContext context;

  ArrowBack(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = IrmaTheme.of(context).primaryBlue;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;

    const start = Offset(28, 50);
    const cP1 = Offset(20, 140);
    final cP2 = Offset(size.width / 2, size.height / 10);
    final end = Offset(size.width / 2, size.height / 2.6);
    final line = Path();
    line.moveTo(start.dx, start.dy);
    line.cubicTo(cP1.dx, cP1.dy, cP2.dx, cP2.dy, end.dx, end.dy);

    canvas.drawPath(
      dashPath(
        line,
        dashArray: CircularIntervalList<double>(<double>[5.0, 6.0]),
      ),
      paint,
    );

    paint.style = PaintingStyle.fill;

    final triangle = Path();
    triangle.moveTo(28, 42);
    triangle.lineTo(36, 52);
    triangle.lineTo(20, 52);
    triangle.close();
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return null;
  }
}
