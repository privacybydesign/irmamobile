part of "change_choice_sheet.dart";

/// The text under a sheet's title, at the top of its scrolling content.
class _Intro extends StatelessWidget {
  final String text;

  const _Intro(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: palette
            .body(15)
            .copyWith(height: 21 / 15, color: palette.secondaryText),
      ),
    );
  }
}

/// "Share nothing", the first choice for optional data: a card the size of
/// the others with a grey tile where the card art goes. It has the outline
/// while the data is left out; a tap leaves it out and closes the sheet.
class _ShareNothingCard extends StatelessWidget {
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ShareNothingCard({
    super.key,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      onTap: onTap,
      child: PressScale(
        scale: PressScale.card,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: CardTileOutline(
            shown: selected,
            child: CardTile(
              art: Container(
                width: CardTile.miniWidth,
                height: CardTile.miniHeight,
                decoration: ShapeDecoration(
                  color: palette.secondaryText.withValues(alpha: 0.1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 20,
                  color: palette.secondaryText,
                ),
              ),
              title: context.tr("share.sheet.share_nothing"),
              subtitle: subtitle,
              subtitleMaxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A card in the app, drawn as on the share screen with every value it
/// would share (and its tags): tap to use it. The chosen one has the link
/// blue ring, drawn just outside the card so it keeps the share screen's
/// size; it fades in (220 ms) when the card is put down in the sheet. No
/// radio: the ring says which.
///
/// A card that can't be used can't be picked: it has its chip and [fix]
/// ("Add a new passport") under it.
class _OwnedCard extends StatelessWidget {
  final DisclosureBundle bundle;
  final bool selected;
  final ({String label, VoidCallback onTap})? fix;
  final VoidCallback onTap;

  const _OwnedCard({
    super.key,
    required this.bundle,
    required this.selected,
    this.fix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final problem = problemOfBundle(bundle) != null;
    if (problem) {
      return SharedCardTile(
        bundle: bundle,
        fixLabel: fix?.label,
        onFix: fix?.onTap,
      );
    }
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      onTap: onTap,
      child: PressScale(
        scale: PressScale.card,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: _Ring(
            shown: selected,
            child: SharedCardTile(bundle: bundle),
          ),
        ),
      ),
    );
  }
}

/// The ring of the chosen card, fading in over 220 ms when it appears.
class _Ring extends StatelessWidget {
  final bool shown;
  final Widget child;

  const _Ring({required this.shown, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!shown) return child;
    final palette = YiviPalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: YiviMotion.duration(context, const Duration(milliseconds: 220)),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => CardTileOutline(
        key: const Key("sheet_chosen_ring"),
        shown: true,
        color: palette.link.withValues(alpha: t),
        child: child!,
      ),
    );
  }
}

/// "Add another card": opens and closes the kinds to add under it. Without
/// [onTap] it stays open (nothing usable in the app).
class _AddToggle extends StatelessWidget {
  final String label;
  final bool open;
  final VoidCallback? onTap;

  const _AddToggle({
    super.key,
    required this.label,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: onTap != null,
      expanded: open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            spacing: 8,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: palette.link,
              ),
              Expanded(
                child: Text(
                  label,
                  style: palette
                      .body(15, weight: FontWeight.w600)
                      .copyWith(color: palette.link),
                ),
              ),
              if (onTap != null)
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: palette.link,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A kind of card to add, as a row: its card faded, its name, and one line
/// on how you get it. Only Yivi's own ways are told ("You get a code by
/// e-mail", "You scan the document with your phone"); for another issuer
/// it is who gives it, and where. The whole row is the button.
class _AddKindRow extends ConsumerWidget {
  final CredentialDescriptor descriptor;
  final VoidCallback onTap;

  /// Where its picture is: it rises from there into the first step.
  final GlobalKey? artKey;

  const _AddKindRow({
    super.key,
    required this.descriptor,
    required this.onTap,
    this.artKey,
  });

  /// The "how" line of [d].
  static String howOf(
    BuildContext context,
    WidgetRef ref,
    CredentialDescriptor d,
  ) {
    final flow = ref
        .read(irmaRepositoryProvider)
        .embeddedFlowOf(d.credentialId);
    final host = hostOf(d.issueURL);
    return switch (flow) {
      EmbeddedFlow.email => context.tr("share.how.email"),
      EmbeddedFlow.phone => context.tr("share.how.phone"),
      EmbeddedFlow.document => context.tr("share.how.document"),
      _ when host != null => context.tr("share.how.via", {
        "issuer": d.issuer.name,
        "host": host,
      }),
      _ => d.issuer.name,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final how = howOf(context, ref, descriptor);
    return Semantics(
      button: true,
      label: "${descriptor.name}, $how",
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(
          scale: PressScale.card,
          child: Container(
            constraints: const BoxConstraints(minHeight: 65),
            padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
            decoration: SurfaceCard.decoration(context),
            child: Row(
              spacing: 12,
              children: [
                artKey == null
                    ? FadedCardArt(descriptor: descriptor)
                    : FlightSpot(
                        flightKey: artKey!,
                        child: FadedCardArt(descriptor: descriptor),
                      ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        descriptor.name,
                        style: palette
                            .display(16, weight: FontWeight.w700)
                            .copyWith(height: 21 / 16, color: palette.text),
                      ),
                      Text(
                        how,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: palette.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
