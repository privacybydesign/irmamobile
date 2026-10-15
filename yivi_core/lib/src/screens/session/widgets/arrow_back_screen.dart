import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";
import "package:native_device_orientation/native_device_orientation.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/navigation.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/translated_text.dart";

enum ArrowBackType { issuance, disclosure, signature, error }

class ArrowBack extends StatefulWidget {
  final ArrowBackType type;

  const ArrowBack({required this.type});

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

  void _forcePortraitOrientation() =>
      SystemChrome.setPreferredOrientations([...portraitOrientations]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _forcePortraitOrientation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _allowAllOrientations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    final String infoText;
    switch (widget.type) {
      case ArrowBackType.issuance:
        infoText = "arrow_back.issuance_success";
        break;
      case ArrowBackType.disclosure:
        infoText = "arrow_back.disclosure_success";
        break;
      case ArrowBackType.signature:
        infoText = "arrow_back.signature_success";
        break;
      case ArrowBackType.error:
        infoText = "arrow_back.no_success";
        break;
    }

    // The NativeDeviceOrientationReader is configured to rebuild according to the gyroscope.
    // On the IOS emulator it is not possible to reproduce this, so this has to be tested on a real device.
    return NativeDeviceOrientationReader(
      useSensor: true,
      builder: (context) {
        final orientation = NativeDeviceOrientationReader.orientation(context);
        final isNativeLandscape =
            orientation == NativeDeviceOrientation.landscapeLeft ||
            orientation == NativeDeviceOrientation.landscapeRight;

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

        final success = widget.type != ArrowBackType.error;

        return Scaffold(
          backgroundColor: palette.background,
          body: Stack(
            children: [
              Center(
                // The SingleChildScrollView is used to prevent overflows when the user increases the device text size
                child: SingleChildScrollView(
                  // Disable scrolling in landscape mode because the orientation is locked
                  physics: isNativeLandscape
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // A green tick, or a cross when it did not work out.
                      ToneDisc(
                        icon: success
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        tone: success ? DialogTone.success : DialogTone.danger,
                        size: 120,
                      ),
                      const SizedBox(height: 32),
                      RotatedBox(
                        quarterTurns: quarterTurns,
                        child: SizedBox(
                          // Set a fixed width when in landscape mode, otherwise the text will be too wide.
                          width: isNativeLandscape ? 250 : null,
                          // The control this screen points at is the iOS status bar
                          // back link, which the app cannot label. This screen
                          // replaces the session body instead of pushing a route, so
                          // VoiceOver does not announce it on its own: make the
                          // outcome and the instruction one live region, so they are
                          // read out as soon as the screen appears.
                          child: Semantics(
                            key: const Key("arrow_back_semantics"),
                            liveRegion: true,
                            label:
                                "${FlutterI18n.translate(context, infoText)}\n"
                                "${FlutterI18n.translate(context, "arrow_back.safari")}",
                            excludeSemantics: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: TranslatedText(
                                    infoText,
                                    style: palette
                                        .display(26, weight: FontWeight.w700)
                                        .copyWith(
                                          height: 34 / 26,
                                          color: palette.heading,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: TranslatedText(
                                    "arrow_back.safari",
                                    style: palette
                                        .body(16)
                                        .copyWith(height: 24 / 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The arrow to the back link in the status bar, top left. It
              // repeats the instruction, so it is decorative.
              Positioned(
                left: 16,
                top: MediaQuery.paddingOf(context).top + 8,
                child: ExcludeSemantics(
                  child: CustomPaint(
                    size: const Size.square(64),
                    painter: _BackArrowPainter(palette.primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // Pop back to home screen when leaving the app (for example going back to the browser)
    if (state == AppLifecycleState.paused) {
      context.goHomeScreen();
    }
  }
}

/// A hand-drawn arrow curving up to the top left corner.
class _BackArrowPainter extends CustomPainter {
  final Color color;

  const _BackArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 64;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(54 * scale, 54 * scale)
      ..cubicTo(
        40 * scale,
        50 * scale,
        20 * scale,
        36 * scale,
        14 * scale,
        14 * scale,
      )
      ..moveTo(14 * scale, 14 * scale)
      ..lineTo(12 * scale, 30 * scale)
      ..moveTo(14 * scale, 14 * scale)
      ..lineTo(29 * scale, 19 * scale);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BackArrowPainter old) => old.color != color;
}
