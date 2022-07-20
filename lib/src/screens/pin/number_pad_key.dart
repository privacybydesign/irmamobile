part of pin;

class _NumberPadKey extends StatelessWidget {
  final int number;
  final String? subtitle;
  final NumberCallback onEnterNumber;

  const _NumberPadKey(this.onEnterNumber, this.number, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    /// On devices smaller than the screen width of the design, e.g. w320
    /// if you pass a constant fontSize, then the text will take up
    /// too much space
    final fontSize = 28.scale(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number',
              style: TextStyle(
                color: theme.secondary,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.headline5?.copyWith(
                  color: theme.secondary,
                  fontWeight: FontWeight.w400,
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
