import 'package:flutter/material.dart';

import '../screens/pin/yivi_pin_screen.dart';
import '../widgets/irma_app_bar.dart';

PreferredSizeWidget _buildAppBar(VoidCallback leadingAction, String title) {
  return IrmaAppBar(
    title: title,
    leadingAction: leadingAction,
  );
}

class SecurePinScreenTest extends StatelessWidget {
  final int maxPinSize;

  final PinStateBloc pinBloc;
  final pinVisibilityBloc = PinVisibilityBloc();
  final String instructionKey;

  final VoidCallback? onTogglePinSize;

  SecurePinScreenTest({
    Key? key,
    required this.maxPinSize,
    required this.onTogglePinSize,
    required this.instructionKey,
    required this.pinBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(() => Navigator.pop(context), 'Secure Pin: Reset / Onboarding'),
      body: YiviPinScreen(
        instructionKey: instructionKey,
        maxPinSize: maxPinSize,
        onSubmit: () => Navigator.pop(context),
        pinBloc: pinBloc,
        pinVisibilityBloc: pinVisibilityBloc,
        onTogglePinSize: onTogglePinSize,
        checkSecurePin: true,
      ),
    );
  }
}

class PinScreenTest extends StatefulWidget {
  final int maxPinSize;
  final VoidCallback? onTogglePinSize;
  final PinStateBloc pinBloc;

  const PinScreenTest({required this.maxPinSize, this.onTogglePinSize, required this.pinBloc});

  @override
  State<StatefulWidget> createState() => _PinScreen();
}

class _PinScreen extends State<PinScreenTest> {
  final pinVisibilityBloc = PinVisibilityBloc();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(() => Navigator.pop(context), 'Basic Pin'),
      body: YiviPinScreen(
        instructionKey: 'pin.title',
        maxPinSize: widget.maxPinSize,
        onSubmit: () => Navigator.pop(context),
        pinBloc: widget.pinBloc,
        pinVisibilityBloc: pinVisibilityBloc,
        onForgotPin: () => Navigator.pop(context),
        onTogglePinSize: widget.onTogglePinSize,
        listener: (context, state) {
          if (state.attributes.contains(SecurePinAttribute.goodEnough) && shortPinSize == state.pin.length) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
