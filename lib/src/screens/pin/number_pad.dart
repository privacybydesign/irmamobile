part of pin;

class _NumberPad extends StatelessWidget {
  final NumberFn onEnterNumber;
  const _NumberPad({Key? key, required this.onEnterNumber}) : super(key: key);

  Widget _keyFactory(BuildContext context, int number, [String? subtitle]) {
    final theme = IrmaTheme.of(context);

    return ClipPath(
      clipper: _PerfectCircleClip(),
      child: Material(
        color: theme.background, // Button color
        child: InkWell(
          onTap: () => onEnterNumber(number),
          child: IgnorePointer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$number',
                  style: TextStyle(
                    color: theme.pinIndicatorDarkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 32.0,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.headline5?.copyWith(
                      color: theme.pinIndicatorDarkBlue,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final backspace = ClipPath(
      clipper: _PerfectCircleClip(),
      child: Material(
        color: Colors.transparent, // Button color
        child: InkWell(
          onTap: () => onEnterNumber(-1),
          child: Icon(
            Icons.backspace,
            color: theme.pinIndicatorDarkBlue,
          ),
        ),
      ),
    );

    final keys = <Widget>[
      _keyFactory(context, 1, ''),
      _keyFactory(context, 2, 'ABC'),
      _keyFactory(context, 3, 'DEF'),
      _keyFactory(context, 4, 'GHI'),
      _keyFactory(context, 5, 'JKL'),
      _keyFactory(context, 6, 'MNO'),
      _keyFactory(context, 7, 'PQRS'),
      _keyFactory(context, 8, 'TUV'),
      _keyFactory(context, 9, 'WXYZ'),
      SizedBox.fromSize(size: const Size.square(40.0)),
      _keyFactory(context, 0),
      backspace,
    ];

    final shortestEdge = min<double>(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    final keyEdgeSize = (shortestEdge - 32) / 3.0;

    final grid = SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: keys
            .map((widget) => SizedBox(
                  width: keyEdgeSize,
                  child: _resize(80, widget),
                ))
            .toList(),
      ),
    );

    return grid;
  }
}
