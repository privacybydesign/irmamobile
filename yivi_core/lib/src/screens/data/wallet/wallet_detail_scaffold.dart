import "dart:math";

import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/bars/scroll_edge.dart";
import "../../../widgets/buttons/close_button.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/sheet/pull_to_dismiss_physics.dart";
import "../card_transition/card_transition.dart";

/// Builds the scrollable content of a [WalletDetailScaffold]. Give the list
/// [physics], so pulling down at its top dismisses the page.
typedef WalletDetailBuilder =
    Widget Function(BuildContext context, ScrollPhysics physics);

/// Closes a card's details: through the card [transition] they are part of
/// (it takes the card back from where it is), else (none) by popping the
/// route on top.
void closeCardDetails(BuildContext context, CardTransition? transition) {
  if (transition != null) return transition.close();
  Navigator.of(context).maybePop();
}

/// A card's details, part of its [transition]: their background and bar
/// once the card is open, pull down at the top or swipe to the right to
/// close (the page follows the finger and shrinks a little), and a floating
/// close button over a fade.
class WalletDetailScaffold extends StatefulWidget {
  final WalletDetailBuilder builder;

  /// Key of the close button, for tests.
  final Key closeKey;

  /// Shown left of the close button, e.g. a compact title once the header
  /// has scrolled away. Gets the opacity the close button has.
  final Widget Function(BuildContext context, double opacity)? barBuilder;

  /// The card transition the page is part of: it moves the page, closing
  /// closes it, and the bar shows only while the card is open.
  final CardTransition transition;

  const WalletDetailScaffold({
    super.key,
    required this.builder,
    required this.closeKey,
    required this.transition,
    this.barBuilder,
  });

  @override
  State<WalletDetailScaffold> createState() => _WalletDetailScaffoldState();
}

class _WalletDetailScaffoldState extends State<WalletDetailScaffold>
    with SingleTickerProviderStateMixin {
  /// How far the page is pulled down at its top, to dismiss it.
  final _pull = ValueNotifier<double>(0);

  /// How far the page is swiped to the right, to dismiss it, as the back
  /// swipe of a page. Sideways scrolling content under the finger (the
  /// sibling cards) keeps its own drag.
  final _swipe = ValueNotifier<double>(0);
  bool _swiping = false;

  /// Springs the pull and the swipe back when they were not far enough to
  /// dismiss.
  late final _springBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  double _springFrom = 0;
  double _springFromSwipe = 0;

  /// As on iOS: only a drag that starts at the top can pull the page down.
  /// One that starts further down scrolls, and at the top it stretches
  /// (or bounces) as usual instead of pulling.
  bool _dragStartedAtTop = false;

  bool _onScrollStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      final metrics = notification.metrics;
      _dragStartedAtTop = metrics.pixels <= metrics.minScrollExtent + 0.5;
    }
    return false;
  }

  late final _physics = PullToDismissPhysics(
    pull: _pull,
    canPull: () {
      // A new drag takes over from a spring back.
      _springBack.stop();
      return _dragStartedAtTop &&
          widget.transition.phase != TransitionPhase.closing;
    },
    onRelease: _onPullReleased,
  );

  @override
  void initState() {
    super.initState();
    widget.transition.phaseListenable.addListener(_onPhase);
    _springBack.addListener(() {
      final t = Curves.easeOutBack.transform(_springBack.value);
      _pull.value = (_springFrom * (1 - t)).clamp(0, double.infinity);
      _swipe.value = (_springFromSwipe * (1 - t)).clamp(0, double.infinity);
    });
  }

  /// In a card transition: pulled down to close, and then pushed back open
  /// by a finger, the page springs back up.
  void _onPhase() {
    if (widget.transition.phase != TransitionPhase.open) return;
    if (_pull.value <= 0 && _swipe.value <= 0) return;
    _springBack.stop();
    _springFrom = _pull.value;
    _springFromSwipe = _swipe.value;
    _springBack.forward(from: 0);
  }

  void _onSwipeStart(DragStartDetails _) {
    _swiping =
        _pull.value == 0 && widget.transition.phase == TransitionPhase.open;
    // A new drag takes over from a spring back.
    if (_swiping) _springBack.stop();
  }

  void _onSwipeUpdate(DragUpdateDetails d) {
    if (!_swiping) return;
    // To the right only, the way back (mirrored right to left).
    final dx = Directionality.of(context) == TextDirection.rtl
        ? -d.delta.dx
        : d.delta.dx;
    _swipe.value = max(0, _swipe.value + dx);
  }

  void _onSwipeEnd(DragEndDetails d) {
    if (!_swiping) return;
    _swiping = false;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final velocity = (rtl ? -1 : 1) * d.velocity.pixelsPerSecond.dx;
    final width = MediaQuery.sizeOf(context).width;
    // As a page's back swipe: past a third of the way, or flicked.
    if (velocity > 500 || (velocity >= -100 && _swipe.value > width / 3)) {
      // The card goes back from where the page was swiped to.
      _close();
    } else {
      _springFrom = _pull.value;
      _springFromSwipe = _swipe.value;
      _springBack.forward(from: 0);
    }
  }

  void _onPullReleased(double velocity) {
    // Only while nothing is over the details (an activity entry's page).
    if (ModalRoute.of(context)?.isCurrent != true) return;
    // A downward flick has a negative scroll velocity.
    if (PullToDismissPhysics.shouldDismiss(_pull.value, -velocity)) {
      // From where the page was pulled to, at the finger's speed.
      widget.transition.close(velocity: -velocity);
    } else {
      _springFrom = _pull.value;
      _springBack.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.transition.phaseListenable.removeListener(_onPhase);
    _springBack.dispose();
    _pull.dispose();
    _swipe.dispose();
    super.dispose();
  }

  void _close() => closeCardDetails(context, widget.transition);

  /// 0 at rest, 1 at twice the dismiss distance (or swiped all the way).
  double get _pullProgress => max(
    (_pull.value / (2 * PullToDismissPhysics.dismissDistance)).clamp(0.0, 1.0),
    (_swipe.value / MediaQuery.sizeOf(context).width).clamp(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final transition = widget.transition;
    final chrome = Listenable.merge([
      _pull,
      _swipe,
      transition.phaseListenable,
    ]);
    // The bar and the background are there only while the card is open: the
    // transition draws the card and what is under it while it moves, and
    // the + of the bar below turns into the ✕. With Reduce Motion the
    // transition fades the whole page, these too.
    double chromeOpacity() =>
        (transition.phase == TransitionPhase.open || transition.still
            ? 1.0
            : 0.0) *
        (1 - _pullProgress);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Opaque once open.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: chrome,
              builder: (context, _) => ColoredBox(
                color: palette.background.withValues(
                  alpha:
                      (transition.phase == TransitionPhase.open ||
                              transition.still
                          ? 1.0
                          : 0.0) *
                      (1 - _pullProgress * 0.5),
                ),
              ),
            ),
          ),
          // The content scrolls under the bar. Only the close button (and
          // [barBuilder]) float over it, with the band behind them once
          // content is under them, as in a sheet.
          Positioned.fill(
            child: ScrollEdge(
              height: padding.top + YiviAppBar.toolbarHeight,
              band: (context, under) => AnimatedBuilder(
                animation: chrome,
                builder: (context, _) =>
                    ScrollEdgeBand(under: under, opacity: chromeOpacity()),
              ),
              bar: [
                // Inside the safe area: clear of the Dynamic Island or an
                // unfolded phone's side panel.
                Positioned(
                  top: padding.top + YiviAppBar.buttonTop,
                  left: 16 + padding.left,
                  right: 16 + padding.right,
                  // Faded by the surface itself (Surface.opacity).
                  child: AnimatedBuilder(
                    animation: chrome,
                    builder: (context, _) => Row(
                      children: [
                        // A little in from the edge.
                        const SizedBox(width: YiviSpace.x12),
                        Expanded(
                          child:
                              widget.barBuilder?.call(
                                context,
                                chromeOpacity(),
                              ) ??
                              const SizedBox.shrink(),
                        ),
                        const SizedBox(width: YiviSpace.x8),
                        Builder(
                          builder: (context) {
                            // Opened from a notification or a search: no +
                            // turned into it; the transition turned this ✕
                            // in.
                            if (!transition.origin.plusTurnsIntoClose) {
                              return YiviCloseButton(
                                key: widget.closeKey,
                                onTap: _close,
                                opacity: chromeOpacity(),
                              );
                            }
                            // Opened from the Data tab: the bar's + turned is
                            // the close button, here where the bar's was.
                            return _PlusAsClose(
                              closeKey: widget.closeKey,
                              onTap: _close,
                              opacity: chromeOpacity(),
                              still: MediaQuery.disableAnimationsOf(context),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // The page follows the finger down or to the side, shrinking
              // a little.
              child: GestureDetector(
                onHorizontalDragStart: _onSwipeStart,
                onHorizontalDragUpdate: _onSwipeUpdate,
                onHorizontalDragEnd: _onSwipeEnd,
                onHorizontalDragCancel: () =>
                    _onSwipeEnd(DragEndDetails(primaryVelocity: 0)),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pull, _swipe]),
                  child: NotificationListener<ScrollStartNotification>(
                    onNotification: _onScrollStart,
                    child: widget.builder(context, _physics),
                  ),
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      Directionality.of(context) == TextDirection.rtl
                          ? -_swipe.value
                          : _swipe.value,
                      _pull.value,
                    ),
                    child: Transform.scale(
                      scale: 1 - _pullProgress * 0.06,
                      alignment: Alignment.topCenter,
                      child: child,
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

/// The close button of a page opened from a bar with a + (the Data tab):
/// that + turned 45° ([YiviIconButton.plusAsClose]), the same button the
/// bar's + has turned into, so taking over from it shows nothing. With
/// reduced motion the + does not turn: there it is the ✕.
class _PlusAsClose extends StatelessWidget {
  final Key closeKey;
  final VoidCallback onTap;
  final double opacity;
  final bool still;

  const _PlusAsClose({
    required this.closeKey,
    required this.onTap,
    required this.opacity,
    required this.still,
  });

  @override
  Widget build(BuildContext context) {
    if (still) {
      return YiviCloseButton(key: closeKey, onTap: onTap, opacity: opacity);
    }
    return Transform.rotate(
      angle: pi / 4,
      child: Transform.scale(
        scale: YiviIconButton.plusAsClose,
        child: YiviIconButton(
          key: closeKey,
          icon: CupertinoIcons.add,
          label: context.tr("accessibility.close"),
          onTap: onTap,
          opacity: opacity,
          look: IconButtonLook.bar,
        ),
      ),
    );
  }
}
