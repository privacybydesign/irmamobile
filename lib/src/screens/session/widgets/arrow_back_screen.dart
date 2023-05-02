import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_svg/svg.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

import '../../../theme/theme.dart';
import '../../../widgets/translated_text.dart';
import '../../home/home_screen.dart';

enum ArrowBackType {
  issuance,
  disclosure,
  signature,
  error,
}

class ArrowBack extends StatefulWidget {
  final ArrowBackType type;

  const ArrowBack({
    required this.type,
  });

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
    final theme = IrmaTheme.of(context);

    final String infoText;
    switch (widget.type) {
      case ArrowBackType.issuance:
        infoText = 'arrow_back.signature_success';
        break;
      case ArrowBackType.disclosure:
        infoText = 'arrow_back.disclosure_success';
        break;
      case ArrowBackType.signature:
        infoText = 'arrow_back.signature_success';
        break;
      case ArrowBackType.error:
        infoText = 'arrow_back.no_success';
        break;
    }

    // The NativeDeviceOrientationReader is configured to rebuild according to the gyroscope.
    // On the IOS emulator it is not possible to reproduce this, so this has to be tested on a real device.
    return NativeDeviceOrientationReader(
      useSensor: true,
      builder: (context) {
        final orientation = NativeDeviceOrientationReader.orientation(context);
        final isNativeLandscape = orientation == NativeDeviceOrientation.landscapeLeft ||
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

        return Scaffold(
          body: Center(
            // The SingleChildScrollView is used to prevent overflows when the user increases the device text size
            child: SingleChildScrollView(
              // Disable scrolling in landscape mode because the orientation is locked
              physics: isNativeLandscape ? const NeverScrollableScrollPhysics() : null,
              padding: EdgeInsets.all(theme.defaultSpacing),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/arrow_back/pointing_up.svg',
                    width: 250,
                  ),
                  SizedBox(height: theme.hugeSpacing),
                  RotatedBox(
                    quarterTurns: quarterTurns,
                    child: SizedBox(
                      // Set a fixed width when in landscape mode, otherwise the text will be too wide.
                      width: isNativeLandscape ? 250 : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: TranslatedText(
                              infoText,
                              style: theme.textTheme.headline1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: theme.mediumSpacing),
                          Flexible(
                            child: TranslatedText(
                              'arrow_back.safari',
                              style: theme.textTheme.bodyText2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // Pop back to home screen when leaving the app (for example going back to the browser)
    if (state == AppLifecycleState.paused) {
      Navigator.of(context).popUntil(ModalRoute.withName(HomeScreen.routeName));
    }
  }
}
