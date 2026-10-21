import "dart:math";

import "package:flutter_i18n/flutter_i18n.dart";
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
    final phone = usePhoneLandscape(context);
    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(32)),
    );

    // On a phone held sideways the pane reaches into the safe area on the
    // right (12 from the top and bottom, 16 from the edge); its content
    // keeps out of it through [paneContentPadding].
    final paneMargin = phone
        ? const EdgeInsets.fromLTRB(0, 12, 16, 12)
        : EdgeInsets.fromLTRB(
            0,
            padding.top + 16,
            padding.right + 16,
            padding.bottom + 16,
          );
    final inPane = MediaQuery.of(context).copyWith(
      padding: phone
          ? EdgeInsets.only(right: max(0, padding.right - 16))
          : EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
    );

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: phone
                ? phoneListPaneWidth(constraints.maxWidth)
                : listPaneWidth,
            // The pane covers the safe area on the right, not the list.
            child: MediaQuery.removePadding(
              context: context,
              removeRight: phone,
              child: list,
            ),
          ),
          Expanded(
            child: Padding(
              padding: paneMargin,
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
                  child: MediaQuery(
                    data: inPane,
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
      ),
    );
  }
}

/// The list's width on a phone held sideways: its content (the tabs keep 16
/// on either side) is 300 on an iPhone 17 Pro, between 260 and 320 on
/// others.
double phoneListPaneWidth(double available) =>
    ((available - 32) * 0.415).clamp(260, 320).roundToDouble() + 32;

/// The padding of what a detail pane shows: 32 on a tablet; 20 on a phone
/// held sideways, plus the part of the safe area the pane reaches into.
EdgeInsets paneContentPadding(BuildContext context) {
  final side = usePhoneLandscape(context) ? 20.0 : 32.0;
  final padding = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    side,
    side + padding.top,
    side + padding.right,
    side + padding.bottom,
  );
}

/// Space the bottom of a tab's list keeps free: room for the floating tab
/// bar on phones, a plain margin where the tabs are a sidebar or a rail.
double bottomBarSpace(BuildContext context) => useHomePanes(context) ? 24 : 112;

/// The title at the top of a page shown in a detail pane (Instellingen,
/// Veelgestelde vragen) instead of its app bar.
class PaneTitle extends StatelessWidget {
  final String translationKey;

  const PaneTitle(this.translationKey, {super.key});

  /// The padding of a page in a pane; a SafeArea inside it keeps it out of
  /// the part of the safe area the pane reaches into.
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 24);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Semantics(
        header: true,
        child: Text(
          FlutterI18n.translate(context, translationKey),
          style: palette.display(22, weight: FontWeight.w700),
        ),
      ),
    );
  }
}
