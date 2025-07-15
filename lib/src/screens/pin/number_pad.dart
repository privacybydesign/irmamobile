part of 'yivi_pin_screen.dart';

class _NumberPad extends StatelessWidget {
  final NumberCallback onEnterNumber;
  const _NumberPad({required this.onEnterNumber});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keys = <Widget>[
          // The empty String keeps the number aligned with the rest
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
          Semantics(
            button: true,
            label: FlutterI18n.translate(context, 'pin_accessibility.backspace'),
            child: _NumberPadIcon(icon: Icons.backspace_outlined, callback: () => onEnterNumber(-1)),
          ),
        ];

        final keyWidth = constraints.maxWidth / 3.0;
        final keyHeight = constraints.maxHeight / 4.0;
        final resizedKeyHeight = keyHeight * 0.8;

        final grid = Wrap(
          alignment: WrapAlignment.center,
          children: keys
              .map(
                (e) => Container(
                  alignment: Alignment.topCenter,
                  width: keyWidth,
                  height: keyHeight,
                  child: ConstrainedBox(constraints: BoxConstraints.tight(Size(keyWidth, resizedKeyHeight)), child: e),
                ),
              )
              .toList(),
        );

        return grid;
      },
    );
  }
}
