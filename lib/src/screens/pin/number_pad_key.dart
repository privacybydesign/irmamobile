part of pin;

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

    if (subtitle != null) {
      return LayoutBuilder(
        builder: (context, constraints) => ConstrainedBox(
          constraints: constraints,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: 0.825,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontFamily: theme.fontFamily,
                            color: theme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    subtitle!,
                    // style: theme.textTheme.headline5?.copyWith(
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      color: theme.secondary,
                      fontWeight: FontWeight.w400,
                      height: 14.0 / 24.0,
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
                    heightFactor: .8,
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
