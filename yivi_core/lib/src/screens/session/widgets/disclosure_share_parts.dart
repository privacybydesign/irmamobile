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

  const _CompactBarSlot({
    required this.shown,
    required this.requestor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return CompactBarDropIn(
      shown: shown,
      bar: (t) => RequestorCompactBar(
        requestor: requestor,
        subtitle: subtitle,
        opacity: t,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final bool shown;

  const _SectionLabel(this.title) : shown = true;

  /// The label's room only: it holds the place of a label at the other
  /// side, so what comes under both lines up.
  const _SectionLabel.room(this.title) : shown = false;

  @override
  Widget build(BuildContext context) {
    if (!shown) {
      // Hidden from screen readers too (maintainSemantics is off).
      return Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: _SectionLabel(title),
      );
    }
    return CapsLabel(title, padding: const EdgeInsets.symmetric(horizontal: 6));
  }
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

/// Optional data that is not shared: one row with the kinds it takes, that
/// it is not shared under it, and "Share" at the end. The whole row opens the
/// sheet; the pill only says so. A card added in the sheet lands on its
/// plus.
class _OptionalRow extends StatelessWidget {
  final GlobalKey? landingKey;
  final String title;
  final String subtitle;
  final String pick;
  final VoidCallback onTap;

  const _OptionalRow({
    super.key,
    this.landingKey,
    required this.title,
    required this.subtitle,
    required this.pick,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      label: "$title, $subtitle",
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(
          scale: PressScale.card,
          child: SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  key: landingKey,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, size: 22, color: palette.link),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: palette
                            .display(15)
                            .copyWith(color: palette.text),
                      ),
                      Text(
                        subtitle,
                        style: palette
                            .body(13.5)
                            .copyWith(
                              height: 19 / 13.5,
                              color: palette.secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: SmallPill(label: pick, onPressed: onTap),
                ),
              ],
            ),
          ),
        ),
      ),
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
          showDividers: true,
        ),
    ],
  );
}

class _Footnote extends StatelessWidget {
  final String text;

  const _Footnote({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // Centred under the cards, also when it fits on one line.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          key: const Key("share_footnote"),
          textAlign: TextAlign.center,
          style: palette
              .body(13.5)
              .copyWith(height: 19 / 13.5, color: palette.secondaryText),
        ),
      ),
    );
  }
}

/// How the line above the share button reads.
enum _ReasonTone {
  /// What is left to do before sharing: one short semibold line.
  soft,

  /// Everything is there: green, with a check.
  ready,

  /// Nobody vouches for the requestor: red.
  risky,

  /// Why it can't be done in Yivi.
  plain,
}

/// The button at the bottom, with what is left above it.
class _ShareBar extends StatelessWidget {
  final String? reason;
  final _ReasonTone tone;

  /// Per required item whether it is ready: dots above the reason.
  final List<bool>? steps;
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

  /// In a bar across the bottom; otherwise just the reason and the button
  /// (the landscape panel).
  final bool inBar;

  const _ShareBar({
    required this.reason,
    this.tone = _ReasonTone.plain,
    this.steps,
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
    final style = switch (tone) {
      _ReasonTone.risky =>
        palette
            .body(13.5, weight: FontWeight.w600)
            .copyWith(height: 19 / 13.5, color: palette.errorText),
      _ReasonTone.soft =>
        palette
            .body(15, weight: FontWeight.w600)
            .copyWith(height: 20 / 15, color: palette.text),
      _ReasonTone.ready =>
        palette
            .body(14.5, weight: FontWeight.w600)
            .copyWith(height: 20 / 14.5, color: palette.successText),
      _ReasonTone.plain =>
        palette.body(13.5).copyWith(height: 19 / 13.5, color: palette.heading),
    };
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
        if (steps case final dots?)
          ExcludeSemantics(
            child: Row(
              key: const Key("share_steps"),
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                for (final done in dots)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? palette.successText
                          : palette.secondaryText.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
        if (reason != null)
          Text.rich(
            TextSpan(
              children: [
                if (tone == _ReasonTone.ready)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: palette.successText,
                      ),
                    ),
                  ),
                TextSpan(text: reason),
              ],
            ),
            key: const Key("share_reason"),
            textAlign: TextAlign.center,
            style: style,
          ),
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
    // Floats over the page: solid behind the reason and the button, with
    // the fade above it, so the reason never sits on a card.
    return inBar ? IrmaBottomBarBase(child: content) : content;
  }
}

/// The message to sign, as a quote: brand-red marks around it.
class _QuotedMessage extends StatelessWidget {
  final String message;

  const _QuotedMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final mark = TextStyle(
      fontFamily: "Georgia",
      fontFamilyFallback: const ["serif"],
      fontSize: 56,
      height: 1,
      color: palette.primary,
    );
    return SurfaceCard(
      key: const Key("share_message"),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(child: Text("\u201C", style: mark)),
          SignatureMessage(message: message),
          Align(
            alignment: Alignment.centerRight,
            child: ExcludeSemantics(child: Text("\u201D", style: mark)),
          ),
        ],
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
          : CardFlightLanding(landingKey: landingKey!, child: art),
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

/// The panel at the left on a phone held sideways: room for the first
/// section label (so the card lines up with the first card at the right),
/// who asks, what the page is, and at its bottom the reason and the button.
/// It scrolls only when it doesn't fit (a large text size).
class _LandscapePanel extends StatelessWidget {
  final double top;
  final String? label;
  final Widget card;
  final String lead;
  final Widget action;

  const _LandscapePanel({
    required this.top,
    required this.label,
    required this.card,
    required this.lead,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final bottom = FloatingBarPlacement.buttonBottom(context);
    return FillScrollView(
      scrollKey: const Key("share_panel"),
      padding: EdgeInsets.fromLTRB(16, top, 0, bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label != null) ...[
                const SizedBox(height: 24),
                _SectionLabel.room(label!),
                const SizedBox(height: 12),
              ],
              card,
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  lead,
                  key: const Key("share_lead"),
                  style: palette
                      .body(13.5)
                      .copyWith(
                        height: 19 / 13.5,
                        color: palette.secondaryText,
                      ),
                ),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(top: 16), child: action),
        ],
      ),
    );
  }
}

/// A red wash behind the top of the page when nobody vouches for the
/// requestor.
class _TrustWash extends StatelessWidget {
  final bool on;
  final Widget child;

  const _TrustWash({required this.on, required this.child});

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
          height: 460,
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
