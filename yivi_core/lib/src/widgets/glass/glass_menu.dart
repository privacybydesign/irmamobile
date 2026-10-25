import "dart:math";

import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "glass_surface.dart";

/// One choice in a [showGlassMenu].
class GlassMenuItem<T> {
  final T value;
  final String label;
  final IconData icon;
  final Key? key;

  const GlassMenuItem({
    required this.value,
    required this.label,
    required this.icon,
    this.key,
  });
}

/// An iOS pull-down menu of [items] under the button at [anchor]: glass,
/// growing out of the button's corner, a row lighting up grey as it is
/// pressed. [footnote] is a line of help under the choices. Resolves to the
/// picked item's value, or null when it is closed without a pick.
Future<T?> showGlassMenu<T>(
  BuildContext anchor, {
  required List<GlassMenuItem<T>> items,
  String? footnote,
}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  HapticFeedback.selectionClick();
  return Navigator.of(anchor).push(
    _GlassMenuRoute<T>(
      anchor: rect,
      items: items,
      footnote: footnote,
      rtl: Directionality.of(anchor) == TextDirection.rtl,
      barrierLabel: MaterialLocalizations.of(anchor).modalBarrierDismissLabel,
    ),
  );
}

class _GlassMenuRoute<T> extends PopupRoute<T> {
  final Rect anchor;
  final List<GlassMenuItem<T>> items;
  final String? footnote;
  final bool rtl;

  @override
  final String barrierLabel;

  _GlassMenuRoute({
    required this.anchor,
    required this.items,
    required this.footnote,
    required this.rtl,
    required this.barrierLabel,
  });

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return CustomSingleChildLayout(
      delegate: _MenuPlacement(
        anchor: anchor,
        padding: MediaQuery.paddingOf(context),
        rtl: rtl,
      ),
      child: _Menu<T>(items: items, footnote: footnote),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    // It grows out of the button: from the corner under it.
    final placement = _MenuPlacement.below(anchor, MediaQuery.sizeOf(context));
    final alignment = Alignment(rtl ? 1 : -1, placement ? -1 : 1);
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
      child: ScaleTransition(
        alignment: alignment,
        scale: Tween(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: YiviMotion.overshoot,
            reverseCurve: Curves.easeIn,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Puts the menu under the button, its start in line with the button's;
/// above it when there is no room below. Keeps 16 from the screen's sides.
class _MenuPlacement extends SingleChildLayoutDelegate {
  static const double width = 250;
  static const double gap = 8;
  static const double margin = 16;

  final Rect anchor;
  final EdgeInsets padding;
  final bool rtl;

  _MenuPlacement({
    required this.anchor,
    required this.padding,
    required this.rtl,
  });

  /// Whether the menu goes under the button: when that half of the screen
  /// has the most room.
  static bool below(Rect anchor, Size screen) =>
      anchor.center.dy < screen.height * 0.6;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final room = below(anchor, constraints.biggest)
        ? constraints.maxHeight - anchor.bottom - gap - padding.bottom - margin
        : anchor.top - gap - padding.top - margin;
    return BoxConstraints(
      maxWidth: min(width, constraints.maxWidth - 2 * margin),
      maxHeight: max(0, room),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = rtl ? anchor.right - childSize.width : anchor.left;
    final y = below(anchor, size)
        ? anchor.bottom + gap
        : anchor.top - gap - childSize.height;
    return Offset(
      x.clamp(margin, max(margin, size.width - margin - childSize.width)),
      y,
    );
  }

  @override
  bool shouldRelayout(_MenuPlacement old) =>
      old.anchor != anchor || old.padding != padding || old.rtl != rtl;
}

class _Menu<T> extends StatelessWidget {
  final List<GlassMenuItem<T>> items;
  final String? footnote;

  const _Menu({required this.items, required this.footnote});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final divider = Container(
      height: 0.5,
      color: palette.secondaryText.withValues(alpha: 0.25),
    );
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    );
    // The stronger glass of a toast: the cards under it are busy.
    return GlassSurface(
      shape: shape,
      fill: palette.glassStrongFill,
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) divider,
                _Row(item: item, palette: palette),
              ],
              if (footnote != null) ...[
                Container(
                  height: 6,
                  color: palette.secondaryText.withValues(alpha: 0.08),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Text(
                    footnote!,
                    style: palette
                        .body(12.5)
                        .copyWith(
                          height: 17 / 12.5,
                          color: palette.secondaryText,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A choice: its name and its icon at the end, as iOS has them.
class _Row<T> extends StatelessWidget {
  final GlassMenuItem<T> item;
  final YiviPalette palette;

  const _Row({required this.item, required this.palette});

  @override
  Widget build(BuildContext context) {
    // The theme's grey lights the row up while it is pressed, as on iOS.
    return InkWell(
      key: item.key,
      onTap: () => Navigator.of(context).pop(item.value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 46),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: palette.body(16).copyWith(color: palette.text),
                ),
              ),
              Icon(item.icon, size: 20, color: palette.text),
            ],
          ),
        ),
      ),
    );
  }
}
