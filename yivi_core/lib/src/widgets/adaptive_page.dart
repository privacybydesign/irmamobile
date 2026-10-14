import "package:material_ui/material_ui.dart";

import "../theme/yivi_palette.dart";
import "../util/adaptive_layout.dart";

/// How a screen is presented at tablet widths (from
/// [expandedLayoutBreakpoint]); on phones every screen fills the window.
enum PresentationMode {
  /// A 540 × 760 form sheet over the dimmed app (settings, help, add data,
  /// documents, e-mail and phone, errors). A sheet opened from a sheet steps
  /// in inside the same frame.
  sheet,

  /// A centred column on the plain background (enrollment, the lock screen,
  /// full-screen system states).
  full,

  /// The whole window, for screens with their own tablet layout (sessions).
  window,
}

/// How a screen comes in on a phone.
enum PhoneTransition {
  /// The platform's push: a slide from the right with a parallax on iOS
  /// (and the back swipe), the predictive back transition on Android.
  push,

  /// Slides up from the bottom, for flows that run on their own: issuance,
  /// disclosure, e-mail and phone, documents. The next step of such a flow
  /// is pushed.
  rise,

  /// Cross-fades, for the lock screen.
  fade,
}

const _ease = Cubic(0.2, 0.8, 0.2, 1);

/// A go_router page that presents its [child] by [mode] on tablets and with
/// [phoneTransition] on phones. With "Reduce motion" on, every transition is
/// a cross-fade.
class AdaptivePage<T> extends Page<T> {
  final Widget child;
  final PresentationMode mode;
  final PhoneTransition phoneTransition;

  const AdaptivePage({
    required this.child,
    this.mode = PresentationMode.sheet,
    this.phoneTransition = PhoneTransition.push,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) => _AdaptiveRoute<T>(this);
}

class _AdaptiveRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _AdaptiveRoute(AdaptivePage<T> page) : super(settings: page);

  AdaptivePage<T> get _page => settings as AdaptivePage<T>;

  bool get _expanded =>
      navigator != null && isExpandedLayout(navigator!.context);

  bool get _sheet => _page.mode == PresentationMode.sheet && _expanded;

  // A sheet directly over another sheet steps in inside the same frame,
  // without a second dim.
  bool get _stacked =>
      _sheet &&
      _previous is _AdaptiveRoute &&
      (_previous as _AdaptiveRoute)._sheet;
  Route<dynamic>? _previous;

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    _previous = previousRoute;
    super.didChangePrevious(previousRoute);
  }

  /// [PhoneTransition.rise] for the first screen of a flow, a push for the
  /// steps after it.
  PhoneTransition get _phone =>
      _page.phoneTransition == PhoneTransition.rise &&
          _previous is _AdaptiveRoute &&
          (_previous as _AdaptiveRoute)._page.phoneTransition ==
              PhoneTransition.rise
      ? PhoneTransition.push
      : _page.phoneTransition;

  bool get _platformPush => !_expanded && _phone == PhoneTransition.push;

  @override
  bool get opaque => _page.mode != PresentationMode.sheet;

  @override
  bool get maintainState => true;

  // Keeps the screen below still while a sheet or a rising flow comes in.
  @override
  bool get fullscreenDialog => !_platformPush;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _platformPush ? super.delegatedTransition : null;

  @override
  Duration get transitionDuration => _platformPush
      ? super.transitionDuration
      : _sheet
      ? const Duration(milliseconds: 260)
      : _phone == PhoneTransition.rise && !_expanded
      ? const Duration(milliseconds: 420)
      : const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => _platformPush
      ? super.reverseTransitionDuration
      : const Duration(milliseconds: 240);

  @override
  Widget buildContent(BuildContext context) {
    final child = _page.child;
    if (!isExpandedLayout(context) || _page.mode == PresentationMode.window) {
      return child;
    }
    final palette = YiviPalette.of(context);

    if (_page.mode == PresentationMode.full) {
      final size = MediaQuery.sizeOf(context);
      return ColoredBox(
        color: palette.background,
        child: Center(
          child: SizedBox(
            width: fullColumnWidth,
            // The screen inside lays out for the column, not the window.
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(size: Size(fullColumnWidth, size.height)),
              child: child,
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final width = sheetSize.width.clamp(0.0, size.width - 48);
    final height = sheetSize.height.clamp(0.0, size.height - 60);
    return Stack(
      children: [
        if (!_stacked)
          Positioned.fill(
            child: Semantics(
              label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
              button: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        Center(
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(Radius.circular(38)),
                ),
                shadows: _stacked
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x4D000000),
                          blurRadius: 80,
                          offset: Offset(0, 30),
                        ),
                      ],
              ),
              child: ClipRSuperellipse(
                borderRadius: const BorderRadius.all(Radius.circular(38)),
                // The screen inside thinks it has the whole window: give it
                // the sheet's size and no system insets.
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(width, height),
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: _ease,
      reverseCurve: Curves.easeIn,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    if (isExpandedLayout(context)) {
      if (_page.mode != PresentationMode.sheet) {
        return FadeTransition(opacity: curved, child: child);
      }
      if (_stacked) {
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      }
      // The dim fades in on its own; the sheet rises and settles.
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: animation,
                child: const ColoredBox(color: Color(0x61000000)),
              ),
            ),
          ),
          FadeTransition(
            opacity: curved,
            child: AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, 48 * (1 - curved.value)),
                child: Transform.scale(
                  scale: 0.97 + 0.03 * curved.value,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return switch (_phone) {
      PhoneTransition.push => super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      ),
      PhoneTransition.rise => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
      PhoneTransition.fade => FadeTransition(opacity: curved, child: child),
    };
  }

  @override
  String get debugLabel => "${super.debugLabel}(${_page.name})";

  /// Size of a form sheet on a tablet.
  static const sheetSize = Size(540, 760);

  /// Width of the centred column of a full-screen state on a tablet.
  static const fullColumnWidth = 560.0;
}
