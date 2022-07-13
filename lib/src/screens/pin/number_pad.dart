part of pin;

class _NumberPad extends StatelessWidget {
  final NumberFn onEnterNumber;
  const _NumberPad({Key? key, required this.onEnterNumber}) : super(key: key);

  Widget _keyFactory(BuildContext context, int number, [String? subtitle]) {
    final theme = IrmaTheme.of(context);
    final fontSize = 32.scale(context);

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
                    color: theme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.headline5?.copyWith(
                      color: theme.secondary,
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
            color: theme.secondary,
          ),
        ),
      ),
    );

    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return LayoutBuilder(builder: (context, constraints) {
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
            SizedBox.fromSize(size: const Size.square(20)),
            _keyFactory(context, 0),
            backspace,
          ];

          final keyWidth = constraints.maxWidth / 3.0;

          /// The padding gets lost along the parent widgets
          final keyHeight = (Orientation.landscape == orientation
                  ? (constraints.maxHeight - _paddingInPx * 2)
                  : constraints.maxHeight) /
              4.0;

          if (kDebugMode) {
            print(
                'keypad constraint width: ${constraints.maxWidth}, keypad constraint height: ${constraints.maxHeight}');
            print('keypad button width: $keyWidth, keypad button height: $keyHeight');
          }

          final childAspectRatioApprox =
              Orientation.landscape == orientation ? keyWidth / keyHeight : keyHeight / keyWidth;
          final childAspectRatio = max(1.5, childAspectRatioApprox);

          if (kDebugMode) {
            print('child aspect ratio: $childAspectRatio, approx: $childAspectRatioApprox');
          }

          final grid = GridView.count(
            childAspectRatio: childAspectRatio,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            children: keys,
          );

          return grid;
        });
      },
    );
  }
}
