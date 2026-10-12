import "dart:math";

import "package:material_ui/material_ui.dart";

// The angle of the bands on the Final boards, as CSS gives it: 0 is up, 90 is
// to the right.
const _angle = 110 * pi / 180;

// The colours of the button asset, and where each band after the first starts.
const _colors = [
  Color(0xFFE12747),
  Color(0xFFBA3555),
  Color(0xFFA03352),
  Color(0xFF87314F),
];
const _starts = [0.64, 0.74, 0.84];

/// Background of a slim fancy button: the bands of the button asset, drawn at
/// the angle of the boards. The asset is stretched to the button, which turns
/// its bands from 20 degrees off vertical to about 45.
class SlimButtonBackground extends StatelessWidget {
  const SlimButtonBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // As in CSS, the gradient line is as long as it takes to reach the
        // corners, so the first and last band touch them.
        final dx = sin(_angle);
        final dy = -cos(_angle);
        final length =
            constraints.maxWidth * dx.abs() + constraints.maxHeight * dy.abs();
        final reachX = dx * length / constraints.maxWidth;
        final reachY = dy * length / constraints.maxHeight;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-reachX, -reachY),
              end: Alignment(reachX, reachY),
              // Every colour holds until its band ends, so the edges are hard.
              colors: [
                for (final color in _colors) ...[color, color],
              ],
              stops: [
                0,
                for (final start in _starts) ...[start, start],
                1,
              ],
            ),
          ),
        );
      },
    );
  }
}
