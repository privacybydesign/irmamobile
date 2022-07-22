import 'package:flutter/material.dart';

import '../screens/pin/yivi_pin_screen.dart';
import '../widgets/irma_app_bar.dart';

class SecurePinScreenTest extends StatelessWidget {
  final int maxPinSize;

  final EnterPinStateBloc pinBloc;
  final String instructionKey;

  final VoidCallback? onTogglePinSize;

  final _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'SecurePinScreenTest');

  SecurePinScreenTest({
    Key? key,
    required this.maxPinSize,
    required this.onTogglePinSize,
    required this.instructionKey,
    required this.pinBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: 'Secure Pin: Reset / Onboarding',
        leadingAction: () => Navigator.pop(context),
      ),
      body: YiviPinScreen(
        scaffoldKey: _scaffoldKey,
        instructionKey: instructionKey,
        maxPinSize: maxPinSize,
        onSubmit: (_) => Navigator.pop(context),
        pinBloc: pinBloc,
        onTogglePinSize: onTogglePinSize,
        checkSecurePin: true,
        listener: (context, state) {
          /// speed run regardless of pin quality
          if (shortPinSize == state.pin.length) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

class PinScreenTest extends StatefulWidget {
  final int maxPinSize;
  final VoidCallback? onTogglePinSize;
  final EnterPinStateBloc pinBloc;

  const PinScreenTest({required this.maxPinSize, this.onTogglePinSize, required this.pinBloc});

  @override
  State<StatefulWidget> createState() => _PinScreen();
}

class _PinScreen extends State<PinScreenTest> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return YiviPinScaffold(
      key: _scaffoldKey,
      appBar: IrmaAppBar(
        title: 'Basic Pin',
        leadingAction: () => Navigator.pop(context),
      ),
      body: YiviPinScreen(
        instructionKey: 'pin.title',
        maxPinSize: widget.maxPinSize,
        onSubmit: (_) => Navigator.pop(context),
        pinBloc: widget.pinBloc,
        onForgotPin: () => Navigator.pop(context),
        onTogglePinSize: widget.onTogglePinSize,
        listener: (context, state) {
          if (state.goodEnough && shortPinSize == state.pin.length) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
