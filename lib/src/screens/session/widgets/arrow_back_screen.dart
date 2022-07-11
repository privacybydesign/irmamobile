import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../theme/theme.dart';

class ArrowBack extends StatefulWidget {
  final bool success;
  final int amountIssued;

  const ArrowBack({
    this.success = false,
    required this.amountIssued,
  }) : assert(success == false);

  @override
  State<StatefulWidget> createState() => _ArrowBackState();
}

class _ArrowBackState extends State<ArrowBack> with WidgetsBindingObserver {
  static const portraitOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];
  static const landscapeOrientations = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  void _allowAllOrientations() => SystemChrome.setPreferredOrientations([
        ...portraitOrientations,
        ...landscapeOrientations,
      ]);

  void _forcePortraitOrientation() => SystemChrome.setPreferredOrientations([
        ...portraitOrientations,
      ]);

  @override
  void initState() {
    super.initState();
    _forcePortraitOrientation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _allowAllOrientations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // The NativeDeviceOrientationReader is configured to rebuild according to the gyroscope.
    // On the IOS emulator it is not possible to reproduce this, so this has to be tested on a real device.
    return NativeDeviceOrientationReader(
      useSensor: true,
      builder: (context) {
        final orientation = NativeDeviceOrientationReader.orientation(context);
        late int quarterTurns;

        switch (orientation) {
          case NativeDeviceOrientation.landscapeLeft:
            quarterTurns = 1;
            break;
          case NativeDeviceOrientation.landscapeRight:
            quarterTurns = 3;
            break;
          case NativeDeviceOrientation.portraitUp:
          case NativeDeviceOrientation.portraitDown:
          case NativeDeviceOrientation.unknown:
            quarterTurns = 0;
            break;
        }

        return Scaffold(
          body: SafeArea(
            child: CustomPaint(
              painter: Arrow(context),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: theme.defaultSpacing),
                  child: RotatedBox(
                    quarterTurns: quarterTurns,
                    child: Container(
                      color: Colors.white,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: theme.textTheme.bodyText1,
                          children: [
                            TextSpan(
                              text: widget.success
                                  ? FlutterI18n.plural(context, 'arrow_back.info_success', widget.amountIssued)
                                  : FlutterI18n.translate(context, 'arrow_back.info_no_success'),
                            ),
                            const TextSpan(
                              text: '\n\n',
                            ),
                            TextSpan(
                              text: FlutterI18n.translate(context, 'arrow_back.safari'),
                              style: theme.textTheme.bodyText2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // If the app is resumed remove the route with this screen from the stack.
    if (state == AppLifecycleState.resumed) {
      Navigator.of(context).removeRoute(ModalRoute.of(context)!);
    }
  }
}

class Arrow extends CustomPainter {
  BuildContext context;

  Arrow(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = IrmaTheme.of(context).secondary;
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
