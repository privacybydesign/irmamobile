import "dart:math" as math;

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_motion.dart";
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
import "requestor_card.dart";
import "session_columns.dart";
import "session_scaffold.dart";
import "shared_card_tile.dart";

/// "Shared with {requestor}" (or "Signed for {requestor}"), after the share
/// button: the shared cards handed to the requestor's logo, which ends with
/// the green check ([_Handover]; a signed message instead as a sheet of
/// paper, the cards as a small stack on its corner); the title; one sentence (what
/// was shared, where it goes on, that it is in Activity); and what to do
/// now: on iOS on the same phone a box that says to tap ◀ at the top left,
/// else a button (back to the website, or Done).
///
/// Coming from the share screen the cards, the requestor's logo (and the
/// message) fly in from where they were there ([DoneFlight]); the words
/// fade up after them; then the cards are handed over and the check pops on
/// last.
class DisclosureFeedbackScreen extends ConsumerStatefulWidget {
  /// Who asked: their name in the words, their logo that takes the cards.
  final schemaless.TrustedParty requestor;
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
    required this.requestor,
    required this.onDismiss,
    this.isSignatureSession = false,
    this.message,
    this.shared = const [],
    this.onOtherDevice = false,
    this.returnHost,
    this.onReturn,
    this.goBackYourself = false,
    this.onBackToWebsite,
  });

  @override
  ConsumerState<DisclosureFeedbackScreen> createState() =>
      DisclosureFeedbackScreenState();
}

class DisclosureFeedbackScreenState
    extends ConsumerState<DisclosureFeedbackScreen>
    with WidgetsBindingObserver {
  /// The signed message; none for a disclosure (whose session has an
  /// empty one).
  String? get _message {
    final message = widget.message;
    return widget.isSignatureSession && message != null && message.isNotEmpty
        ? message
        : null;
  }

  /// Per card of the pile (or the stack on the paper): its unturned box,
  /// where a card flies to.
  late final _cardKeys = List.generate(
    widget.shared.length,
    (i) => GlobalKey(debugLabel: "done_card_$i"),
  );
  final _paperKey = GlobalKey(debugLabel: "done_paper");
  final _logoKey = GlobalKey(debugLabel: "done_logo");

  /// The cards flew in: the words come up after them, and the check pops on.
  late final bool _arriving = DoneFlight.pending;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    if (_arriving) {
      // The places are hidden from the first frame; the flight shows them
      // as each card lands.
      YiviFlight.hide([..._cardKeys, _paperKey, _logoKey]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _land());
    }
  }

  void _land() {
    if (!mounted) {
      DoneFlight.reset();
      YiviFlight.show([..._cardKeys, _paperKey, _logoKey]);
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
      paper: _message == null ? null : _paperKey,
      paperCopy: _message == null
          ? null
          : SignedMessage(
              message: _message!,
              clamp: SignedMessage.paperClamp,
              padding: _paperPadding,
            ),
      // The logo takes the cards; on a signed message there is none.
      logo: _message == null ? _logoKey : null,
      logoCopy: requestorAvatar(widget.requestor, size: _Handover.logo),
    );
    // What does not fly (not captured) just shows.
    YiviFlight.show([
      for (final k in [..._cardKeys, _paperKey, _logoKey])
        if (!flying.contains(k)) k,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// All the shared cards, as pictures.
  List<schemaless.Credential> _cards() {
    final wallet = ref.read(walletCardsProvider);
    return [for (final i in widget.shared) sharedCardFor(i, wallet)];
  }

  /// The turn of the pile's card [i], in radians (see [pilePlace]).
  double _turnOf(int i) =>
      pilePlace(
        _message != null ? _Paper._seal : _Handover._places,
        i,
        widget.shared.length,
      ).turn *
      3.14159265 /
      180;

  static const _paperPadding = EdgeInsets.fromLTRB(44, 26, 44, 34);

  /// When the cards start going to the logo: once the last of [count] has
  /// flown in from the share screen ([DoneFlight.land]: 560 ms each, the
  /// first after 60 ms, 70 ms apart) and has lain there a moment; else a
  /// moment after the screen is there.
  Duration _handOverAt(int count) => Duration(
    milliseconds: _arriving && count > 0
        ? 60 + (count - 1) * 70 + 560 + 250
        : 400,
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final shared = widget.shared;
    ref.watch(walletCardsProvider);
    final cards = _cards();
    final requestor = widget.requestor.name;
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

    final hero = _message != null
        ? _Paper(
            message: _message!,
            paperKey: _paperKey,
            cards: cards,
            cardKeys: _cardKeys,
            padding: _paperPadding,
            arriving: _arriving,
            onReadAll: () => showSignedMessageSheet(
              context: context,
              message: _message!,
              lead: context.tr("share.message_sheet.lead_done", {
                "requestor": requestor,
              }),
              from: _paperKey,
            ),
          )
        : _Handover(
            requestor: widget.requestor,
            cards: cards,
            cardKeys: _cardKeys,
            logoKey: _logoKey,
            start: _handOverAt(cards.length),
          );

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
              SizedBox(height: _message != null ? 12 : 28),
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

/// Where card [i] of [count] goes in a pile drawn for three ([three]: the
/// front card, the second, the third, each as right, down and turn in
/// degrees). Up to three, as drawn. More fit in the same room: from the
/// front card to where the third is, evenly, turned from the second's turn
/// to the third's; the front card keeps its own.
({double dx, double dy, double turn}) pilePlace(
  List<(double, double, double)> three,
  int i,
  int count,
) {
  if (count <= 3) {
    final (dx, dy, turn) = three[i];
    return (dx: dx, dy: dy, turn: turn);
  }
  final (lastX, lastY, lastTurn) = three[2];
  final f = i / (count - 1);
  final turn = i == 0
      ? three[0].$3
      : three[1].$3 + (lastTurn - three[1].$3) * (i - 1) / (count - 2);
  return (dx: lastX * f, dy: lastY * f, turn: turn);
}

/// The shared cards handed to who asked: the cards as a pile (300 × 200:
/// pictures 260 wide, the first on top turned −3°, the next 12 right and 10
/// up turned 2°, the third 22 right and 18 up turned 6°; more share that
/// room, see [pilePlace]) under the requestor's logo (112). Once the cards
/// are in place ([start], after they have flown in), each in turn, the front
/// one first, is lifted, rises into the logo while it tilts away and shrinks,
/// and is gone; the logo takes each in with a small swell. Then the logo
/// settles in the middle where the pile was, a ring goes out from it, the
/// green check pops on, and the cards come back small on the logo's bottom
/// left corner (up to three, the back one first). With reduce motion: the
/// logo with the check and the small cards.
class _Handover extends StatefulWidget {
  final schemaless.TrustedParty requestor;
  final List<schemaless.Credential> cards;
  final List<GlobalKey> cardKeys;

  /// Where the logo is while it is up, for its flight in ([DoneFlight]).
  final GlobalKey logoKey;

  /// How long to wait before the first card goes: until the cards have
  /// landed in the pile.
  final Duration start;

  const _Handover({
    required this.requestor,
    required this.cards,
    required this.cardKeys,
    required this.logoKey,
    required this.start,
  });

  static const double width = 300;
  static const double height = 340;
  static const double logo = 112;

  /// The pile's top, under the logo.
  static const double _pileTop = 140;

  static const _places = [
    (0.0, 0.0, -3.0),
    (12.0, -10.0, 2.0),
    (22.0, -18.0, 6.0),
  ];

  /// One card going: lifted, carried up into the logo, gone.
  static const _cardGoes = 1050;

  /// After the last card is in: the logo settles, the ring, the check, the
  /// small cards.
  static const _settles = 520;
  static const _ring = 650;
  static const _check = 360;
  static const _miniAt = 420;
  static const _miniGap = 80;
  static const _mini = 420;

  /// The small cards on the logo's corner, the front one first: right,
  /// down, and turn in degrees.
  static const _minis = [
    (0.0, 0.0, -8.0),
    (6.0, -6.0, -1.0),
    (11.0, -11.0, 6.0),
  ];

  @override
  State<_Handover> createState() => _HandoverState();
}

class _HandoverState extends State<_Handover>
    with SingleTickerProviderStateMixin {
  late final int _count = widget.cards.length;

  /// Between two cards going, so that many still go within about a second.
  late final int _gap = _count < 2 ? 0 : math.min(260, 900 ~/ (_count - 1));

  late final int _start = widget.start.inMilliseconds;

  /// When the last card is in the logo.
  late final int _lastIn =
      _start + (_count == 0 ? 0 : (_count - 1) * _gap + _Handover._cardGoes);

  /// How many come back small.
  late final int _small = math.min(_count, 3);

  late final int _total =
      _lastIn +
      [
        _Handover._settles,
        300 + _Handover._ring,
        _Handover._miniAt +
            (_small - 1).clamp(0, 2) * _Handover._miniGap +
            _Handover._mini,
      ].reduce(math.max);

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _total),
  );

  @override
  void initState() {
    super.initState();
    _clock.forward();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// How far [ms] is through the beat from [from] lasting [length], 0..1.
  static double _through(double ms, num from, num length) =>
      length <= 0 ? 1 : ((ms - from) / length).clamp(0.0, 1.0);

  static const _carry = Cubic(0.65, 0, 0.35, 1);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      key: const Key("share_done_handover"),
      width: _Handover.width,
      height: _Handover.height,
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) {
          final ms = still ? _total.toDouble() : _clock.value * _total;
          const logo = _Handover.logo;
          const logoLeft = (_Handover.width - logo) / 2;
          // The logo's centre while it is up; where it settles.
          const up = Offset(_Handover.width / 2, logo / 2);
          const settled = (_Handover.height - logo) / 2;
          // Nothing shared: it is there from the start.
          final down = _count == 0
              ? 1.0
              : _carry.transform(_through(ms, _lastIn, _Handover._settles));
          // A small swell as each card goes in.
          var swell = 0.0;
          for (var i = 0; i < _count; i++) {
            final t = _through(ms, _arrives(i), 300);
            swell = math.max(swell, math.sin(t * math.pi));
          }
          final ring = _through(ms, _lastIn + 300, _Handover._ring);
          final check = _through(ms, _lastIn + 320, _Handover._check);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Back to front, so the front card is on top.
              for (var i = _count - 1; i >= 0; i--) ?_card(i, ms, up),
              Positioned(
                left: logoLeft,
                top: settled * down,
                width: logo,
                height: logo,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (ring > 0 && ring < 1)
                      Positioned.fill(
                        child: Transform.scale(
                          scale: 1 + 0.5 * Curves.easeOut.transform(ring),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: YiviPalette.successMark.withValues(
                                  alpha: 0.5 * (1 - ring),
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    FlightSpot(
                      flightKey: widget.logoKey,
                      child: Transform.scale(
                        scale: 1 + 0.07 * swell,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x29102846),
                                blurRadius: 30,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ExcludeSemantics(
                            child: requestorAvatar(
                              widget.requestor,
                              size: logo,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_small > 0)
                      Positioned(
                        key: const Key("share_done_minis"),
                        left: -30,
                        bottom: -12,
                        width: 70,
                        height: 46,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Back to front.
                            for (var i = _small - 1; i >= 0; i--) ?_mini(i, ms),
                          ],
                        ),
                      ),
                    if (check > 0)
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: Transform.scale(
                          scale: _pop(check),
                          child: const ReceivedCheck(
                            key: Key("share_done_check"),
                            size: 44,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// When card [i] is in the logo.
  double _arrives(int i) =>
      (_start + i * _gap + _Handover._cardGoes * 0.92).toDouble();

  /// Card [i] at [ms], or null once it is gone: in its place in the pile,
  /// then lifted, then carried up into the logo centred at [logo].
  Widget? _card(int i, double ms, Offset logo) {
    final t = _through(ms, _start + i * _gap, _Handover._cardGoes);
    if (t >= 1) return null;
    final place = pilePlace(_Handover._places, i, _count);
    final left = 20 + place.dx;
    final top = _Handover._pileTop + 22 + place.dy;
    // Lifted in the first fifth, carried up the rest of the way, gone at
    // the end.
    final lift = Curves.easeOut.transform((t / 0.2).clamp(0.0, 1.0));
    final go = _carry.transform(((t - 0.2) / 0.72).clamp(0.0, 1.0));
    final fade = 1 - ((t - 0.88) / 0.12).clamp(0.0, 1.0);
    const size = Size(260, 164);
    final centre = Offset(left + size.width / 2, top + size.height / 2);
    final to = logo - centre;
    final scale = (1 + 0.04 * lift) * (1 - 0.74 * go);
    final turn = place.turn * (1 - go) * math.pi / 180;
    final up = lift * (1 - go);
    return Positioned(
      left: left,
      top: top,
      width: size.width,
      height: size.height,
      child: Opacity(
        opacity: fade,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..translateByDouble(to.dx * go, -14 * lift + to.dy * go, 0, 1)
            ..rotateX(22 * math.pi / 180 * go)
            ..scaleByDouble(scale, scale, 1, 1),
          // The spot is the unturned box, where a card flies in to.
          child: FlightSpot(
            flightKey: widget.cardKeys[i],
            child: Transform.rotate(
              angle: turn,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: YiviCorners.cardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        const Color(0x1F000000),
                        const Color(0x38102846),
                        up,
                      )!,
                      blurRadius: 18 + 20 * up,
                      offset: Offset(0, 6 + 14 * up),
                    ),
                  ],
                ),
                child: CredentialCardArt(
                  credential: widget.cards[i],
                  width: 260,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Small card [i] (0 the front one) at [ms]: out of the logo onto its
  /// corner, the back one first; null before it comes.
  Widget? _mini(int i, double ms) {
    final order = _small - 1 - i;
    final t = _through(
      ms,
      _lastIn + _Handover._miniAt + order * _Handover._miniGap,
      _Handover._mini,
    );
    if (t <= 0) return null;
    final e = YiviMotion.ease.transform(t);
    final (dx, dy, turn) = _Handover._minis[i];
    final palette = YiviPalette.of(context);
    return Positioned(
      left: 0,
      bottom: 0,
      width: 58,
      height: 37,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(34 + (dx - 34) * e, -30 + (dy + 30) * e),
          child: Transform.rotate(
            angle: turn * e * math.pi / 180,
            child: Transform.scale(
              scale: 0.3 + 0.7 * e,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: palette.background, width: 2),
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x2E102846),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: CredentialCardArt(
                      credential: widget.cards[i],
                      width: 58,
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

  /// The check's pop: past its size and back.
  static double _pop(double t) {
    final eased = Curves.easeOut.transform(t);
    return eased < 0.7 ? 1.1 * eased / 0.7 : 1.1 - 0.1 * (eased - 0.7) / 0.3;
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
                      left: pilePlace(_seal, i, cards.length).dx,
                      bottom: -pilePlace(_seal, i, cards.length).dy,
                      width: 96,
                      height: 61,
                      child: FlightSpot(
                        flightKey: cardKeys[i],
                        child: Transform.rotate(
                          angle:
                              pilePlace(_seal, i, cards.length).turn *
                              3.14159265 /
                              180,
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

/// What to do now on the done screen, on iOS without a link back: a small
/// status bar with ◀ lit, where they tap to go back, a head and a line. The bar shows no app name: they may have come from a browser,
/// mail or another app.
class _NextBox extends StatelessWidget {
  final String head;
  final String text;

  const _NextBox({required this.head, required this.text});

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
