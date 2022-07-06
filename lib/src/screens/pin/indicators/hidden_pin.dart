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
    final scaledEdgeSize = edgeSize.scale(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(pinSize, (_) => _resize(scaledEdgeSize, circleFilled), growable: false),
        if (maxPinSize == _minPinSize)
          ...List<Widget>.generate(maxPinSize - pinSize, (_) => _resize(scaledEdgeSize, circleOutlined),
              growable: false),
      ],
    );
  }
}
