part of 'yivi_pin_screen.dart';

class _PinIndicator extends StatelessWidget {
  final int maxPinSize;
  final ValueNotifier<bool> pinVisibilityValue;
  final EnterPinState pinState;

  const _PinIndicator({required this.maxPinSize, required this.pinVisibilityValue, required this.pinState});

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
        ? theme.textTheme.headlineSmall?.copyWith(
            color: textColor,
          )
        : theme.textTheme.displayMedium?.copyWith(
            color: textColor,
          );

    final double edgeSize = maxPinSize != shortPinSize ? 6 : 12;

    // Applied scaling so, the circles / dots won't
    // get too small on devices bigger than the design
    // and too big on devices smaller than the design
    final scaledEdgeSize = edgeSize.scaleToDesignSize(context);

    final circleFilledDecoration = BoxDecoration(
      color: isPinVisible ? Colors.transparent : theme.secondary,
      shape: BoxShape.circle,

      // prevent unnecessary resize
      border: Border.all(color: Colors.transparent, width: 2.0),
    );

    final circleOutlinedDecoration = BoxDecoration(
      color: Colors.transparent, // border color
      shape: BoxShape.circle,
      border: Border.all(color: theme.secondary, width: 2.0),
    );

    final pinSize = pinState.pin.length;

    // prevent the row from collapsing
    if (pinSize == 0 && maxPinSize != shortPinSize) {
      return SizedBox(
        width: 0,
        height: 19.scaleToDesignSize(context),
      );
    }

    final constraints = BoxConstraints.tightFor(width: scaledEdgeSize, height: scaledEdgeSize);

    final isMaxPin5 = maxPinSize == shortPinSize;
    final joinedPin = pinState.pin.join();

    return Semantics(
      label: joinedPin.isEmpty
          ? FlutterI18n.translate(context, 'pin_accessibility.empty_pin_input')
          : isPinVisible
              ? joinedPin
              : FlutterI18n.plural(
                  context,
                  'pin_accessibility.digits_entered',
                  pinState.pin.length,
                ),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: isMaxPin5 ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            isMaxPin5 ? shortPinSize : pinSize,
            (i) => Stack(
              alignment: Alignment.center,
              children: [
                // SizedBox ensures that all the relevant
                // glyphs have a uniform size, that prevents realignment
                SizedBox(
                  width: isMaxPin5 ? 14 : 9,
                  height: isMaxPin5 ? 36 : 21,
                  child: Text(
                    '${i < pinSize ? pinState.pin.elementAt(i) : ''}',
                    style: i >= pinSize ? style?.copyWith(color: Colors.transparent) : style,
                  ),
                ),
                if (i < pinSize)
                  Container(
                    constraints: constraints,
                    decoration: circleFilledDecoration,
                  ),
                if (isMaxPin5 && i >= pinSize)
                  Container(
                    constraints: constraints,
                    decoration: circleOutlinedDecoration,
                  ),
              ],
            ),
            growable: false,
          ),
        ),
      ),
    );
  }
}
