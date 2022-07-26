part of pin;

class _PinIndicator extends StatelessWidget {
  final int maxPinSize;
  final ValueNotifier<bool> pinVisibilityValue;
  final EnterPinState pinState;

  const _PinIndicator({Key? key, required this.maxPinSize, required this.pinVisibilityValue, required this.pinState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: pinVisibilityValue,
      builder: (context, visibility, _) => _togglePinIndicators(context, visibility),
    );
  }

  Widget _togglePinIndicators(BuildContext context, bool isPinVisible) {
    final theme = IrmaTheme.of(context);

    final textColor = isPinVisible ? theme.secondary : Colors.transparent;

    final style = maxPinSize != shortPinSize
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

        // prevent unnecessary resize
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

    final double edgeSize = maxPinSize != shortPinSize ? 6 : 12;

    // Applied scaling so, the circles / dots won't
    // get too small on devices bigger than the design
    // and too big on devices smaller than the design
    final scaledEdgeSize = edgeSize.scaleToDesignSize(context);

    // prevent the row from collapsing
    if (pinSize == 0 && maxPinSize != shortPinSize) {
      return SizedBox(
        width: 0,
        height: 19.scaleToDesignSize(context),
      );
    }

    final isMaxPin5 = maxPinSize == shortPinSize;

    return Row(
      mainAxisAlignment: isMaxPin5 ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...List.generate(
          isMaxPin5 ? shortPinSize : pinSize,
          (i) => Stack(
            alignment: Alignment.center,
            children: [
              BlockSemantics(
                blocking: !isPinVisible,
                child: Text(
                  '${i < pinSize ? pinState.pin.elementAt(i) : '_'}',
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
