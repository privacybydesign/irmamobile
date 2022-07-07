part of pin;

class _VisiblePinIndicator extends StatelessWidget {
  final int maxPinSize;
  final PinStateBloc pinBloc;

  const _VisiblePinIndicator({
    Key? key,
    required this.maxPinSize,
    required this.pinBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PinStateBloc, PinState>(
      bloc: pinBloc,
      builder: (context, state) => _visiblePin(context, maxPinSize, state.pin),
    );
  }

  Widget _visiblePin(BuildContext context, int maxPinSize, Pin pin) {
    final theme = IrmaTheme.of(context);

    final style = maxPinSize != _minPinSize
        ? theme.textTheme.headline5?.copyWith(
            color: theme.pinIndicatorDarkBlue,
          )
        : theme.textTheme.headline2?.copyWith(
            color: theme.pinIndicatorDarkBlue,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pin.length,
        (i) => Text(
          '${pin[i]}',
          style: style,
        ),
      ),
    );
  }
}
