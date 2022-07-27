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

    if (subtitle != null) {
      return LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
          constraints: constraints,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: _ScalableText(
                      '$number',
                      heightFactor: heightFactor,
                      textStyle: TextStyle(
                        fontFamily: theme.fontFamily,
                        color: theme.secondary,
                        fontSize: 32,
                        height: 32 / 40,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
          ),
        ),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
          constraints: constraints,
          child: ClipPath(
            clipper: _PerfectCircleClip(),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onEnterNumber(number),
                child: IgnorePointer(
                  child: FractionallySizedBox(
                    alignment: Alignment.topCenter,
                    heightFactor: heightFactor,
                    child: FittedBox(
                      // fit: BoxFit.scaleDown,
                      fit: BoxFit.fitHeight,
                      child: Container(
                        // color: Colors.transparent,
                        alignment: Alignment.center,
                        child: Text(
                          '$number',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.secondary,
                            fontWeight: FontWeight.w600,
                            // backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
