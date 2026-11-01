part of "data_tab.dart";

/// The cards overlap, each showing a strip of [_stripHeight]; the last one is
/// shown in full. Hold a card to drag it to another place.
class _StackView extends ConsumerWidget {
  static const double _stripHeight = 64;

  /// Between the card in the hand and the card below it.
  static const double _landingGap = 8;

  /// How far the card open in the detail pane slides out of the stack.
  static const double nudge = 16;

  /// How far it tilts to the right (clockwise), in radians: about 2°.
  static const double tilt = 0.035;

  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final double width;
  final bool arrangeable;

  /// The card open in the detail pane, if there is one.
  final String? openHash;

  const _StackView({
    required this.cards,
    required this.hintTexts,
    required this.width,
    required this.arrangeable,
    this.openHash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardHeight = width / CredentialCardArt.aspectRatio;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final onMove = _reorder(ref);
    // What a card transition measures when one of them is tapped.
    StackCards.hashes = [for (final c in cards) c.hash];
    return DragToArrange(
      keys: [for (final c in cards) c.hash],
      size: Size(width, (cards.length - 1) * _stripHeight + cardHeight),
      slotWidth: width,
      slot: (i) => Offset(0, i * _stripHeight),
      indexAt: (at) => (at.dy / _stripHeight).round(),
      // The cards below the one in the hand clear all of it (lifted), and a
      // little more, so it lands without dropping through them.
      room: Offset(
        0,
        cardHeight * DragToArrange.lift - _stripHeight + _landingGap,
      ),
      enabled: arrangeable,
      // The cards slide down when a received card joins the top.
      slide: _slideForFlight(),
      curve: IssuanceFlight.curve,
      onMove: onMove,
      builder: (context, i) {
        final c = cards[i];
        return PushAway(
          hash: c.hash,
          child: WalletStackSlot(
            hash: c.hash,
            index: i,
            child: _flightSlot(
              first: i == 0,
              hash: c.hash,
              child: _Nudge(
                key: Key("stack_nudge_${c.hash}"),
                open: c.hash == openHash,
                width: width,
                reduceMotion: reduceMotion,
                // Measured here, outside the card's press (it gives way
                // under the finger): the card's place at rest.
                child: RegisteredSlot(
                  registry: StackCards.slots,
                  id: i,
                  child: _CardButton(
                    credential: c,
                    hintText: hintTexts[c.hash],
                    pressDepth: 6,
                    moves: arrangeable
                        ? moveActions(
                            context,
                            index: i,
                            count: cards.length,
                            onMove: onMove,
                          )
                        : null,
                    // Under the next card only its strip shows.
                    revealHeight: i == cards.length - 1 ? null : _stripHeight,
                    // Sinks or falls while a card opens; the open card
                    // itself is drawn by its details.
                    child: StackCardFollow(
                      index: i,
                      width: width,
                      child: CredentialCardArt(
                        credential: c,
                        width: width,
                        hintText: hintTexts[c.hash],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// How fast cards slide to their places by themselves: when a flight
/// starts the cards close the gap at once, under the curtain; they slide
/// only to make room for the new card.
Duration _slideForFlight() {
  final flight = IssuanceFlight.state.value;
  return flight != null && !flight.inserted
      ? Duration.zero
      : const Duration(milliseconds: 400);
}

/// The card open in the detail pane slides [_StackView.nudge] to the right,
/// out of the stack toward its details, and tilts a little to the right
/// ([_StackView.tilt]), on a deeper shadow; it slides back when another
/// card opens.
class _Nudge extends StatelessWidget {
  final bool open;
  final double width;
  final bool reduceMotion;
  final Widget child;

  const _Nudge({
    super.key,
    required this.open,
    required this.width,
    required this.reduceMotion,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: open ? 1 : 0),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(t * _StackView.nudge, 0),
        child: Transform.rotate(
          angle: t * _StackView.tilt,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: CredentialCardArt.radiusFor(width),
              boxShadow: [
                if (t > 0)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.26 * t),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The card the detail pane shows: the [selected] one while it is among
/// [cards], otherwise the first.
String? _paneCardHash(String? selected, List<schemaless.Credential> cards) =>
    cards.any((c) => c.hash == selected) ? selected : cards.firstOrNull?.hash;

/// A row a card: its picture, name, hint and issuer. Hold a row to drag it
/// to another place.
class _ListView extends ConsumerWidget {
  static const double gap = 8;

  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final double width;
  final bool arrangeable;

  /// While searching: the query, and why each card matched (by hash).
  final String query;
  final Map<String, CardSearchResult> results;

  /// The card open in the detail pane, if there is one.
  final String? openHash;

  const _ListView({
    required this.cards,
    required this.hintTexts,
    required this.width,
    required this.arrangeable,
    this.query = "",
    this.results = const {},
    this.openHash,
  });

  /// The height of every row: its picture, or its three lines of text when
  /// they are taller (large text), and its padding. One height for all, so
  /// the rows have fixed places to be dragged between; a row without a hint
  /// has its text in the middle. With [matchLine] there is room for the
  /// line that says why a search found the card.
  static double rowHeight(BuildContext context, {bool matchLine = false}) {
    final palette = YiviPalette.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle style) => (TextPainter(
      text: TextSpan(text: "Ag", style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout()).height;
    final text =
        line(palette.display(16)) +
        line(palette.body(14)) +
        line(palette.body(12)) +
        (matchLine ? line(palette.body(13)) : 0);
    return 2 * _ListRow.padding +
        max(
          _ListRow.picture / CredentialCardArt.aspectRatio,
          text,
        ).ceilToDouble();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onMove = _reorder(ref);
    final row = rowHeight(
      context,
      matchLine: results.values.any(_ListRow.hasMatchLine),
    );
    return DragToArrange(
      keys: [for (final c in cards) c.hash],
      size: Size(width, cards.length * (row + gap) - gap),
      slotWidth: width,
      slotHeight: row,
      slot: (i) => Offset(0, i * (row + gap)),
      indexAt: (at) => (at.dy / (row + gap)).round(),
      enabled: arrangeable,
      slide: _slideForFlight(),
      curve: IssuanceFlight.curve,
      onMove: onMove,
      builder: (context, i) {
        final c = cards[i];
        return PushAway(
          hash: c.hash,
          fadeWhenOpening: true,
          child: IssuanceFlightHidden(
            hash: c.hash,
            child: _ListRow(
              credential: c,
              hintText: hintTexts[c.hash],
              selected: c.hash == openHash,
              // Nothing lands in a search result.
              flightTarget: i == 0 && results.isEmpty,
              query: query,
              result: results[c.hash],
              moves: arrangeable
                  ? moveActions(
                      context,
                      index: i,
                      count: cards.length,
                      onMove: onMove,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _ListRow extends StatelessWidget {
  /// The width of its card picture, and the room around it.
  static const double picture = 88;
  static const double padding = 8;

  final schemaless.Credential credential;
  final String? hintText;

  /// The thumbnail is where a received card lands.
  final bool flightTarget;

  /// Whether the detail pane shows this card.
  final bool selected;

  /// The screen reader's ways to move it ([moveActions]).
  final Map<CustomSemanticsAction, VoidCallback>? moves;

  /// While searching: the query, and why the card matched.
  final String query;
  final CardSearchResult? result;

  const _ListRow({
    required this.credential,
    this.hintText,
    this.flightTarget = false,
    this.selected = false,
    this.moves,
    this.query = "",
    this.result,
  });

  /// Whether the row says why the search found it: only when its name,
  /// hint and issuer don't already show it.
  static bool hasMatchLine(CardSearchResult r) =>
      !r.byName && r.hits.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final result = this.result;
    final folded = foldQuery(query);
    // Name, hint and issuer are marked where the name search found them
    // (not for a near miss: nothing there to mark).
    SearchMatch? mark(String text) =>
        result != null && result.byName ? findAnywhere(text, folded) : null;
    // Plain text unless something in it is marked.
    Widget line(String text, TextStyle style) {
      final m = mark(text);
      return m == null
          ? Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            )
          : Text.rich(
              searchMarkSpan(text, m, palette),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            );
    }

    final match = result != null && hasMatchLine(result)
        ? _MatchLine(result: result)
        : null;
    return _CardButton(
      credential: credential,
      hintText: hintText,
      matchText: match?.plainText(context),
      found: result?.hits.firstOrNull?.field.claimKey,
      pressDepth: 4,
      moves: moves,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
          side: selected
              ? BorderSide(width: 2, color: palette.primary)
              : YiviEdges.block(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(padding),
          child: Row(
            spacing: 16,
            children: [
              _flightSlot(
                first: flightTarget,
                child: CardHero(
                  credential: credential,
                  width: picture,
                  hintText: hintText,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(
                      credential.name,
                      palette.display(16).copyWith(color: palette.text),
                    ),
                    if ((hintText ?? "").isNotEmpty)
                      line(hintText!, palette.body(14)),
                    line(
                      credential.issuer.name,
                      palette.body(12).copyWith(color: palette.heading),
                    ),
                    ?match,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two cards a row, each with its name and hint under it. Hold a card to
/// drag it to another place.
class _GridView extends ConsumerWidget {
  static const double gap = 16;

  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final double width;
  final bool arrangeable;

  /// The card open in the detail pane, if there is one.
  final String? openHash;

  const _GridView({
    required this.cards,
    required this.hintTexts,
    required this.width,
    required this.arrangeable,
    this.openHash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final cardWidth = (width - gap) / 2;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final captionHeight = 8 + 40 * textScale;
    final cellHeight =
        cardWidth / CredentialCardArt.aspectRatio + captionHeight;
    final rows = (cards.length + 1) ~/ 2;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final onMove = _reorder(ref);
    // The column of a place, the first one on the reading side.
    double x(int column) => (rtl ? 1 - column : column) * (cardWidth + gap);
    return DragToArrange(
      keys: [for (final c in cards) c.hash],
      size: Size(width, rows * cellHeight + max(0, rows - 1) * gap),
      slotWidth: cardWidth,
      slotHeight: cellHeight,
      slot: (i) => Offset(x(i % 2), (i ~/ 2) * (cellHeight + gap)),
      indexAt: (at) {
        final row = (at.dy / (cellHeight + gap)).round();
        final column = (at.dx / (cardWidth + gap)).round().clamp(0, 1);
        return row * 2 + (rtl ? 1 - column : column);
      },
      enabled: arrangeable,
      slide: _slideForFlight(),
      curve: IssuanceFlight.curve,
      onMove: onMove,
      builder: (context, i) {
        final c = cards[i];
        return PushAway(
          hash: c.hash,
          fadeWhenOpening: true,
          child: IssuanceFlightHidden(
            hash: c.hash,
            child: _CardButton(
              credential: c,
              hintText: hintTexts[c.hash],
              pressDepth: 4,
              moves: arrangeable
                  ? moveActions(
                      context,
                      index: i,
                      count: cards.length,
                      onMove: onMove,
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _flightSlot(
                    first: i == 0,
                    // The card open in the detail pane: the red border of
                    // the list's rows, around the card.
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: CredentialCardArt.radiusFor(cardWidth),
                          side: BorderSide(
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignOutside,
                            color: c.hash == openHash
                                ? palette.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: CardHero(
                        credential: c,
                        width: cardWidth,
                        hintText: hintTexts[c.hash],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.display(14).copyWith(color: palette.text),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      hintTexts[c.hash] ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.body(12).copyWith(color: palette.heading),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Makes a card tappable and gives it one clear screen reader label:
/// "{name}, {hint}, {issuer}".
class _CardButton extends StatefulWidget {
  final schemaless.Credential credential;
  final String? hintText;
  final Widget child;

  /// How far the card moves down while it is pressed: it gives way under
  /// the finger, so a press is felt before the card opens. A little less in
  /// the list and grid, where the cards are smaller.
  final double pressDepth;

  /// How much of the card, from its top, shows (a card in the stack under
  /// the next one: its strip); null when all of it does. What has to be in
  /// view when it opens in the detail pane ([_revealCard]).
  final double? revealHeight;

  /// The screen reader's ways to move it to another place ([moveActions]).
  final Map<CustomSemanticsAction, VoidCallback>? moves;

  /// Why a search found it, read after the rest ([_MatchLine]).
  final String? matchText;

  /// The field a search found it by (a claim path key): the card opens on it.
  final String? found;

  const _CardButton({
    required this.credential,
    required this.child,
    this.hintText,
    this.matchText,
    this.found,
    required this.pressDepth,
    this.revealHeight,
    this.moves,
  });

  @override
  State<_CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<_CardButton> {
  /// The cards on screen by hash, to bring the one that opens in the
  /// detail pane into view ([_revealCard]).
  static final shown = <String, _CardButtonState>{};

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    shown[widget.credential.hash] = this;
  }

  @override
  void didUpdateWidget(_CardButton old) {
    super.didUpdateWidget(old);
    if (old.credential.hash != widget.credential.hash) {
      if (shown[old.credential.hash] == this) shown.remove(old.credential.hash);
      shown[widget.credential.hash] = this;
    }
  }

  @override
  void dispose() {
    if (shown[widget.credential.hash] == this) {
      shown.remove(widget.credential.hash);
    }
    super.dispose();
  }

  void _press(bool pressed) {
    if (mounted && pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final credential = widget.credential;
    final label = [
      credential.name,
      if ((widget.hintText ?? "").isNotEmpty) widget.hintText,
      credential.issuer.name,
      if ((widget.matchText ?? "").isNotEmpty) widget.matchText,
    ].join(", ");
    final depth = widget.pressDepth;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: label,
      customSemanticsActions: widget.moves,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key("${credential.credentialId}_tile"),
        behavior: HitTestBehavior.opaque,
        // A tap down arrives only once it is not a scroll (or after a short
        // wait), so scrolling over the stack does not push cards.
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: () => openCard(context, credential, found: widget.found),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _pressed && !reduceMotion ? depth : 0),
          duration: Duration(milliseconds: _pressed ? 90 : 260),
          curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
          builder: (context, dy, child) =>
              Transform.translate(offset: Offset(0, dy), child: child),
        ),
      ),
    );
  }
}

/// Under a search result that was found through one of its fields, which
/// field: "Woonplaats: Utrecht" for a value, "Bevat BSN" for a label (never
/// its value: a result shows no more than was typed), and how many more.
class _MatchLine extends StatelessWidget {
  final CardSearchResult result;

  const _MatchLine({required this.result});

  FieldHit get _hit => result.hits.first;

  String _more(BuildContext context) => result.hits.length > 1
      ? " · ${FlutterI18n.translate(context, "wallet.search.more", translationParams: {"count": "${result.hits.length - 1}"})}"
      : "";

  /// What a screen reader says.
  String plainText(BuildContext context) {
    final f = _hit.field;
    final what = _hit.kind == FieldHitKind.label
        ? FlutterI18n.translate(
            context,
            "wallet.search.contains",
            translationParams: {"label": f.label},
          )
        : "${f.label}: ${f.value}";
    return what + _more(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final f = _hit.field;
    final InlineSpan what;
    if (_hit.kind == FieldHitKind.label) {
      // The label goes where {label} is in the sentence, marked.
      const slot = "\u0000";
      final parts = FlutterI18n.translate(
        context,
        "wallet.search.contains",
        translationParams: {"label": slot},
      ).split(slot);
      what = TextSpan(
        children: [
          TextSpan(text: parts.first),
          searchMarkSpan(f.label, _hit.match, palette),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      );
    } else {
      what = TextSpan(
        children: [
          TextSpan(text: "${f.label}: "),
          searchMarkSpan(f.value ?? "", _hit.match, palette),
        ],
      );
    }
    return Text.rich(
      key: const Key("search_match_line"),
      TextSpan(
        children: [
          what,
          TextSpan(text: _more(context)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: palette.body(13).copyWith(color: palette.heading),
    );
  }
}

/// Marks the first card picture as the landing slot of a received card, and
/// hides the card that is flying in (with [hash]).
Widget _flightSlot({required bool first, String? hash, required Widget child}) {
  Widget slot = child;
  if (hash != null) slot = IssuanceFlightHidden(hash: hash, child: slot);
  if (first) slot = IssuanceFlightTarget(child: slot);
  return slot;
}

/// Moves a card in the user's order ([DragToArrange.onMove]).
void Function(int from, int to) _reorder(WidgetRef ref) =>
    ref.read(schemalessCredentialOrderControllerProvider.notifier).reorder;
