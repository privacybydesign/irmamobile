import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../util/adaptive_layout.dart";

/// The tablet layout of a tab: its list on the left and, on the right, a
/// rounded pane with the details of the picked item.
class TwoPane extends StatelessWidget {
  final Widget list;

  /// The details of the picked item, or null to show [placeholder].
  final Widget? detail;

  /// Shown in the detail pane while nothing is picked.
  final Widget? placeholder;

  const TwoPane({
    super.key,
    required this.list,
    required this.detail,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(32)),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: listPaneWidth, child: list),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              0,
              padding.top + 16,
              padding.right + 16,
              padding.bottom + 16,
            ),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: shape,
                color: palette.sheet,
                shadows: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: const ShapeBorderClipper(shape: shape),
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  removeLeft: true,
                  removeRight: true,
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: detail ?? placeholder ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Space the bottom of a tab's list keeps free: room for the floating tab
/// bar on phones, a plain margin next to the sidebar on tablets.
double bottomBarSpace(BuildContext context) =>
    isExpandedLayout(context) ? 24 : 112;
