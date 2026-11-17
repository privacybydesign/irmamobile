import "package:material_ui/material_ui.dart";

import "../theme/yivi_motion.dart";
import "../theme/yivi_palette.dart";

/// One part of a progress made of short parts (the share screen's, and that
/// of adding a card in a sheet): grey, [width] by 4, filled green from the
/// start edge when [filled]. It fills (or empties) over [YiviMotion.page]
/// when [filled] changes; at once under Reduce Motion.
class ProgressPart extends StatefulWidget {
  final double width;
  final bool filled;

  const ProgressPart({super.key, required this.width, required this.filled});

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
  State<ProgressPart> createState() => _ProgressPartState();
}

class _ProgressPartState extends State<ProgressPart>
    with SingleTickerProviderStateMixin {
  late final _fill = AnimationController(
    vsync: this,
    duration: YiviMotion.page,
    value: widget.filled ? 1 : 0,
  );

  @override
  void didUpdateWidget(ProgressPart old) {
    super.didUpdateWidget(old);
    if (widget.filled == old.filled) return;
    final to = widget.filled ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fill.value = to;
    } else {
      _fill.animateTo(to);
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(ProgressPart.height / 2),
      child: Container(
        width: widget.width,
        height: ProgressPart.height,
        color: palette.text.withValues(alpha: 0.12),
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedBuilder(
          animation: _fill,
          builder: (context, _) => FractionallySizedBox(
            widthFactor: YiviMotion.ease.transform(_fill.value),
            heightFactor: 1,
            child: ColoredBox(color: palette.successText),
          ),
        ),
      ),
    );
  }
}
