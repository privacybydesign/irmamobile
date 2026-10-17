import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../irma_close_button.dart";
import "../pull_to_dismiss_physics.dart";
import "glass_surface.dart";

/// Shows [builder]'s content in the app's one sheet: a full-width glass sheet
/// attached to the bottom of the screen, at least [minHeightFraction] of the
/// screen tall (or exactly [heightFraction]), that closes on a tap outside it
/// or a drag down. It is a page route, so a [Hero] can fly into it. On
/// tablets it is a centred dialog with the same look.
///
/// The sheet adds no padding of its own: the content starts with a
/// [GlassSheetHeader] (or is a [GlassSheetContent]) and pads its body 16 from
/// the sides. Its bottom padding, clear of the home indicator, is in
/// `MediaQuery.paddingOf(context).bottom`, so a list can scroll under the
/// bottom edge.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double minHeightFraction = 0.5,
  double? heightFraction,
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
              child: _GlassSheet(
                attached: false,
                height: heightFraction == null
                    ? null
                    : MediaQuery.sizeOf(context).height * heightFraction,
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
  return Navigator.of(context).push(
    _GlassSheetRoute<T>(
      builder: builder,
      minHeightFraction: minHeightFraction,
      heightFraction: heightFraction,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

/// The scroll physics for a list in a sheet (see [GlassSheetScope]).
ScrollPhysics? glassSheetScrollPhysics(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<GlassSheetScope>()?.physics;

/// Hands a sheet's content the physics for its list: as on the credential's
/// page and in native iOS sheets, a drag that starts at the top of the list
/// pulls the sheet down with it, and far enough or fast enough closes it; a
/// drag that starts further down only scrolls.
class GlassSheetScope extends InheritedWidget {
  final ScrollPhysics physics;

  const GlassSheetScope({
    super.key,
    required this.physics,
    required super.child,
  });

  @override
  bool updateShouldNotify(GlassSheetScope oldWidget) =>
      physics != oldWidget.physics;
}

/// The route of a sheet: it slides up from the bottom over a dim barrier,
/// closes on a tap outside it, a drag down or a pull of its list, and is a
/// [PageRoute], so heroes fly into it (a modal bottom sheet is not).
class _GlassSheetRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final double minHeightFraction;
  final double? heightFraction;

  _GlassSheetRoute({
    required this.builder,
    required this.minHeightFraction,
    required this.heightFraction,
    required this.barrierLabel,
  }) {
    _pull.addListener(_followPull);
  }

  /// A pull this far, or a flick down this fast, closes the sheet: the
  /// numbers of the credential's page.
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 700.0;

  // How far the list is pulled down at its top.
  final _pull = ValueNotifier<double>(0);
  bool _dragStartedAtTop = false;
  bool _pulling = false;
  double _sheetHeight = 1;

  late final _physics = PullToDismissPhysics(
    pull: _pull,
    canPull: () =>
        _dragStartedAtTop && animation?.status != AnimationStatus.reverse,
    onRelease: _onPullReleased,
  );

  // From the start of a drag or pull until the sheet has settled after it:
  // the sheet then follows the finger one to one, without its curve.
  bool _gesture = false;

  void _startGesture() {
    if (_gesture) return;
    _gesture = true;
    navigator!.didStartUserGesture();
  }

  /// Closes the sheet, or springs it back open, and ends the gesture once it
  /// has settled, so the curve does not take over half way.
  void _settle({required bool close}) {
    void done(AnimationStatus status) {
      if (status.isAnimating) return;
      controller!.removeStatusListener(done);
      _gesture = false;
      navigator?.didStopUserGesture();
    }

    controller!.addStatusListener(done);
    if (close) {
      navigator!.pop();
    } else {
      controller!.forward();
    }
    if (!controller!.isAnimating) done(controller!.status);
  }

  void _followPull() {
    if (_pull.value <= 0) return;
    if (!_pulling) {
      _pulling = true;
      _startGesture();
    }
    controller!.value = 1 - _pull.value / _sheetHeight;
  }

  void _onPullReleased(double velocity) {
    final pulled = _pull.value;
    _pulling = false;
    _pull.value = 0;
    // A downward flick has a negative scroll velocity.
    _settle(close: pulled > _dismissDistance || velocity < -_dismissVelocity);
  }

  bool _onScrollStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      final m = notification.metrics;
      _dragStartedAtTop = m.pixels <= m.minScrollExtent + 0.5;
    }
    return false;
  }

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

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

  double _measure(BuildContext context) =>
      _sheetHeight = context.size?.height ?? _sheetHeight;

  /// Follows a drag of [delta] logical pixels on a sheet [height] tall.
  void _drag(double delta, double height) {
    controller!.value -= delta / height;
  }

  /// Ends a drag: closes on a fling down or past half way, else springs back.
  void _release(double velocity) => _settle(
    close: velocity > 700 || (velocity >= 0 && controller!.value < 0.5),
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    final screen = media.size.height;
    final maxHeight = screen - media.padding.top - 8;
    final height = heightFraction == null
        ? null
        : (screen * heightFraction!).clamp(0.0, maxHeight);
    return Padding(
      // Rides up on the keyboard.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (screen * minHeightFraction).clamp(0.0, maxHeight),
            maxHeight: maxHeight,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: LayoutBuilder(
              builder: (context, _) => GestureDetector(
                // Dragging the sheet outside its list (its header).
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => _startGesture(),
                onVerticalDragUpdate: (d) =>
                    _drag(d.primaryDelta ?? 0, _measure(context)),
                onVerticalDragEnd: (d) =>
                    _release(d.velocity.pixelsPerSecond.dy),
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: (n) {
                    _measure(context);
                    return _onScrollStart(n);
                  },
                  child: GlassSheetScope(
                    physics: _physics,
                    child: _GlassSheet(
                      attached: true,
                      height: height,
                      bottomInset: media.viewInsets.bottom > 0
                          ? 0
                          : media.padding.bottom,
                      child: builder(context),
                    ),
                  ),
                ),
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
  ) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final t = animation.value;
      final shown = _gesture
          ? t
          : (animation.status == AnimationStatus.reverse
                    ? Curves.easeInCubic
                    : Curves.easeOutCubic)
                .transform(t);
      return FractionalTranslation(
        translation: Offset(0, 1 - shown),
        child: child,
      );
    },
  );
}

/// The look of every sheet: frosted glass, corners of 38 (concentric with a
/// 44 close button inset 16). Attached to the bottom edge it has square
/// bottom corners, which the screen's own corners round off.
class _GlassSheet extends StatelessWidget {
  final bool attached;
  final double? height;
  // Room for the home indicator, handed to the content as its bottom padding.
  final double bottomInset;
  final Widget child;

  const _GlassSheet({
    required this.attached,
    required this.height,
    this.bottomInset = 0,
    required this.child,
  });

  static const _radius = Radius.circular(38);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: attached
          ? const BorderRadius.vertical(top: _radius)
          : const BorderRadius.all(_radius),
    );
    final media = MediaQuery.of(context);
    return GlassSurface(
      key: const Key("glass_sheet"),
      fill: palette.glassStrongFill,
      shape: shape,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: SizedBox(
          height: height,
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: 0, bottom: 20 + bottomInset),
              viewPadding: media.viewPadding.copyWith(top: 0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The top of a sheet: its title (and subtitle), the same round glass close
/// button as on a full screen, and a back button when [onBack] is set.
class GlassSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Space from the sides of the sheet to the title.
  final double sidePadding;

  const GlassSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.sidePadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          if (onBack != null)
            GlassIconButton(
              semanticsLabel: FlutterI18n.translate(context, "ui.go_back"),
              onTap: onBack,
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: palette.text,
              ),
            ),
          Expanded(
            child: Padding(
              // Centres a one-line title on the 44 buttons.
              padding: const EdgeInsets.only(top: 8),
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
                          .copyWith(
                            height: 20 / 14,
                            color: palette.secondaryText,
                          ),
                    ),
                ],
              ),
            ),
          ),
          const IrmaCloseButton(),
        ],
      ),
    );
  }
}

/// A sheet of a [GlassSheetHeader] with [title] over [child], which scrolls
/// when it is too tall. [child] pads itself from the sides.
class GlassSheetContent extends StatelessWidget {
  final String title;
  final Widget child;
  final double sidePadding;

  const GlassSheetContent({
    super.key,
    required this.title,
    required this.child,
    this.sidePadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSheetHeader(title: title, sidePadding: sidePadding),
        Flexible(
          child: SingleChildScrollView(
            physics: glassSheetScrollPhysics(context),
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// A sheet with the title [titleKey] over [child]: [GlassSheetContent] in
/// [showGlassSheet].
Future<void> showTitledGlassSheet({
  required BuildContext context,
  required String titleKey,
  required Widget child,
  double minHeightFraction = 0.5,
  double sidePadding = 16,
}) => showGlassSheet<void>(
  context: context,
  minHeightFraction: minHeightFraction,
  builder: (context) => GlassSheetContent(
    title: FlutterI18n.translate(context, titleKey),
    sidePadding: sidePadding,
    child: child,
  ),
);
