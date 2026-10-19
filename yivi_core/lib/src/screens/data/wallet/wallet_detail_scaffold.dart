import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/pull_to_dismiss_physics.dart";
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
/// finger and shrinks a little), and a floating Done button over a fade.
///
/// The content itself flies in as heroes and fades up with [WalletReveal].
class WalletDetailScaffold extends StatefulWidget {
  /// What is open, for [WalletTransition.openKey]: the items of the page
  /// below with this key stay put while the rest moves away.
  final String openKey;

  final WalletDetailBuilder builder;

  /// Key of the Done button, for tests.
  final Key doneKey;

  /// Shown left of the Done button, e.g. a compact title once the header has
  /// scrolled away. Gets the opacity the Done button has.
  final Widget Function(BuildContext context, double opacity)? barBuilder;

  const WalletDetailScaffold({
    super.key,
    required this.openKey,
    required this.builder,
    required this.doneKey,
    this.barBuilder,
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
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 700.0;

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
    _springBack.addListener(() {
      final t = Curves.easeOutBack.transform(_springBack.value);
      _pull.value = (_springFrom * (1 - t)).clamp(0, double.infinity);
    });
  }

  void _onPullReleased(double velocity) {
    // A downward flick has a negative scroll velocity.
    if (_pull.value > _dismissDistance || velocity < -_dismissVelocity) {
      // The heroes fly back from where the page was pulled to.
      _close();
    } else {
      _springFrom = _pull.value;
      _springBack.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _routeAnimation = animation?..addStatusListener(_onRouteStatus);
    }
    // Opened without a tap on the page below (e.g. from a notification):
    // still let that page know what is open. After this build: the page
    // below listens.
    if (WalletTransition.openKey.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) WalletTransition.openKey.value ??= widget.openKey;
      });
    }
  }

  @override
  void didUpdateWidget(WalletDetailScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openKey != widget.openKey) {
      WalletTransition.openKey.value = widget.openKey;
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    // Closing bounces into place (WalletTransition.closeCurve).
    WalletTransition.closing = status == AnimationStatus.reverse;
    if (status == AnimationStatus.dismissed) {
      WalletTransition.openKey.value = null;
    }
  }

  @override
  void dispose() {
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

  void _close() => Navigator.of(context).maybePop();

  /// 0 at rest, 1 at twice the dismiss distance.
  double get _pullProgress =>
      (_pull.value / (2 * _dismissDistance)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final animation = _routeAnimation ?? kAlwaysCompleteAnimation;
    final chrome = Listenable.merge([animation, _pull]);
    double chromeOpacity() =>
        const Interval(0.4, 1).transform(animation.value) * (1 - _pullProgress);

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
                      const Interval(0.6, 1).transform(animation.value) *
                      (1 - _pullProgress * 0.5),
                ),
              ),
            ),
          ),
          Positioned.fill(
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
          // Fades the content out under the floating Done button.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: padding.top + 72,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.6, 1),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.background,
                        palette.background.withValues(alpha: 0),
                      ],
                      stops: const [0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: padding.top + 16,
            left: 16,
            right: 16,
            // Faded by the glass itself: a FadeTransition would darken its
            // blur until the fade ends (see GlassSurface.opacity).
            child: AnimatedBuilder(
              animation: chrome,
              builder: (context, _) => Row(
                children: [
                  Expanded(
                    child:
                        widget.barBuilder?.call(context, chromeOpacity()) ??
                        const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  GlassPillButton(
                    buttonKey: widget.doneKey,
                    label: FlutterI18n.translate(context, "wallet.detail.done"),
                    onTap: _close,
                    opacity: chromeOpacity(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades its child in and moves it up from below as the route opens.
class WalletReveal extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const WalletReveal({super.key, required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final opening = animation.status != AnimationStatus.reverse;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = opening
            ? const Interval(
                0.25,
                1,
                curve: WalletTransition.curve,
              ).transform(animation.value)
            : const Interval(0.5, 1).transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, reduceMotion ? 0 : (1 - t) * 56),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
