part of pin;

class _NumberPadKey extends StatelessWidget {
  final int number;
  final String? subtitle;
  final NumberCallback onEnterNumber;

  _NumberPadKey(this.onEnterNumber, this.number, [this.subtitle])
      : super(key: Key('number_pad_key_${number.toString()}'));

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // On devices smaller than the screen width of the design, e.g. w320
    // if you pass a constant fontSize, then the text will take up
    // too much space

    const heightFactor = 0.825;
    final bigNumberTextStyle = TextStyle(
      fontFamily: theme.secondaryFontFamily,
      color: theme.secondary,
      fontSize: 32,
      height: 32 / 40,
      fontWeight: FontWeight.w600,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: (() => onEnterNumber(number)).haptic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: _ScalableText(
                '$number',
                heightFactor: (subtitle != null) ? heightFactor : .45,
                textStyle: bigNumberTextStyle,
              ),
            ),
            if (subtitle != null)
              Flexible(
                child: _ScalableText(
                  subtitle!,
                  heightFactor: 1.1 - heightFactor,
                  textStyle: TextStyle(
                    fontFamily: theme.secondaryFontFamily,
                    color: theme.secondary,
                    fontWeight: FontWeight.w400,
                    height: 14.0 / 24.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
