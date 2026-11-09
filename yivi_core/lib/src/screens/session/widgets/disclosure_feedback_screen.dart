import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/received_check.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/signed_message.dart";
import "done_flight.dart";
import "session_columns.dart";
import "session_scaffold.dart";
import "shared_card_tile.dart";

/// "Shared with {requestor}" (or "Signed for {requestor}"), after the share
/// button: what was shared as a pile of the cards, tilted, with the green
/// check on its corner (a signed message instead as a sheet of paper, the
/// cards as a small stack on its corner); the title; one sentence (what
/// was shared, where it goes on, that it is in Activity); and what to do
/// now: on iOS on the same phone a box that says to tap ◀ at the top left,
/// else a button (back to the website, or Done).
///
/// Coming from the share screen the cards (and the message) fly in from
/// where they were there ([DoneFlight]); the words fade up after them and
/// the check pops on last.
class DisclosureFeedbackScreen extends ConsumerStatefulWidget {
  final String otherParty;
  final Function(BuildContext) onDismiss;
  final bool isSignatureSession;

  /// The message that was signed.
  final String? message;

  /// The cards (with only the shared attributes) the user just shared.
  final List<SelectableCredentialInstance> shared;

  /// The session continues on another device (the one that showed the QR
  /// code).
  final bool onOtherDevice;

  /// The same phone, with a link back: "Back to {host}" opens it
  /// ([onReturn]).
  final String? returnHost;
  final VoidCallback? onReturn;

  /// The same phone without a link back, on iOS: the user goes back
  /// themselves, with ◀ at the top left.
  final bool goBackYourself;

  /// The same phone without a link back, on Android: "Back to the website"
  /// puts Yivi in the background ([onBackToWebsite]).
  final VoidCallback? onBackToWebsite;

  const DisclosureFeedbackScreen({
    super.key,
    required this.otherParty,
    required this.onDismiss,
    bool? isSignatureSession,
    this.message,
    this.shared = const [],
    this.onOtherDevice = false,
    this.returnHost,
    this.onReturn,
    this.goBackYourself = false,
    this.onBackToWebsite,
  }) : isSignatureSession = isSignatureSession ?? false;

  @override
  ConsumerState<DisclosureFeedbackScreen> createState() =>
      DisclosureFeedbackScreenState();
}

class DisclosureFeedbackScreenState
    extends ConsumerState<DisclosureFeedbackScreen>
    with WidgetsBindingObserver {
  /// Per card of the pile (or the stack on the paper): its unturned box,
  /// where a card flies to.
  final _cardKeys = List.generate(
    3,
    (i) => GlobalKey(debugLabel: "done_card_$i"),
  );
  final _paperKey = GlobalKey(debugLabel: "done_paper");

  /// The cards flew in: the words come up after them, and the check pops on.
  late final bool _arriving = DoneFlight.pending;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    if (_arriving) {
      // The places are hidden from the first frame; the flight shows them
      // as each card lands.
      YiviFlight.hide([..._cardKeys, _paperKey]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _land());
    }
  }

  void _land() {
    if (!mounted) {
      DoneFlight.reset();
      YiviFlight.show([..._cardKeys, _paperKey]);
      return;
    }
    final cards = _cards();
    final flying = DoneFlight.land(
      context,
      cards: [
        for (final (i, c) in cards.indexed)
          (
            key: _cardKeys[i],
            hash: c.hash,
            z: cards.length - i,
            turn: _turnOf(i),
            picture: CredentialCardArt(credential: c, width: 260),
          ),
      ],
      paper: widget.message == null ? null : _paperKey,
      paperCopy: widget.message == null
          ? null
          : SignedMessage(
              message: widget.message!,
              clamp: SignedMessage.paperClamp,
              padding: _paperPadding,
            ),
    );
    // What does not fly (not captured) just shows.
    YiviFlight.show([
      for (final k in [..._cardKeys, _paperKey])
        if (!flying.contains(k)) k,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Up to three of the shared cards, as pictures.
  List<schemaless.Credential> _cards() {
    final wallet = ref.read(walletCardsProvider);
    return [for (final i in widget.shared.take(3)) sharedCardFor(i, wallet)];
  }

  /// The turn of the pile's card [i], in radians: -3°, 2°, 6°; on the paper's
  /// stack -5°, 2°, 8°.
  double _turnOf(int i) =>
      (widget.message != null
          ? const [-5.0, 2.0, 8.0]
          : const [-3.0, 2.0, 6.0])[i] *
      3.14159265 /
      180;

  static const _paperPadding = EdgeInsets.fromLTRB(44, 26, 44, 34);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final shared = widget.shared;
    ref.watch(walletCardsProvider);
    final cards = _cards();
    final requestor = widget.otherParty;
    final sign = widget.isSignatureSession;
    final host = widget.returnHost;

    final title = shared.isEmpty && !sign
        ? context.tr("share.done.title_none")
        : context.tr(sign ? "share.done.title_signature" : "share.done.title", {
            "requestor": requestor,
          });
    final what = shared.length == 1
        ? shared.single.name
        : context.tr("share.done.cards", {"count": "${shared.length}"});
    final text = [
      if (shared.isEmpty && !sign)
        context.tr("share.done.text_none", {"requestor": requestor})
      else ...[
        sign
            ? context.tr("share.done.signed_with", {"what": what})
            : shared.length == 1
            ? context.tr("share.done.shared_one", {"name": what})
            : context.tr("share.done.shared_many", {
                "count": "${shared.length}",
              }),
        if (widget.onOtherDevice) context.tr("share.done.other_device"),
        context.tr("share.done.in_activity"),
      ],
    ].join(" ");
    final nextBox = widget.goBackYourself
        ? _NextBox(
            head: context.tr("share.done.next.back_head"),
            text: context.tr("share.done.next.back_text"),
            statusBar: true,
          )
        : null;
    final label = host != null
        ? context.tr("share.done.next.return_head", {"host": host})
        : widget.onBackToWebsite != null
        ? context.tr("share.done.back_website")
        : context.tr("share.done.button");
    void done() => host != null
        ? widget.onReturn?.call()
        : widget.onBackToWebsite != null
        ? widget.onBackToWebsite!()
        : widget.onDismiss(context);
    // On iOS on the same phone there is nothing to do but go back with ◀
    // (or close): no button.
    final button = widget.goBackYourself
        ? null
        : FancyPillButton(
            key: const Key("ok_button"),
            label: label,
            onPressed: done,
          );

    final hero = widget.message != null
        ? _Paper(
            message: widget.message!,
            paperKey: _paperKey,
            cards: cards,
            cardKeys: _cardKeys,
            padding: _paperPadding,
            arriving: _arriving,
            onReadAll: () => showSignedMessageSheet(
              context: context,
              message: widget.message!,
              lead: context.tr("share.message_sheet.lead_done", {
                "requestor": requestor,
              }),
              from: _paperKey,
            ),
          )
        : cards.isEmpty
        ? const SizedBox(height: 40)
        : _Pile(cards: cards, cardKeys: _cardKeys, arriving: _arriving);

    final sideways = useSheetColumns(context) || useSessionColumns(context);
    final words = <Widget>[
      Semantics(
        header: true,
        child: Text(
          title,
          key: const Key("share_done_title"),
          textAlign: sideways ? TextAlign.start : TextAlign.center,
          style: palette
              .display(27, weight: FontWeight.w600)
              .copyWith(height: 35 / 27, color: palette.text),
        ),
      ),
      SizedBox(height: sideways ? 12 : 16),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: sideways ? 0 : 24),
        child: Text(
          text,
          key: const Key("share_done_text"),
          textAlign: sideways ? TextAlign.start : TextAlign.center,
          style: palette
              .body(16)
              .copyWith(height: 24 / 16, color: palette.text),
        ),
      ),
      if (nextBox != null) ...[const SizedBox(height: 18), nextBox],
    ];
    Widget fading(List<Widget> children) => _FadeUp(
      on: _arriving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    // Held sideways, and on a tablet: the pile (or the paper) at the left,
    // staying put; the words at the right, scrolling; the button at the
    // bottom of the right column.
    if (sideways) {
      return PopScope(
        canPop: false,
        child: SessionScaffold(
          onDismiss: () => widget.onDismiss(context),
          wide: true,
          scrollsUnderBars: true,
          cornerClose: true,
          body: Builder(
            builder: (context) {
              final media = MediaQuery.paddingOf(context);
              return SidewaysLayout(
                panel: Padding(
                  padding: EdgeInsets.only(top: 48 + media.top),
                  child: Align(alignment: Alignment.topCenter, child: hero),
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key("share_done_scroll"),
                        padding: EdgeInsets.only(top: 48 + media.top),
                        child: fading(words),
                      ),
                    ),
                    if (button != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: 12,
                          bottom: 21 + media.bottom,
                        ),
                        child: button,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: SessionScaffold(
        onDismiss: () => widget.onDismiss(context),
        scrollsUnderBars: true,
        body: BarInsetsBuilder(
          builder: (context, insets) => ListView(
            padding: insets + const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Center(child: hero),
              SizedBox(height: widget.message != null ? 12 : 28),
              fading(words),
            ],
          ),
        ),
        bottomNavigationBar: button == null
            ? null
            : IrmaBottomBarBase(child: button),
      ),
    );
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // If the app is resumed remove the route with this screen from the stack.
    if (state == AppLifecycleState.resumed) {
      widget.onDismiss(context);
    }
  }
}

/// The words of the done screen coming up after the cards have flown in:
/// from 8 lower, fading in, 320 ms after 380 ms.
class _FadeUp extends StatelessWidget {
  final bool on;
  final Widget child;

  const _FadeUp({required this.on, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!on || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      child: child,
      builder: (context, t, child) {
        final local = Curves.easeOut.transform(
          ((t * 700 - 380) / 320).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: local,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - local)),
            child: child,
          ),
        );
      },
    );
  }
}

/// The green check popping on: from nothing past its size and back, 360 ms
/// after 600 ms (after the cards have landed).
class _CheckPop extends StatelessWidget {
  final bool on;
  final Widget child;

  const _CheckPop({required this.on, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!on || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 960),
      child: child,
      builder: (context, t, child) {
        final local = ((t * 960 - 600) / 360).clamp(0.0, 1.0);
        final eased = Curves.easeOut.transform(local);
        final scale = eased < 0.7
            ? 1.12 * eased / 0.7
            : 1.12 - 0.12 * (eased - 0.7) / 0.3;
        return Transform.scale(scale: scale, child: child);
      },
    );
  }
}

/// The shared cards as a pile, 300 × 200: up to three pictures 260 wide, the
/// first on top turned −3°, the next 12 right and 10 up turned 2°, the third
/// 22 right and 18 up turned 6°; the green check on the top right corner.
class _Pile extends StatelessWidget {
  final List<schemaless.Credential> cards;
  final List<GlobalKey> cardKeys;
  final bool arriving;

  const _Pile({
    required this.cards,
    required this.cardKeys,
    required this.arriving,
  });

  static const _places = [
    (0.0, 0.0, -3.0),
    (12.0, -10.0, 2.0),
    (22.0, -18.0, 6.0),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key("share_done_pile"),
      width: 300,
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final i in [for (var i = cards.length - 1; i >= 0; i--) i])
            Positioned(
              left: 20 + _places[i].$1,
              top: 22 + _places[i].$2,
              width: 260,
              height: 164,
              child: FlightSpot(
                flightKey: cardKeys[i],
                child: Transform.rotate(
                  angle: _places[i].$3 * 3.14159265 / 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: YiviCorners.cardRadius,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CredentialCardArt(credential: cards[i], width: 260),
                  ),
                ),
              ),
            ),
          Positioned(
            right: -2,
            top: 0,
            child: _CheckPop(
              on: arriving,
              child: const ReceivedCheck(key: Key("share_done_check")),
            ),
          ),
        ],
      ),
    );
  }
}

/// A signed message as a sheet of paper, turned −2°, the green check on its
/// top right corner and the cards it was signed with as a small fanned stack
/// on its bottom left corner, like a seal.
class _Paper extends StatelessWidget {
  final String message;
  final GlobalKey paperKey;
  final List<schemaless.Credential> cards;
  final List<GlobalKey> cardKeys;
  final EdgeInsets padding;
  final bool arriving;
  final VoidCallback onReadAll;

  const _Paper({
    required this.message,
    required this.paperKey,
    required this.cards,
    required this.cardKeys,
    required this.padding,
    required this.arriving,
    required this.onReadAll,
  });

  static const _seal = [
    (0.0, 0.0, -5.0),
    (14.0, -7.0, 2.0),
    (26.0, -13.0, 8.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 44),
      child: SizedBox(
        key: const Key("share_done_paper"),
        width: 310,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: FlightSpot(
                flightKey: paperKey,
                child: Transform.rotate(
                  angle: -2 * 3.14159265 / 180,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 132),
                    child: SignedMessage(
                      message: message,
                      clamp: SignedMessage.paperClamp,
                      padding: padding,
                      onReadAll: onReadAll,
                      shadow: const [
                        BoxShadow(
                          color: Color(0x24102846),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -12,
              top: -16,
              child: _CheckPop(
                on: arriving,
                child: const ReceivedCheck(key: Key("share_done_check")),
              ),
            ),
            Positioned(
              left: -10,
              bottom: 0,
              width: 120,
              height: 76,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final i in [
                    for (var i = cards.length - 1; i >= 0; i--) i,
                  ])
                    Positioned(
                      left: _seal[i].$1,
                      bottom: -_seal[i].$2,
                      width: 96,
                      height: 61,
                      child: FlightSpot(
                        flightKey: cardKeys[i],
                        child: Transform.rotate(
                          angle: _seal[i].$3 * 3.14159265 / 180,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2E000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: CredentialCardArt(
                                credential: cards[i],
                                width: 92,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What to do now, at the top of the done screen: a head and a line, and on
/// iOS without a link back a small status bar with ◀ lit, where they tap to
/// go back. The bar shows no app name: they may have come from a browser,
/// mail or another app.
class _NextBox extends StatelessWidget {
  final String head;
  final String text;
  final bool statusBar;

  const _NextBox({
    required this.head,
    required this.text,
    required this.statusBar,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: const Key("share_done_next"),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: ShapeDecoration(
        color: palette.infoSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          if (statusBar)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(7),
                          ),
                          side: BorderSide(color: palette.primary, width: 2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5,
                        children: [
                          Text(
                            "\u25C0",
                            style: palette
                                .body(12, weight: FontWeight.w700)
                                .copyWith(color: palette.link),
                          ),
                          Container(
                            width: 46,
                            height: 9,
                            decoration: ShapeDecoration(
                              color: palette.link.withValues(alpha: 0.35),
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "9:41",
                      style: palette
                          .body(12, weight: FontWeight.w600)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          Text(
            head,
            style: palette
                .display(19, weight: FontWeight.w700)
                .copyWith(height: 25 / 19, color: palette.text),
          ),
          Text(
            text,
            style: palette
                .body(15)
                .copyWith(height: 21 / 15, color: palette.heading),
          ),
        ],
      ),
    );
  }
}
