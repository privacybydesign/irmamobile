import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";

/// One part of a progress made of short parts (the share screen's, and that
/// of adding a card in a sheet): grey, [width] by 4, filled green from the
/// start edge as far as [fill] (0..1, eased) says. Its state decides when
/// it fills.
class ProgressPartTrack extends StatelessWidget {
  final double width;
  final Animation<double> fill;

  const ProgressPartTrack({super.key, required this.width, required this.fill});

  static const double height = 4;

  /// The line beside the parts: a step lighter than other secondary text,
  /// the parts say it already.
  static TextStyle lineStyle(BuildContext context) {
    final palette = YiviPalette.of(context);
    return palette
        .body(15)
        .copyWith(height: 20 / 15, color: palette.secondaryText);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        width: width,
        height: height,
        color: palette.text.withValues(alpha: 0.12),
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedBuilder(
          animation: fill,
          builder: (context, _) => FractionallySizedBox(
            widthFactor: YiviMotion.ease.transform(fill.value),
            heightFactor: 1,
            child: ColoredBox(color: palette.successText),
          ),
        ),
      ),
    );
  }
}
