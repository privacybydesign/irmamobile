part of 'yivi_pin_screen.dart';

class _ScalableText extends StatelessWidget {
  final String string;
  final TextStyle textStyle;
  final double heightFactor;

  const _ScalableText(this.string, {super.key, required this.heightFactor, required this.textStyle})
      : assert(heightFactor < 1.0);

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
