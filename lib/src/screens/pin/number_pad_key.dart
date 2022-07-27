part of pin;

class _ScalableText extends StatelessWidget {
  final String string;
  final TextStyle textStyle;
  final double heightFactor;

  const _ScalableText(this.string, {Key? key, required this.heightFactor, required this.textStyle})
      : assert(heightFactor < 1.0),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: constraints.maxHeight * heightFactor,
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.fitHeight,
          child: Text(
            string,
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class _NumberPadKey extends StatelessWidget {
  final int number;
  final String? subtitle;
  final NumberCallback onEnterNumber;

  const _NumberPadKey(this.onEnterNumber, this.number, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    // On devices smaller than the screen width of the design, e.g. w320
    // if you pass a constant fontSize, then the text will take up
    // too much space

    const heightFactor = 0.825;
    final bigNumberTextStyle = TextStyle(
      fontFamily: theme.fontFamily,
      color: theme.secondary,
      fontSize: 32,
      height: 32 / 40,
      fontWeight: FontWeight.w600,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: _ScalableText(
                '$number',
                heightFactor: (subtitle != null) ? heightFactor : .5,
                textStyle: bigNumberTextStyle,
              ),
            ),
            if (subtitle != null)
              Flexible(
                child: _ScalableText(
                  subtitle!,
                  heightFactor: 1 - heightFactor,
                  textStyle: TextStyle(
                    fontFamily: theme.fontFamily,
                    color: theme.secondary,
                    fontWeight: FontWeight.w400,
                    height: 14.0 / 24.0,
                  ),
                ),
              ),
          ],
        ),
        ClipPath(
          clipper: _PerfectCircleClip(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onEnterNumber(number),
              child: IgnorePointer(
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
