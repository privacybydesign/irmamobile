import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "glass_surface.dart";

/// Shows [builder]'s content in a floating glass sheet: inset 8 from the
/// screen edges, with rounded corners all round and a handle, as in the
/// design. On tablets it is a centred dialog with the same look.
///
/// The content usually starts with a [GlassSheetHeader].
///
/// With [attached] it is a full-width sheet attached to the bottom of the
/// screen instead, shown in a page route so a [Hero] can fly into it.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool attached = false,
}) {
  if (isExpandedLayout(context)) {
    return showDialog<T>(
      context: context,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: _GlassSheet(handle: false, child: builder(context)),
            ),
          ),
        ),
      ),
    );
  }
  if (attached) {
    return Navigator.of(context).push(
      _AttachedSheetRoute<T>(
        builder: builder,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: const Color(0x470C1824),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        0,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: _GlassSheet(handle: true, child: builder(context)),
    ),
  );
}

/// The route of an attached sheet: it slides up from the bottom over a dim
/// barrier, closes on a tap outside it or a drag down, and is a [PageRoute],
/// so heroes fly into it (a modal bottom sheet is not).
class _AttachedSheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  _AttachedSheetRoute({required this.builder, required this.barrierLabel});

  @override
  final String barrierLabel;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => const Color(0x470C1824);

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  /// Follows a drag of [delta] logical pixels on a sheet [height] tall.
  void _drag(double delta, double height) {
    controller!.value -= delta / height;
  }

  /// Ends a drag: closes on a fling down or past half way, else springs back.
  void _release(double velocity) {
    final close = velocity > 700 || (velocity >= 0 && controller!.value < 0.5);
    if (close) {
      navigator!.pop();
    } else {
      controller!.forward();
    }
    navigator!.didStopUserGesture();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final padding = MediaQuery.paddingOf(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height - padding.top - 8,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, _) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => navigator!.didStartUserGesture(),
              onVerticalDragUpdate: (d) =>
                  _drag(d.primaryDelta ?? 0, context.size?.height ?? 1),
              onVerticalDragEnd: (d) => _release(d.velocity.pixelsPerSecond.dy),
              child: _GlassSheet(
                handle: true,
                attached: true,
                bottomInset: padding.bottom,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    ),
    child: child,
  );
}

class _GlassSheet extends StatelessWidget {
  final bool handle;
  // Full width at the bottom edge: square bottom corners, which the screen's
  // own corners round off, and room for the home indicator.
  final bool attached;
  final double bottomInset;
  final Widget child;

  const _GlassSheet({
    required this.handle,
    this.attached = false,
    this.bottomInset = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return GlassSurface(
      key: const Key("glass_sheet"),
      fill: palette.glassStrongFill,
      shape: RoundedSuperellipseBorder(
        borderRadius: attached
            ? const BorderRadius.vertical(top: Radius.circular(38))
            : const BorderRadius.all(Radius.circular(38)),
      ),
      // Attached, the content runs to the bottom edge, so a list scrolls
      // under it; it finds its bottom padding in MediaQuery.padding.
      padding: EdgeInsets.fromLTRB(16, handle ? 10 : 18, 16, attached ? 0 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (handle)
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: palette.handle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          Flexible(
            child: attached
                ? MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.paddingOf(
                        context,
                      ).copyWith(top: 0, bottom: 20 + bottomInset),
                    ),
                    child: child,
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

/// The top of a glass sheet: its title and a line under it, a round glass
/// close button, and a back button when [onBack] is set.
class GlassSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  const GlassSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    Widget round(IconData icon, String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: GlassSurface(
          shape: const CircleBorder(),
          child: SizedBox.square(
            dimension: 38,
            child: Icon(icon, size: 18, color: palette.text),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        if (onBack != null)
          round(
            Icons.arrow_back_rounded,
            FlutterI18n.translate(context, "ui.go_back"),
            onBack!,
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  key: const Key("glass_sheet_title"),
                  style: palette.display(19).copyWith(color: palette.text),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: palette
                      .body(14)
                      .copyWith(height: 20 / 14, color: palette.secondaryText),
                ),
            ],
          ),
        ),
        round(
          Icons.close_rounded,
          FlutterI18n.translate(context, "accessibility.close"),
          () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
