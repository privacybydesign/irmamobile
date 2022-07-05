part of pin;

class _HiddenPinIndicator extends StatelessWidget {
  final int maxPinSize;
  final _PinSizeBloc pinSizeBloc;

  const _HiddenPinIndicator({
    Key? key,
    required this.maxPinSize,
    required this.pinSizeBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<_PinSizeBloc, int>(
      bloc: pinSizeBloc,
      builder: (context, size) => _hiddenPin(context, maxPinSize, size),
    );
  }

  Widget _hiddenPin(BuildContext context, int maxPinSize, int pinSize) {
    final theme = IrmaTheme.of(context);

    final circleFilled = Container(
      decoration: BoxDecoration(
        color: theme.darkPurple,
        shape: BoxShape.circle,
      ),
    );

    final circleOutlined = Container(
        decoration: BoxDecoration(
      color: Colors.transparent, // border color
      shape: BoxShape.circle,
      border: Border.all(color: theme.darkPurple, width: 2.0),
    ));

    final double edgeSize = maxPinSize != _minPinSize ? 6 : 12;

    /// SizedBox.height = 24 So the eye won't get clipped in the Stack
    return Container(
      decoration: BoxDecoration(
        border: maxPinSize == _minPinSize
            ? null
            : Border(
                bottom: BorderSide(color: theme.darkPurple),
              ),
      ),
      child: SizedBox(
        height: 24,
        width: maxPinSize == _minPinSize ? 100 : 230,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...List.generate(pinSize, (_) => _resize(edgeSize, circleFilled), growable: false),
            if (maxPinSize == _minPinSize)
              ...List<Widget>.generate(maxPinSize - pinSize, (_) => _resize(edgeSize, circleOutlined), growable: false),
          ],
        ),
      ),
    );
  }
}
