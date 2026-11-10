part of "disclosure_share_screen.dart";

/// A widget on the page with the gap above it.
class _Spaced {
  final double gap;
  final Widget child;

  const _Spaced(this.gap, this.child);
}

/// The compact bar once the requestor card has scrolled away: it
/// fades in and comes down 8 pt, as on the detail pages.
class _CompactBarSlot extends StatelessWidget {
  final ValueListenable<bool> shown;
  final schemaless.TrustedParty requestor;
  final String subtitle;
  final GlobalKey? logoKey;

  const _CompactBarSlot({
    required this.shown,
    required this.requestor,
    required this.subtitle,
    this.logoKey,
  });

  @override
  Widget build(BuildContext context) {
    return CompactBarDropIn(
      shown: shown,
      bar: (t) => RequestorCompactBar(
        requestor: requestor,
        subtitle: subtitle,
        opacity: t,
        logoKey: logoKey,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) =>
      CapsLabel(title, padding: const EdgeInsets.symmetric(horizontal: 6));
}

/// The strip at the foot of a card with other choices.
class _ChoiceStrip extends StatelessWidget {
  final String text;
  final Widget button;

  const _ChoiceStrip({required this.text, required this.button});

  @override
  Widget build(BuildContext context) {
    return CardTileStrip(
      children: [
        Expanded(
          child: Text(
            text,
            key: const Key("share_also"),
            style: CardTileStrip.textStyle(context),
          ),
        ),
        button,
      ],
    );
  }
}

/// A card the requestor gives in return (an issuance with disclosure): a
/// tile like the cards that are shared, with its name, who gives it and
/// every value it holds.
class _OfferedCard extends StatelessWidget {
  final schemaless.Credential card;

  const _OfferedCard({required this.card});

  @override
  Widget build(BuildContext context) => CardTile(
    key: const Key("share_offered_card"),
    art: CredentialCardArt(credential: card, width: CardTile.miniWidth),
    title: card.name,
    subtitle: card.issuer.name,
    body: [
      if (card.attributes.isNotEmpty)
        YiviCredentialCardAttributeList(
          card.attributes,
          credentialId: card.credentialId,
          namespaced: card.isMdoc,
          showDividers: true,
        ),
    ],
  );
}

/// The bottom of the share screen: why it can't go on (red when nobody
/// vouches for the requestor), the progress (a part per asked card, filled
/// by how many are ready, and a line: what is left, or that all is set), the
/// button, and for a card that does not count a quiet "Don't share".
class _ShareBar extends StatelessWidget {
  /// Above the button, alone: red when [risky], else why it can't be done.
  final String? reason;

  /// The parts: how many asked cards, how many ready.
  final ({int total, int filled})? parts;

  /// The line beside the parts.
  final String? line;

  /// The line is a warning (a card that does not count): red, semibold.
  final bool warn;
  final String label;
  final bool primary;

  /// Nobody vouches for the requestor: a sober dark "Share anyway" with the
  /// reason in red above it, instead of the celebratory red button.
  final bool risky;
  final VoidCallback? onPressed;

  /// The button just became "Share": it fades in, and ignores taps meanwhile.
  final bool arriving;

  /// The button does the next step ("Add passport"), not share.
  final bool isNext;

  /// A quiet "Don't share" under the button: the request may not be for them.
  final ({String label, VoidCallback onTap})? decline;

  /// In a bar across the bottom; otherwise just its content (the panel).
  final bool inBar;

  const _ShareBar({
    required this.reason,
    this.parts,
    this.line,
    this.warn = false,
    required this.label,
    required this.primary,
    this.risky = false,
    required this.onPressed,
    this.arriving = false,
    this.isNext = false,
    this.decline,
    this.inBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final Widget button = risky
        ? PillButton(
            label: label,
            style: PillStyle.neutral,
            size: PillSize.large,
            onPressed: onPressed,
          )
        : primary
        ? FancyPillButton(label: label, onPressed: onPressed)
        : PillButton(label: label, size: PillSize.large, onPressed: onPressed);
    final pill = isNext
        ? KeyedSubtree(key: const Key("share_next"), child: button)
        : button;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (reason case final r?)
          Text(
            r,
            key: const Key("share_reason"),
            textAlign: TextAlign.center,
            style: risky
                ? palette
                      .body(13.5, weight: FontWeight.w600)
                      .copyWith(height: 19 / 13.5, color: palette.errorText)
                : palette
                      .body(13.5)
                      .copyWith(height: 19 / 13.5, color: palette.heading),
          ),
        if (line case final l?)
          _ShareProgress(parts: parts, line: l, warn: warn),
        KeyedSubtree(
          key: const Key("share_button"),
          child: arriving
              ? IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: YiviMotion.duration(
                      context,
                      const Duration(milliseconds: 1300),
                    ),
                    builder: (context, t, child) =>
                        Opacity(opacity: t, child: child),
                    child: pill,
                  ),
                )
              : pill,
        ),
        if (decline case final d?)
          TextLink(
            key: const Key("share_decline"),
            label: d.label,
            onPressed: d.onTap,
          ),
      ],
    );
    // Floats over the page: solid behind the button, with the fade above
    // it, so the line never sits on a card.
    return inBar ? IrmaBottomBarBase(child: content) : content;
  }
}

/// The share screen's progress: a 28×4 part per asked card, filled from
/// the left by how many are ready (not by which), and [line] beside them. A
/// part that fills while on screen grows from its start (450 ms).
class _ShareProgress extends StatelessWidget {
  final ({int total, int filled})? parts;
  final String line;
  final bool warn;

  const _ShareProgress({
    required this.parts,
    required this.line,
    required this.warn,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final p = parts;
    return Semantics(
      key: const Key("share_progress"),
      label: line,
      excludeSemantics: true,
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          if (p != null && p.total > 0)
            Row(
              key: const Key("share_progress_parts"),
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                for (var i = 0; i < p.total; i++)
                  _SharePart(filled: i < p.filled),
              ],
            ),
          Flexible(
            child: Text(
              line,
              key: const Key("share_progress_line"),
              textAlign: p == null ? TextAlign.center : TextAlign.start,
              style: warn
                  ? palette
                        .body(13.5, weight: FontWeight.w600)
                        .copyWith(height: 19 / 13.5, color: palette.errorText)
                  : palette
                        .body(12)
                        .copyWith(
                          height: 16 / 12,
                          color: palette.secondaryText.withValues(alpha: 0.85),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePart extends StatefulWidget {
  final bool filled;

  const _SharePart({required this.filled});

  @override
  State<_SharePart> createState() => _SharePartState();
}

class _SharePartState extends State<_SharePart>
    with SingleTickerProviderStateMixin {
  late final _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: widget.filled ? 1 : 0,
  );

  @override
  void didUpdateWidget(_SharePart old) {
    super.didUpdateWidget(old);
    if (widget.filled == old.filled) return;
    final to = widget.filled ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fill.value = to;
    } else {
      _fill.animateTo(to);
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        width: 28,
        height: 4,
        color: palette.text.withValues(alpha: 0.12),
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedBuilder(
          animation: _fill,
          builder: (context, _) => FractionallySizedBox(
            widthFactor: YiviMotion.ease.transform(_fill.value),
            heightFactor: 1,
            child: ColoredBox(color: palette.successText),
          ),
        ),
      ),
    );
  }
}

/// The green ring around a card that landed while the screen was open: it
/// fades in (350 ms) as the card lands, and stays.
class _LandedRing extends StatelessWidget {
  final bool shown;
  final Widget child;

  const _LandedRing({required this.shown, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!shown) return child;
    final palette = YiviPalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: YiviMotion.duration(context, const Duration(milliseconds: 350)),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => CardTileOutline(
        shown: true,
        color: palette.successText.withValues(alpha: t),
        child: child!,
      ),
    );
  }
}

/// A card in the app of a kind the request takes, that does not count for
/// it: one of its values is not what they ask. Shown as it is, with that
/// value in red and what they ask beside it, and a strip that says what
/// the user can do: get it again if it changed, or else not share.
class _MismatchTile extends StatelessWidget {
  final WalletMismatch mismatch;
  final GlobalKey? landingKey;
  final String requestor;

  const _MismatchTile({
    super.key,
    required this.mismatch,
    required this.landingKey,
    required this.requestor,
  });

  @override
  Widget build(BuildContext context) {
    final card = mismatch.card;
    final asked = localizedAttributeText(context, mismatch.asked) ?? "";
    final have = localizedAttributeText(context, mismatch.have) ?? "";
    final single = mismatch.descriptor.isSingleton || card.isSingleton;
    final art = CredentialCardArt(credential: card, width: CardTile.miniWidth);
    return CardTile(
      key: const Key("share_not_counted"),
      art: landingKey == null
          ? art
          : FlightSpot(flightKey: landingKey!, child: art),
      title: card.name,
      subtitle: card.issuer.name,
      chip: StatusChip(
        label: context.tr("share.not_counted.chip"),
        tone: DialogTone.danger,
      ),
      body: [
        YiviCredentialCardAttributeList(
          card.attributes,
          credentialId: card.credentialId,
          namespaced: card.isMdoc,
          disclosure: true,
          showDividers: true,
          mismatched: {
            for (final a in card.attributes)
              if (a.effectiveDisplayName == mismatch.attributeName)
                claimPathKey(a.claimPath),
          },
          mismatchedTag: context.tr("share.not_counted.asked", {
            "value": asked,
          }),
        ),
      ],
      footer: CardTileStrip(
        key: const Key("share_not_counted_note"),
        children: [
          Expanded(
            child: Text(
              context.tr(
                single
                    ? "share.not_counted.text_single"
                    : "share.not_counted.text",
                {
                  "requestor": requestor,
                  "field": mismatch.attributeName,
                  "value": asked,
                  "have": have,
                },
              ),
              style: CardTileStrip.textStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// The panel at the left held sideways (and on a tablet): the title and who
/// asks at the top, the progress and the button at its bottom. It scrolls
/// only when it doesn't fit (a large text size).
class _LandscapePanel extends StatelessWidget {
  final double top;
  final Widget title;
  final Widget card;
  final Widget action;

  const _LandscapePanel({
    required this.top,
    required this.title,
    required this.card,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = FloatingBarPlacement.buttonBottom(context);
    return FillScrollView(
      scrollKey: const Key("share_panel"),
      padding: EdgeInsets.fromLTRB(0, top, 0, bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 16), card],
          ),
          Padding(padding: const EdgeInsets.only(top: 16), child: action),
        ],
      ),
    );
  }
}

/// The right column held sideways: what is shared, scrolling under the
/// corner's close button. Once something is under the top, the column gets
/// the bar's hard edge behind that button, across to the screen's edge.
class _SidewaysCards extends StatefulWidget {
  final double top;
  final bool risky;
  final List<Widget> children;

  const _SidewaysCards({
    required this.top,
    required this.risky,
    required this.children,
  });

  @override
  State<_SidewaysCards> createState() => _SidewaysCardsState();
}

class _SidewaysCardsState extends State<_SidewaysCards> {
  final _under = ScrollEdgeNotifier();

  @override
  void dispose() {
    _under.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final media = MediaQuery.paddingOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ScrollEdgeListener(
            notifier: _under,
            child: FillScrollView(
              scrollKey: const Key("share_scroll_view"),
              physics: const AlwaysScrollableScrollPhysics(),
              // 4 at the left: room for a missing card's dashed outline.
              padding: EdgeInsets.fromLTRB(4, widget.top, 0, 56 + media.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: -sidewaysMargin(context, end: true),
          height: media.top + 52,
          child: IgnorePointer(
            child: ScrollEdgeBand(
              under: _under,
              color: widget.risky ? palette.errorSurface : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// A red wash behind the top of the page when nobody vouches for the
/// requestor.
class _TrustWash extends StatelessWidget {
  final bool on;
  final Widget child;

  /// How far down the wash goes: 460, 300 held sideways.
  final double height;

  const _TrustWash({required this.on, required this.child, this.height = 460});

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    final palette = YiviPalette.of(context);
    return Stack(
      children: [
        Positioned(
          key: const Key("share_trust_wash"),
          left: 0,
          right: 0,
          top: 0,
          height: height,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.errorSurface,
                    palette.errorSurface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
