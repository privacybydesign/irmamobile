import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../util/after_frame.dart";

/// Lets a route open or close without its transition: when the layout
/// changes (the phone turned) rather than after a tap.
abstract final class RouteMotion {
  static bool _instant = false;

  /// Whether a route pushed or popped now skips its transition.
  static bool get instant => _instant;

  /// Runs [action] (a push or a pop) with transitions off. The router puts
  /// the change into the navigator in the next frame, so they stay off
  /// until after that frame.
  static void instantly(VoidCallback action) {
    _instant = true;
    try {
      action();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) => _instant = false);
      WidgetsBinding.instance.scheduleFrame();
    }
  }
}

/// For routes that can open and close without their transition
/// ([RouteMotion.instantly]).
mixin InstantRouteMixin<T> on TransitionRoute<T> {
  @override
  TickerFuture didPush() {
    if (RouteMotion.instant) controller?.duration = Duration.zero;
    return super.didPush();
  }

  @override
  bool didPop(T? result) {
    if (RouteMotion.instant) controller?.reverseDuration = Duration.zero;
    return super.didPop(result);
  }
}

/// A page of the home tabs pushed as a screen of its own (a card, an
/// activity entry, Instellingen), for when the layout can show it in a
/// detail pane instead (the phone turned sideways):
///
/// once [paneAvailable] and this is the top route, [onHandoff] picks what it
/// shows in the pane (and the tab), and the page closes without its
/// transition. Something on top of it (a sheet, a deeper page) is left
/// alone; the hand-off waits until that has closed.
class PaneHandoff extends StatefulWidget {
  final bool Function(BuildContext context) paneAvailable;
  final void Function(ProviderContainer container) onHandoff;
  final Widget child;

  const PaneHandoff({
    super.key,
    required this.paneAvailable,
    required this.onHandoff,
    required this.child,
  });

  @override
  State<PaneHandoff> createState() => _PaneHandoffState();
}

class _PaneHandoffState extends State<PaneHandoff> {
  bool _handedOff = false;
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
    // Depends on the route (whether it is the top one) and on the screen's
    // size, so this runs again when either changes.
    final route = ModalRoute.of(context);
    if (_handedOff ||
        route == null ||
        !route.isCurrent ||
        !widget.paneAvailable(context)) {
      return;
    }
    _handedOff = true;
    afterFrame(() {
      widget.onHandoff(_container!);
      final navigator = Navigator.of(context);
      RouteMotion.instantly(navigator.pop);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
