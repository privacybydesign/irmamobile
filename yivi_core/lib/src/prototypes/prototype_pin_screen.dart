import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../screens/pin/yivi_pin_screen.dart";
import "../widgets/irma_app_bar.dart";

class SecurePinScreenTest extends StatelessWidget {
  final int maxPinSize;

  final String instructionKey;

  final VoidCallback? onTogglePinSize;

  final _scaffoldKey = GlobalKey<ScaffoldState>(
    debugLabel: "SecurePinScreenTest",
  );

  SecurePinScreenTest({
    super.key,
    required this.maxPinSize,
    required this.onTogglePinSize,
    required this.instructionKey,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [enterPinProvider.overrideWith(() => EnterPinNotifier())],
      child: YiviPinScaffold(
        key: _scaffoldKey,
        appBar: IrmaAppBar(titleString: "Secure Pin: Reset / Onboarding"),
        body: Consumer(
          builder: (context, ref, _) {
            ref.read(enterPinProvider.notifier).configure(maxPinSize);
            return YiviPinScreen(
              scaffoldKey: _scaffoldKey,
              instructionKey: instructionKey,
              maxPinSize: maxPinSize,
              onSubmit: (_) => Navigator.pop(context),
              onTogglePinSize: onTogglePinSize,
              checkSecurePin: true,
              listener: (context, state) {
                // speed run regardless of pin quality
                if (shortPinSize == state.pin.length) {
                  Navigator.pop(context);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class PinScreenTest extends StatefulWidget {
  final int maxPinSize;
  final VoidCallback? onTogglePinSize;

  const PinScreenTest({required this.maxPinSize, this.onTogglePinSize});

  @override
  State<StatefulWidget> createState() => _PinScreen();
}

class _PinScreen extends State<PinScreenTest> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [enterPinProvider.overrideWith(() => EnterPinNotifier())],
      child: YiviPinScaffold(
        key: _scaffoldKey,
        appBar: IrmaAppBar(titleString: "Basic Pin"),
        body: Consumer(
          builder: (context, ref, _) {
            ref.read(enterPinProvider.notifier).configure(widget.maxPinSize);
            return YiviPinScreen(
              instructionKey: "pin.title",
              maxPinSize: widget.maxPinSize,
              onSubmit: (_) => Navigator.pop(context),
              onForgotPin: () => Navigator.pop(context),
              onTogglePinSize: widget.onTogglePinSize,
              listener: (context, state) {
                if (state.goodEnough && shortPinSize == state.pin.length) {
                  Navigator.pop(context);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
