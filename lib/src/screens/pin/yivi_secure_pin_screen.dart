part of pin;

class SecurePinScreenTest extends StatelessWidget {
  final int maxPinSize;

  late final PinStateBloc pinBloc;
  final pinVisibilityBloc = _PinVisibilityBloc();
  final String instructionKey;

  final VoidCallback? onTogglePinSize;

  SecurePinScreenTest({
    Key? key,
    required this.maxPinSize,
    required this.onTogglePinSize,
    required this.instructionKey,
  }) : super(key: key) {
    pinBloc = PinStateBloc(maxPinSize);
  }

  @override
  Widget build(BuildContext context) {
    return YiviPinScreen(
      instructionKey: instructionKey,
      maxPinSize: maxPinSize,
      onCompletePin: () => Navigator.pop(context),
      pinBloc: pinBloc,
      pinVisibilityBloc: pinVisibilityBloc,
      onTogglePinSize: onTogglePinSize,
      checkSecurePin: true,
    );
  }
}
