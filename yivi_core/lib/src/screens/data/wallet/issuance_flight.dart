import "package:collection/collection.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../providers/pane_selection_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/laid_out_box.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../home/home_screen.dart";
import "../../home/widgets/home_tab.dart";
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
/// curtain in the page colour hides the switch to the data tab, and the
/// received card is carried from the success screen into the first slot
/// (a [YiviFlight], as a card lands on the share screen: picked up as it
/// lies, turned a little, carried and put down, 950 ms), while the other
/// cards slide down to make room from the moment it is picked up.
///
/// Like [WalletTransition], the data tab and the overlay share state through
/// static notifiers: the overlay outlives the session route.
class IssuanceFlight {
  IssuanceFlight._();

  /// When the other cards start making room: as the card is picked up.
  static const insertAt = Duration(milliseconds: 190);

  /// The flight.
  static const duration = Duration(milliseconds: 950);

  /// How long the curtain takes to fade out.
  static const curtainFade = Duration(milliseconds: 460);

  /// How the other cards slide down to make room.
  static const curve = YiviMotion.ease;

  static final state = ValueNotifier<IssuanceFlightState?>(null);

  /// The first card slot of the data tab, registered by [IssuanceFlightTarget].
  static BuildContext? _target;

  /// Starts the flight from the card at [source] and switches home to the
  /// data tab. Returns false without doing anything when it cannot fly: no
  /// source card, or the new card is not the first of the wallet (e.g. an
  /// instance that was replaced in place). The caller then closes the
  /// session as usual.
  ///
  /// With reduce motion on nothing flies (false): the session closes as
  /// usual.
  ///
  /// Without [curtain] the card only flies: for a start from the Add data
  /// sheet, which closes over the data tab that is already on screen.
  static bool start(
    BuildContext context, {
    required schemaless.Credential received,
    required GlobalKey source,
    bool curtain = true,
  }) {
    final box = source.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || state.value != null) return false;

    final container = ProviderScope.containerOf(context, listen: false);
    final cards = container.read(walletCardsProvider);
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

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return false;

    // With other cards, the new one joins the list a little later, so they
    // visibly slide down to make room.
    state.value = IssuanceFlightState(
      hash: card.hash,
      inserted: cards.length == 1,
    );
    tabs.add(HomeTab.data);

    final palette = YiviPalette.of(context);
    var first = true;
    return YiviFlight.start(
      context,
      from: source,
      to: (overlay) {
        final rect = _targetRect(overlay, scroll: first);
        if (rect != null) first = false;
        return rect;
      },
      keys: FlightKey.carry(lift: 0.2, hold: 0.8, startTurn: -0.035),
      duration: duration,
      lift: YiviFlight.liftCarried,
      shadow: YiviFlight.shadowCarried,
      copyKey: const Key("issuance_flight_card"),
      copy: (context, frame) =>
          CredentialCardArt(credential: card, width: frame.size.width),
      // Slides under the card below its place in the stack (the first card,
      // until it joins the list), so it tucks in as it lands instead of
      // jumping under at the end.
      wrap: (child, clock) => CoveredByStack(
        hash: card.hash,
        incoming: true,
        repaint: clock,
        child: child,
      ),
      backdrop: curtain
          ? (elapsed) => ColoredBox(
              color: palette.background.withValues(
                alpha:
                    1 -
                    (elapsed.inMicroseconds / curtainFade.inMicroseconds).clamp(
                      0.0,
                      1.0,
                    ),
              ),
            )
          : null,
      onTick: (elapsed) {
        final flight = state.value;
        if (flight != null && !flight.inserted && elapsed >= insertAt) {
          state.value = IssuanceFlightState(hash: flight.hash, inserted: true);
        }
      },
      // The card in the list shows as the copy lands; the copy goes two
      // frames later.
      onLanded: () => _finish(container, card.hash),
    );
  }

  /// Flies whichever of the [received] cards (drawn at [sources], one key
  /// per card) now leads the data tab, if any; see [start].
  static bool startFirstOf(
    BuildContext context, {
    required List<schemaless.Credential> received,
    required List<GlobalKey> sources,
    bool curtain = true,
  }) {
    final wallet = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(walletCardsProvider);
    final first = wallet.firstOrNull;
    final i = first == null
        ? 0
        : received.indexWhere((c) => c.credentialId == first.credentialId);
    if (i < 0 || i >= received.length || i >= sources.length) return false;
    return start(
      context,
      received: received[i],
      source: sources[i],
      curtain: curtain,
    );
  }

  static void _finish(ProviderContainer container, String hash) {
    state.value = null;
    // With a detail pane (tablet, landscape) the new card opens in it.
    final target = _target;
    if (target != null && target.mounted && useHomePanes(target)) {
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
    return target.rectIn(overlayBox);
  }

  /// Ends a flight at once, e.g. between tests.
  @visibleForTesting
  static void reset() {
    YiviFlight.reset();
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
