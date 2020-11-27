import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:path_drawing/path_drawing.dart';

class ArrowBack extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ArrowBackState();
  }
}

class ArrowBackState extends State with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomPaint(
          painter: Arrow(context),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: IrmaTheme.of(context).defaultSpacing),
              child: Container(
                color: IrmaTheme.of(context).primaryLight,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: IrmaTheme.of(context).textTheme.body2,
                    children: <TextSpan>[
                      TextSpan(
                        text: FlutterI18n.translate(context, 'arrow_back.info_1'),
                      ),
                      TextSpan(
                        text: FlutterI18n.translate(context, 'arrow_back.safari'),
                        style: IrmaTheme.of(context).textTheme.body1,
                      ),
                      TextSpan(
                        text: FlutterI18n.translate(context, 'arrow_back.info_2'),
                        style: IrmaTheme.of(context).textTheme.body1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // If the app is resumed remove the route with this screen from the stack.
    if (state == AppLifecycleState.resumed) {
      Navigator.of(context).removeRoute(ModalRoute.of(context));
    }
  }
}

class Arrow extends CustomPainter {
  BuildContext context;

  Arrow(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = IrmaTheme.of(context).primaryBlue;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    paint.strokeCap = StrokeCap.round;
    paint.strokeJoin = StrokeJoin.round;

    const start = Offset(23, 15);
    const cP1 = Offset(15, 140);
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
    triangle.moveTo(23, 7);
    triangle.lineTo(31, 17);
    triangle.lineTo(15, 17);
    triangle.close();
    canvas.drawPath(triangle, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
