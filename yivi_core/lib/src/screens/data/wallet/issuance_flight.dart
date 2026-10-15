import "package:collection/collection.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/pane_selection_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../home/home_screen.dart";
import "../../home/widgets/irma_nav_bar.dart";
import "wallet_transition.dart";

/// Where the incoming card is while it flies from the issuance success
/// screen into the data tab.
class IssuanceFlightState {
  /// The wallet instance that was just added.
  final String hash;

  /// The card is in the list (still hidden); before this the other cards
  /// have not made room for it yet.
  final bool inserted;

  const IssuanceFlightState({required this.hash, this.inserted = false});
}

/// The fly-in after an issuance: on "Done" the session closes at once, a
/// curtain in the page colour hides the switch to the data tab, and a copy
/// of the received card flies from the success screen into the first slot,
/// while the other cards slide down to make room.
///
/// Like [WalletTransition], the data tab and the overlay share state through
/// static notifiers: the overlay outlives the session route.
class IssuanceFlight {
  IssuanceFlight._();

  static const flight = Duration(milliseconds: 760);
  static const curtain = Duration(milliseconds: 460);
  static const insertAt = Duration(milliseconds: 420);

  static const stackEnd = Duration(milliseconds: 1120);
  static const end = Duration(milliseconds: 840);
  static const curve = Cubic(0.3, 0.9, 0.25, 1);

  static final state = ValueNotifier<IssuanceFlightState?>(null);

  /// The first card slot of the data tab, registered by [IssuanceFlightTarget].
  static BuildContext? _target;

  static OverlayEntry? _entry;

  /// Starts the flight from the card at [source] and switches home to the
  /// data tab. Returns false without doing anything when it cannot fly: no
  /// source card, or the new card is not the first of the wallet (e.g. an
  /// instance that was replaced in place). The caller then closes the
  /// session as usual.
  ///
  /// With reduce motion on only the curtain fades.
  static bool start(
    BuildContext context, {
    required schemaless.Credential received,
    required GlobalKey source,
  }) {
    final box = source.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _entry != null) return false;

    final container = ProviderScope.containerOf(context, listen: false);
    final cards =
        container.read(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final card = cards.firstOrNull;
    if (card == null || card.credentialId != received.credentialId) {
      return false;
    }

    final HomeTabState tabs;
    try {
      tabs = context.read<HomeTabState>();
    } on ProviderNotFoundException {
      return false;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final from =
        box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
    final stack =
        (container.read(walletViewProvider) ?? WalletView.stack) ==
        WalletView.stack;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // With other cards, the new one joins the list a little later, so they
    // visibly slide down to make room.
    state.value = IssuanceFlightState(
      hash: card.hash,
      inserted: reduceMotion || cards.length == 1,
    );
    tabs.add(IrmaNavBarTab.data);

    _entry = OverlayEntry(
      builder: (_) => _FlightOverlay(
        card: card,
        from: from,
        stack: stack && cards.length > 1,
        reduceMotion: reduceMotion,
        onDone: () => _finish(container, card.hash),
      ),
    );
    overlay.insert(_entry!);
    return true;
  }

  static void _finish(ProviderContainer container, String hash) {
    _entry?.remove();
    _entry = null;
    state.value = null;
    // On a tablet the new card opens in the detail pane.
    final target = _target;
    if (target != null && target.mounted && isExpandedLayout(target)) {
      container.read(selectedCardProvider.notifier).select(hash);
    }
  }

  /// The first slot's rect in [overlayBox]'s coordinates, scrolling the data
  /// tab to the top the first time it is found.
  static Rect? _targetRect(RenderBox overlayBox, {required bool scroll}) {
    final target = _target;
    if (target == null || !target.mounted) return null;
    if (scroll) {
      final position = Scrollable.maybeOf(target)?.position;
      if (position != null && position.pixels != position.minScrollExtent) {
        position.jumpTo(position.minScrollExtent);
      }
    }
    final box = target.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
  }

  /// Ends a flight at once, e.g. between tests.
  @visibleForTesting
  static void reset() {
    _entry?.remove();
    _entry = null;
    _target = null;
    state.value = null;
  }
}

/// Marks the first card slot of the data tab as where the flight lands.
class IssuanceFlightTarget extends StatefulWidget {
  final Widget child;

  const IssuanceFlightTarget({super.key, required this.child});

  @override
  State<IssuanceFlightTarget> createState() => _IssuanceFlightTargetState();
}

class _IssuanceFlightTargetState extends State<IssuanceFlightTarget> {
  @override
  Widget build(BuildContext context) {
    IssuanceFlight._target = context;
    return widget.child;
  }

  @override
  void dispose() {
    if (IssuanceFlight._target == context) IssuanceFlight._target = null;
    super.dispose();
  }
}

/// Hides the incoming card in the data tab while its copy is flying.
class IssuanceFlightHidden extends StatelessWidget {
  final String hash;
  final Widget child;

  const IssuanceFlightHidden({
    super.key,
    required this.hash,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IssuanceFlightState?>(
      valueListenable: IssuanceFlight.state,
      child: child,
      builder: (context, flight, child) => flight?.hash == hash
          ? Opacity(opacity: 0, child: ExcludeSemantics(child: child))
          : child!,
    );
  }
}

/// Leaves the incoming card out of [cards] until it may join the list.
List<schemaless.Credential> withoutIncomingCard(
  List<schemaless.Credential> cards,
  IssuanceFlightState? flight,
) => flight == null || flight.inserted
    ? cards
    : cards.where((c) => c.hash != flight.hash).toList();

class _FlightOverlay extends StatefulWidget {
  final schemaless.Credential card;
  final Rect from;
  final bool stack;
  final bool reduceMotion;
  final VoidCallback onDone;

  const _FlightOverlay({
    required this.card,
    required this.from,
    required this.stack,
    required this.reduceMotion,
    required this.onDone,
  });

  @override
  State<_FlightOverlay> createState() => _FlightOverlayState();
}

class _FlightOverlayState extends State<_FlightOverlay>
    with SingleTickerProviderStateMixin {
  late final Duration _total = widget.reduceMotion
      ? IssuanceFlight.curtain
      : widget.stack
      ? IssuanceFlight.stackEnd
      : IssuanceFlight.end;

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _total,
  );

  Rect? _to;

  @override
  void initState() {
    super.initState();
    _clock.addListener(_tick);
    _clock.forward().whenComplete(widget.onDone);
  }

  Duration get _elapsed => _total * _clock.value;

  void _tick() {
    final flight = IssuanceFlight.state.value;
    if (flight != null &&
        !flight.inserted &&
        _elapsed >= IssuanceFlight.insertAt) {
      IssuanceFlight.state.value = IssuanceFlightState(
        hash: flight.hash,
        inserted: true,
      );
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  double _progress(Duration of, {Duration start = Duration.zero}) =>
      ((_elapsed - start).inMicroseconds / of.inMicroseconds).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final overlayBox = context.findRenderObject() as RenderBox?;
          if (overlayBox != null && overlayBox.hasSize) {
            // The slot moves while the list settles, so follow it.
            _to =
                IssuanceFlight._targetRect(overlayBox, scroll: _to == null) ??
                _to;
          }
          final t = IssuanceFlight.curve.transform(
            _progress(IssuanceFlight.flight),
          );
          final rect = Rect.lerp(widget.from, _to ?? widget.from, t)!;

          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: palette.background.withValues(
                    alpha: 1 - _progress(IssuanceFlight.curtain),
                  ),
                ),
              ),
              if (!widget.reduceMotion)
                Positioned(
                  key: const Key("issuance_flight_card"),
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  // Slides under the card below its place in the stack (the
                  // first card, until it joins the list), so it tucks in
                  // as it lands instead of jumping under at the end.
                  child: CoveredByStack(
                    hash: widget.card.hash,
                    incoming: true,
                    repaint: _clock,
                    child: Transform.rotate(
                      angle: -0.035 * (1 - t),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CredentialCardArt(
                            credential: widget.card,
                            width: rect.width,
                          ),
                          Positioned(
                            right: -12,
                            top: -16,
                            child: Opacity(
                              opacity: 1 - t,
                              child: _CheckBadge(border: palette.background),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The green check on the received card.
class _CheckBadge extends StatelessWidget {
  final Color border;

  const _CheckBadge({required this.border});

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFF00973A),
      shape: BoxShape.circle,
      border: Border.all(color: border, width: 4),
    ),
    child: const Icon(Icons.check, color: Colors.white, size: 30),
  );
}
