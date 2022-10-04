import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:native_device_orientation/native_device_orientation.dart';

import 'package:irmamobile/src/screens/home/home_screen.dart';

import '../../../widgets/irma_info_scaffold_body.dart';

class ArrowBack extends StatefulWidget {
  final bool success;
  final int amountIssued;

  const ArrowBack({
    this.success = false,
    required this.amountIssued,
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
    WidgetsBinding.instance?.addObserver(this);
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
          body: RotatedBox(
            quarterTurns: quarterTurns,
            child: IrmaInfoScaffoldBody(
              imagePath: 'assets/arrow_back/pointing_up.svg',
              titleTranslationKey: widget.success
                  ? widget.amountIssued > 0
                      ? 'arrow_back.issuance_success'
                      : 'arrow_back.disclosure_success'
                  : 'arrow_back.no_success',
              bodyTranslationKey: 'arrow_back.safari',
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
      Navigator.of(context).popUntil(ModalRoute.withName(HomeScreen.routeName));
    }
  }
}
