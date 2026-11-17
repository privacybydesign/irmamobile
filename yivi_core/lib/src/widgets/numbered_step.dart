import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../theme/yivi_space.dart";

/// One step of a numbered list: the [number] on a tinted disc, then
/// [child], whose first line sits level with the number. The number is
/// hidden from screen readers; the step's text says it all.
///
/// A plain [Text] child gets the step text style (15 on 21, heading
/// colour) unless it sets its own.
class NumberedStep extends StatelessWidget {
  final int number;
  final Widget child;

  /// A smaller disc and gap, for steps inside a card.
  final bool compact;

  const NumberedStep({
    super.key,
    required this.number,
    required this.child,
    this.compact = false,
  });

  /// The disc's width, and the step text's line height.
  static const double _disc = 26;
  static const double _discCompact = 22;
  static const double _line = 21;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final disc = compact ? _discCompact : _disc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: compact ? YiviSpace.x8 : YiviSpace.x12,
      children: [
        ExcludeSemantics(
          child: Container(
            width: disc,
            height: disc,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.tint,
              shape: BoxShape.circle,
            ),
            child: Text(
              "$number",
              style: palette
                  .body(compact ? 12 : 13, weight: FontWeight.w700)
                  .copyWith(color: palette.link, height: 1),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            // The first line's middle level with the disc's.
            padding: EdgeInsets.only(top: compact ? 0 : (disc - _line) / 2),
            child: DefaultTextStyle.merge(
              style: palette
                  .body(15)
                  .copyWith(height: _line / 15, color: palette.heading),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
