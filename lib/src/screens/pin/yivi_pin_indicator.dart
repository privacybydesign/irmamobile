part of pin;

class _PinIndicator extends StatelessWidget {
  final int maxPinSize;
  final _PinVisibilityBloc visibilityBloc;
  final PinState pinState;

  const _PinIndicator({Key? key, required this.maxPinSize, required this.visibilityBloc, required this.pinState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<_PinVisibilityBloc, bool>(
      bloc: visibilityBloc,
      builder: (context, isPinVisible) => _togglePinIndicators(context, isPinVisible),
    );
  }

  Widget _togglePinIndicators(BuildContext context, bool isPinVisible) {
    final theme = IrmaTheme.of(context);

    final textColor = isPinVisible ? theme.pinIndicatorDarkBlue : Colors.transparent;

    final style = maxPinSize != _minPinSize
        ? theme.textTheme.headline5?.copyWith(
            color: textColor,
          )
        : theme.textTheme.headline2?.copyWith(
            color: textColor,
          );

    final circleFilled = Container(
      decoration: BoxDecoration(
        color: isPinVisible ? Colors.transparent : theme.darkPurple,
        shape: BoxShape.circle,

        /// prevent unnecessary resize
        border: Border.all(color: Colors.transparent, width: 2.0),
      ),
    );

    final circleOutlined = Container(
        decoration: BoxDecoration(
      color: Colors.transparent, // border color
      shape: BoxShape.circle,
      border: Border.all(color: theme.darkPurple, width: 2.0),
    ));

    final pinSize = pinState.pin.length;

    final double edgeSize = maxPinSize != _minPinSize ? 6 : 12;
    final scaledEdgeSize = edgeSize.scale(context);

    /// prevent the row from collapsing
    if (pinSize == 0 && maxPinSize != _minPinSize) {
      return SizedBox(
        width: 0,
        height: 19.scale(context),
      );
    }

    final isMaxPin5 = maxPinSize == _minPinSize;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...List.generate(
          isMaxPin5 ? 5 : pinSize,
          (i) => Stack(
            alignment: Alignment.center,
            children: [
              BlockSemantics(
                blocking: !isPinVisible,
                child: Text(
                  '${i < pinSize ? pinState.pin[i] : '_'}',
                  style: i >= pinSize ? style?.copyWith(color: Colors.transparent) : style,
                ),
              ),
              if (i < pinSize) _resizeBox(circleFilled, scaledEdgeSize),
              if (isMaxPin5 && i >= pinSize) _resizeBox(circleOutlined, scaledEdgeSize),
            ],
          ),
          growable: false,
        ),
      ],
    );
  }
}
