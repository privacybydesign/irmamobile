part of pin;

class _NumberPadKey extends StatelessWidget {
  final int number;
  final String? subtitle;
  final NumberFn onEnterNumber;

  const _NumberPadKey(this.onEnterNumber, this.number, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final fontSize = 32.scale(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        Wrap(
          direction: Axis.vertical,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
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
