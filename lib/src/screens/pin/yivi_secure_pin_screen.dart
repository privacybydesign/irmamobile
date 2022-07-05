part of pin;

class SecurePinScreenTest extends StatelessWidget {
  final pinStream = PinStream.seeded([]);
  final int maxPinSize;

  late final _PinSizeBloc pinSizeBloc;
  final pinVisibilityBloc = _PinVisibilityBloc();
  final String instructionKey;

  final VoidCallback? onTogglePinSize;

  SecurePinScreenTest({
    Key? key,
    required this.maxPinSize,
    required this.onTogglePinSize,
    required this.instructionKey,
  }) : super(key: key) {
    pinSizeBloc = _PinSizeBloc(pinStream);
  }

  @override
  Widget build(BuildContext context) {
    return YiviPinScreen(
      instructionKey: instructionKey,
      maxPinSize: maxPinSize,
      onPinEntered: (pin) {
        pinStream.sink.add(pin);
      },
      onCompletePin: () => Navigator.pop(context),
      pinSizeBloc: pinSizeBloc,
      pinVisibilityBloc: pinVisibilityBloc,
      pinStream: pinStream,
      onTogglePinSize: onTogglePinSize,
      checkSecurePin: true,
    );
  }
}
