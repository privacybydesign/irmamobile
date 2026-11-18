import "dart:math";

import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/irma_app_bar.dart";
import "../../../widgets/bars/scroll_edge.dart";
import "../../../widgets/buttons/irma_close_button.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/sheet/pull_to_dismiss_physics.dart";
import "../card_transition/card_transition.dart";
import "wallet_transition.dart";

/// Builds the scrollable content of a [WalletDetailScaffold]. Give the list
/// [physics], so pulling down at its top dismisses the page.
typedef WalletDetailBuilder =
    Widget Function(
      BuildContext context,
      ScrollPhysics physics,
      Animation<double> animation,
    );

/// Closes a card's details: through the card [transition] they are part of
/// (it takes the card back from where it is), else by popping their route.
void closeCardDetails(BuildContext context, CardTransition? transition) {
  if (transition != null) return transition.close();
  Navigator.of(context).maybePop();
}

/// The page of a detail route opened with the Wallet-style transition
/// ([WalletDetailPage]): a background that fades in once the other content
/// has moved away, pull down at the top or swipe to the right to dismiss
/// (the page follows the finger and shrinks a little), and a floating close
/// button over a fade.
///
/// The content itself flies in as heroes and fades up with [WalletReveal].
class WalletDetailScaffold extends StatefulWidget {
  /// What is open, for [WalletTransition.openKey]: the items of the page
  /// below with this key stay put while the rest moves away.
  final String openKey;

  final WalletDetailBuilder builder;

  /// Key of the close button, for tests.
  final Key closeKey;

  /// Shown left of the close button, e.g. a compact title once the header
  /// has scrolled away. Gets the opacity the close button has.
  final Widget Function(BuildContext context, double opacity)? barBuilder;

  /// The card transition the page is part of (opened from the stack): then
  /// the transition moves it, closing closes the transition, and its bar
  /// shows only while the card is open.
  final CardTransition? transition;

  const WalletDetailScaffold({
    super.key,
    required this.openKey,
    required this.builder,
    required this.closeKey,
    this.barBuilder,
    this.transition,
  });

  @override
  State<WalletDetailScaffold> createState() => _WalletDetailScaffoldState();
}

class _WalletDetailScaffoldState extends State<WalletDetailScaffold>
    with SingleTickerProviderStateMixin {
  Animation<double>? _routeAnimation;

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
          _routeAnimation?.status != AnimationStatus.reverse;
    },
    onRelease: _onPullReleased,
  );

  @override
  void initState() {
    super.initState();
    widget.transition?.phaseListenable.addListener(_onPhase);
    _springBack.addListener(() {
      final t = Curves.easeOutBack.transform(_springBack.value);
      _pull.value = (_springFrom * (1 - t)).clamp(0, double.infinity);
      _swipe.value = (_springFromSwipe * (1 - t)).clamp(0, double.infinity);
    });
  }

  /// In a card transition: pulled down to close, and then pushed back open
  /// by a finger, the page springs back up.
  void _onPhase() {
    if (widget.transition?.phase != TransitionPhase.open) return;
    if (_pull.value <= 0 && _swipe.value <= 0) return;
    _springBack.stop();
    _springFrom = _pull.value;
    _springFromSwipe = _swipe.value;
    _springBack.forward(from: 0);
  }

  void _onSwipeStart(DragStartDetails _) {
    _swiping =
        _pull.value == 0 &&
        _routeAnimation?.status != AnimationStatus.reverse &&
        (widget.transition?.phase ?? TransitionPhase.open) ==
            TransitionPhase.open;
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
    // Only while this page is on top: the pull stays as the page closes (the
    // heroes fly back from where it was pulled to), and its list settles
    // again during the close, which reported the release once more. A
    // second close popped the page below too, and from home that sends the
    // app to the background.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    // A downward flick has a negative scroll velocity.
    if (PullToDismissPhysics.shouldDismiss(_pull.value, -velocity)) {
      // From where the page was pulled to, at the finger's speed.
      if (widget.transition case final t?) return t.close(velocity: -velocity);
      _close();
    } else {
      _springFrom = _pull.value;
      _springBack.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // In a card transition it is no route of its own.
    if (widget.transition != null) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = animation?..addStatusListener(_onRouteStatus);
    }
    // Opened without a tap on the page below (e.g. from a notification):
    // still let that page know what is open. After this build: the page
    // below listens.
    if (WalletTransition.openKey.value == null) {
      afterFrame(() => WalletTransition.openKey.value ??= widget.openKey);
    }
  }

  @override
  void didUpdateWidget(WalletDetailScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openKey != widget.openKey && widget.transition == null) {
      WalletTransition.openKey.value = widget.openKey;
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    WalletTransition.closing = status == AnimationStatus.reverse;
    if (status == AnimationStatus.dismissed) {
      WalletTransition.openKey.value = null;
    }
  }

  @override
  void dispose() {
    widget.transition?.phaseListenable.removeListener(_onPhase);
    _springBack.dispose();
    _pull.dispose();
    _swipe.dispose();
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    final key = widget.openKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WalletTransition.openKey.value == key) {
        WalletTransition.openKey.value = null;
      }
    });
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
    final animation = _routeAnimation ?? kAlwaysCompleteAnimation;
    final transition = widget.transition;
    final chrome = Listenable.merge([
      animation,
      _pull,
      _swipe,
      transition?.phaseListenable,
    ]);
    // In a card transition the bar is there only while the card is open:
    // the + of the bar below turns into its ✕ as it opens.
    double chromeOpacity() =>
        (transition != null
            ? (transition.phase == TransitionPhase.open ? 1.0 : 0.0)
            : const Interval(0.4, 1).transform(animation.value)) *
        (1 - _pullProgress);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Transparent while the page below moves away, opaque once open.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: chrome,
              builder: (context, _) => ColoredBox(
                color: palette.background.withValues(
                  alpha:
                      // Closing: clears once the details have gone
                      // (WalletReveal), so they never lie over the cards
                      // coming back.
                      // In a card transition only once it is open: the
                      // transition paints the band under the card while
                      // it moves.
                      (transition != null
                          ? (transition.phase == TransitionPhase.open
                                ? 1.0
                                : 0.0)
                          : (WalletTransition.closing
                                    ? const Interval(0.55, 0.85)
                                    : const Interval(0.6, 1))
                                .transform(animation.value)) *
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
              height: padding.top + IrmaAppBar.toolbarHeight,
              band: (context, under) => AnimatedBuilder(
                animation: chrome,
                builder: (context, _) =>
                    ScrollEdgeBand(under: under, opacity: chromeOpacity()),
              ),
              bar: [
                // Inside the safe area: clear of the Dynamic Island or an
                // unfolded phone's side panel.
                Positioned(
                  top: padding.top + IrmaAppBar.buttonTop,
                  left: 16 + padding.left,
                  right: 16 + padding.right,
                  // Faded by the surface itself (GlassSurface.opacity).
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
                            // Takes over from the bar's buttons below,
                            // where they were (WalletTransition.closeButton).
                            final (opacity, turn) =
                                WalletTransition.closeButton(animation.value);
                            final still = MediaQuery.disableAnimationsOf(
                              context,
                            );
                            // Opened from the bar's +: that + turned is the
                            // close button, here where the bar's was.
                            if (transition != null) {
                              return _PlusAsClose(
                                closeKey: widget.closeKey,
                                onTap: _close,
                                opacity: chromeOpacity(),
                                still: still,
                              );
                            }
                            // From the list: the bar's + is covered by this
                            // page as it opens, so this one turns over it
                            // from the start.
                            if (WalletTransition.closeFromPlus) {
                              return _PlusAsClose(
                                closeKey: widget.closeKey,
                                onTap: _close,
                                opacity:
                                    (still ? opacity : 1) * (1 - _pullProgress),
                                turn: WalletTransition.barProgress(
                                  animation.value,
                                ),
                                still: still,
                              );
                            }
                            return Transform.rotate(
                              angle: still ? 0 : turn * pi / 180,
                              child: IrmaCloseButton(
                                key: widget.closeKey,
                                onTap: _close,
                                opacity: opacity * (1 - _pullProgress),
                              ),
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
                    child: widget.builder(context, _physics, animation),
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

/// Fades its child in as the route opens, where it is.
class WalletReveal extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const WalletReveal({super.key, required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final opening = animation.status != AnimationStatus.reverse;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = opening
            ? const Interval(0.35, 1).transform(animation.value)
            // Closing: gone in the first fifth, before the other cards
            // come back up under it.
            : const Interval(0.8, 1).transform(animation.value);
        return Opacity(
          opacity: t,
          // Only fades, where it is: what flies starts and ends there.
          child: child,
        );
      },
      child: child,
    );
  }
}

/// The close button of a page opened from a bar with a + (the Data tab):
/// that + turned 45° ([YiviIconButton.plusAsClose]), the same button the
/// bar's + has turned into, so taking over from it shows nothing; or, with
/// [turn] less than 1, that + on its way (0 is the + as in the bar). With
/// reduced motion the + does not turn: there it is the ✕.
class _PlusAsClose extends StatelessWidget {
  final Key closeKey;
  final VoidCallback onTap;
  final double opacity;
  final double turn;
  final bool still;

  const _PlusAsClose({
    required this.closeKey,
    required this.onTap,
    required this.opacity,
    required this.still,
    this.turn = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (still) {
      return IrmaCloseButton(key: closeKey, onTap: onTap, opacity: opacity);
    }
    return Transform.rotate(
      angle: pi / 4 * turn,
      child: Transform.scale(
        scale: 1 + (YiviIconButton.plusAsClose - 1) * turn,
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
