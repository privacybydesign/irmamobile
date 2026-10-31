import "dart:math";

import "package:flutter/cupertino.dart" show CupertinoIcons;

import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../util/after_frame.dart";
import "../../../widgets/glass/round_icon_button.dart";
import "../../../widgets/glass/scroll_edge.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_close_button.dart";
import "../../../widgets/pull_to_dismiss_physics.dart";
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

/// The page of a detail route opened with the Wallet-style transition
/// ([WalletDetailPage]): a background that fades in once the other content
/// has moved away, pull down at the top to dismiss (the page follows the
/// finger and shrinks a little), and a floating close button over a fade.
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

  /// Springs the pull back when it was not far enough to dismiss.
  late final _springBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  double _springFrom = 0;

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

  /// A pull this far, or a flick down this fast, closes the page.

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
    });
  }

  /// In a card transition: pulled down to close, and then pushed back open
  /// by a finger, the page springs back up.
  void _onPhase() {
    if (widget.transition?.phase != TransitionPhase.open) return;
    if (_pull.value <= 0) return;
    _springFrom = _pull.value;
    _springBack.forward(from: 0);
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
    // A close goes on from where everything is now (also halfway through
    // opening), and from where the page was pulled to.
    if (status == AnimationStatus.reverse) {
      WalletTransition.reverseFrom = _routeAnimation?.value ?? 1;
      WalletTransition.pullAtClose = _pull.value;
    }
    if (status == AnimationStatus.dismissed) {
      WalletTransition.stack = null;
      WalletTransition.openKey.value = null;
    }
  }

  @override
  void dispose() {
    widget.transition?.phaseListenable.removeListener(_onPhase);
    _springBack.dispose();
    _pull.dispose();
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    final key = widget.openKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (WalletTransition.openKey.value == key) {
        WalletTransition.openKey.value = null;
      }
    });
    super.dispose();
  }

  void _close() {
    // In a card transition: it takes the card back from where it is.
    if (widget.transition case final t?) return t.close();
    Navigator.of(context).maybePop();
  }

  /// 0 at rest, 1 at twice the dismiss distance.
  double get _pullProgress =>
      (_pull.value / (2 * PullToDismissPhysics.dismissDistance)).clamp(
        0.0,
        1.0,
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
          // From the stack (Wallet depth) only the band of the details is
          // filled while it moves: from the card's bottom to where the card
          // below it has slid away.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: chrome,
              builder: (context, _) =>
                  WalletTransition.stack != null && !animation.isCompleted
                  ? _StackBand(value: animation.value)
                  : ColoredBox(
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
                        Expanded(
                          child:
                              widget.barBuilder?.call(
                                context,
                                chromeOpacity(),
                              ) ??
                              const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            // Takes over from the bar's buttons below,
                            // where they were (WalletTransition.closeButton).
                            final (opacity, turn) =
                                WalletTransition.closeButton(animation.value);
                            final still = MediaQuery.disableAnimationsOf(
                              context,
                            );
                            // In a card transition: takes over from the
                            // bar's turned + as that same +, then turns
                            // into the ✕.
                            if (transition != null) {
                              return _CloseFromPlus(
                                closeKey: widget.closeKey,
                                onTap: _close,
                                opacity: chromeOpacity(),
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
              // The page follows the finger down, shrinking a little.
              child: ValueListenableBuilder<double>(
                valueListenable: _pull,
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: _onScrollStart,
                  child: widget.builder(context, _physics, animation),
                ),
                builder: (context, pull, child) => Transform.translate(
                  offset: Offset(0, pull),
                  child: Transform.scale(
                    scale: 1 - _pullProgress * 0.06,
                    alignment: Alignment.topCenter,
                    child: child,
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

/// The page's background while a card opens from the stack: only between
/// the card's bottom and the card below it.
class _StackBand extends StatelessWidget {
  final double value;

  const _StackBand({required this.value});

  @override
  Widget build(BuildContext context) {
    final open = WalletTransition.stack!;
    final top = WalletTransition.stackCardTop(value) + open.cardHeight;
    final bottom = WalletTransition.stackRevealLine(
      value,
      MediaQuery.sizeOf(context).height,
    );
    return Stack(
      children: [
        if (bottom > top)
          Positioned(
            left: 0,
            right: 0,
            top: top,
            height: bottom - top,
            child: ColoredBox(
              color: YiviPalette.of(context).background.withValues(
                alpha: WalletTransition.closing
                    ? 1 -
                          (WalletTransition.closeFraction(value) / 0.3).clamp(
                            0.0,
                            1.0,
                          )
                    : 1,
              ),
            ),
          ),
      ],
    );
  }
}

/// Fades its child in as the route opens, where it is. From the stack
/// (Wallet depth) it hangs under the card instead, comes up with it, and
/// shows only above the card below as that slides away.
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
        if (WalletTransition.stack case final _? when !animation.isCompleted) {
          final value = animation.value;
          // The page is pulled down by pullAtClose already.
          final dy =
              WalletTransition.stackCardTop(value) -
              WalletTransition.stack!.targetTop -
              WalletTransition.pullAtClose;
          final box = context.findRenderObject() as RenderBox?;
          final restTop = box != null && box.hasSize && box.attached
              ? box.localToGlobal(Offset.zero).dy
              : 0.0;
          final line = WalletTransition.stackRevealLine(
            value,
            MediaQuery.sizeOf(context).height,
          );
          // Closing they also fade, in the first part: with no card below
          // to cover them (the last card) they would stay in sight.
          return Opacity(
            opacity: WalletTransition.closing
                ? 1 -
                      (WalletTransition.closeFraction(value) / 0.3).clamp(
                        0.0,
                        1.0,
                      )
                : 1,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: ClipRect(
                clipper: _Above(line - restTop - dy),
                child: child,
              ),
            ),
          );
        }
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

class _Above extends CustomClipper<Rect> {
  final double y;

  const _Above(this.y);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-1e5, -1e5, 1e5, y);

  @override
  bool shouldReclip(_Above oldClipper) => oldClipper.y != y;
}

/// The close button of a page opened by a card transition. It is there
/// only while the card is open ([opacity]); moving, the bar's + turns into
/// it. As it comes it is that turned + ([RoundIconButton.plusAsClose]),
/// where the bar's is, and cross-fades into the ✕ (a little larger and
/// bolder): it never pops in.
class _CloseFromPlus extends StatelessWidget {
  final Key closeKey;
  final VoidCallback onTap;
  final double opacity;
  final bool still;

  const _CloseFromPlus({
    required this.closeKey,
    required this.onTap,
    required this.opacity,
    required this.still,
  });

  @override
  Widget build(BuildContext context) {
    final shown = opacity > 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: shown ? 1 : 0),
      duration: shown && !still
          ? const Duration(milliseconds: 150)
          : Duration.zero,
      builder: (context, close, _) => Stack(
        alignment: Alignment.center,
        children: [
          if (!still && close < 1)
            IgnorePointer(
              child: ExcludeSemantics(
                child: Transform.rotate(
                  angle: pi / 4,
                  child: Transform.scale(
                    scale: RoundIconButton.plusAsClose,
                    child: RoundIconButton(
                      icon: CupertinoIcons.add,
                      label: "",
                      onTap: () {},
                      opacity: opacity * (1 - close),
                    ),
                  ),
                ),
              ),
            ),
          IrmaCloseButton(
            key: closeKey,
            onTap: onTap,
            opacity: opacity * (still ? 1 : close),
          ),
        ],
      ),
    );
  }
}
