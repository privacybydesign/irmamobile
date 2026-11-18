import "package:material_ui/material_ui.dart";

import "../../theme/yivi_space.dart";
import "../buttons/pill_buttons.dart";
import "irma_bottom_bar_base.dart";

/// The buttons at the bottom of a page: one look everywhere. It floats
/// over the page with a fade above it, keeps clear of the home indicator
/// and the sides, and stacks its [actions] (the main one first) upright,
/// or puts them in a row when the screen is low (a phone held sideways).
/// [above] is a reason or a note over the buttons. Labels arrive
/// translated.
class ActionBar extends StatelessWidget {
  final List<Widget> actions;
  final Widget? above;

  const ActionBar({super.key, required this.actions, this.above});

  /// One main button: the red one, or a dark red one when it [danger]ously
  /// deletes something.
  ActionBar.single({
    super.key,
    required String label,
    required VoidCallback? onTap,
    bool danger = false,
  }) : above = null,
       actions = [primary(label: label, onTap: onTap, danger: danger)];

  /// The main button of a bar.
  static Widget primary({
    required String label,
    required VoidCallback? onTap,
    bool danger = false,
  }) => danger
      ? PillButton(
          key: const Key("bottom_bar_primary"),
          label: label,
          onPressed: onTap,
          style: PillStyle.dangerFilled,
          size: PillSize.large,
        )
      : FancyPillButton(
          key: const Key("bottom_bar_primary"),
          label: label,
          onPressed: onTap,
        );

  /// A plain text button under (or, sideways, before) the main one.
  static Widget secondary({
    required String label,
    required VoidCallback? onTap,
  }) => PillButton(
    key: const Key("bottom_bar_secondary"),
    label: label,
    onPressed: onTap,
    style: PillStyle.text,
    size: PillSize.large,
  );

  /// Lower than this, the buttons go in a row.
  static const double _rowBelow = 450;

  @override
  Widget build(BuildContext context) {
    final upright = MediaQuery.sizeOf(context).height > _rowBelow;
    final last = actions.lastOrNull;
    final endsWithText =
        upright &&
        (last is TextLink ||
            (last is PillButton && last.style == PillStyle.text));
    final buttons = upright || actions.length < 2
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: YiviSpace.x8,
            children: actions,
          )
        : Row(
            spacing: YiviSpace.x4,
            children: [for (final a in actions.reversed) Expanded(child: a)],
          );
    return IrmaBottomBarBase(
      // "Cancel" under the main button sits low, as on iOS.
      endsWithTextButton: endsWithText,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (above case final above?)
            Padding(
              padding: const EdgeInsets.only(bottom: YiviSpace.x12),
              child: above,
            ),
          // A bar of one button ends where every bar does.
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x4),
            child: buttons,
          ),
        ],
      ),
    );
  }
}
