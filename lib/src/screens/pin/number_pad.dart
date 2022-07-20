part of pin;

class _NumberPad extends StatelessWidget {
  final NumberCallback onEnterNumber;
  const _NumberPad({Key? key, required this.onEnterNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    final backspace = ClipPath(
      clipper: _PerfectCircleClip(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onEnterNumber(-1),
          child: Icon(
            Icons.backspace,
            color: theme.secondary,
          ),
        ),
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final keys = <Widget>[
        /// The empty String keeps the number aligned with the rest
        _NumberPadKey(onEnterNumber, 1, ''),
        _NumberPadKey(onEnterNumber, 2, 'ABC'),
        _NumberPadKey(onEnterNumber, 3, 'DEF'),
        _NumberPadKey(onEnterNumber, 4, 'GHI'),
        _NumberPadKey(onEnterNumber, 5, 'JKL'),
        _NumberPadKey(onEnterNumber, 6, 'MNO'),
        _NumberPadKey(onEnterNumber, 7, 'PQRS'),
        _NumberPadKey(onEnterNumber, 8, 'TUV'),
        _NumberPadKey(onEnterNumber, 9, 'WXYZ'),
        SizedBox.fromSize(size: const Size.square(20)),
        _NumberPadKey(onEnterNumber, 0),
        backspace,
      ];

      final keyWidth = constraints.maxWidth / 3.0;
      final keyHeight = constraints.maxHeight / 4.0;

      final childAspectRatioApprox = keyWidth > keyHeight ? keyWidth / keyHeight : keyHeight / keyWidth;

      final grid = GridView.count(
        childAspectRatio: childAspectRatioApprox,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        children: keys,
      );
/*
      final keys = <Widget>[
        /// The empty String keeps the number aligned with the rest
        _NumberPadKey(onEnterNumber, 1, ''),
        _NumberPadKey(onEnterNumber, 2, 'ABC'),
        _NumberPadKey(onEnterNumber, 3, 'DEF'),
        _NumberPadKey(onEnterNumber, 4, 'GHI'),
        _NumberPadKey(onEnterNumber, 5, 'JKL'),
        _NumberPadKey(onEnterNumber, 6, 'MNO'),
        _NumberPadKey(onEnterNumber, 7, 'PQRS'),
        _NumberPadKey(onEnterNumber, 8, 'TUV'),
        _NumberPadKey(onEnterNumber, 9, 'WXYZ'),
        SizedBox.fromSize(size: const Size.square(20)),
        _NumberPadKey(onEnterNumber, 0),
        backspace,
      ];

      final keyWidth = constraints.maxWidth / 3.0;
      final keyHeight = constraints.maxHeight / 4.0;

      final grid = Wrap(
        children: keys
            .map((e) => SizedBox(
                  child: e,
                  width: keyWidth,
                  height: keyHeight,
                ))
            .toList(),
        alignment: WrapAlignment.center,
      );
*/
      return grid;
    });
  }
}
