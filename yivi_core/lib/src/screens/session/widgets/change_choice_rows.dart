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
/// would share, and a radio in its header: tap to use it. The chosen one
/// (or the one a finger is on) has the outline of the current card on the
/// credential's page, drawn just outside the card so it keeps the share
/// screen's size (and hidden while the card flies).
///
/// A card that can't be used can't be picked: it has its chip, no radio,
/// and [fix] ("Add a new passport") under it.
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
    final outlined = selected && !SharedCardTileInFlight.of(context);
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
            shown: outlined,
            child: SharedCardTile(
              bundle: bundle,
              trailing: _Radio(on: selected),
            ),
          ),
        ),
      ),
    );
  }
}

/// The round tick of a choice: a ring, filled with a dot when [on].
class _Radio extends StatelessWidget {
  final bool on;

  const _Radio({required this.on});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: Key(on ? "sheet_radio_on" : "sheet_radio_off"),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on
              ? palette.link
              : palette.secondaryText.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: on
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: palette.link,
                shape: BoxShape.circle,
              ),
            )
          : null,
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

  const _AddKindRow({super.key, required this.descriptor, required this.onTap});

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
          child: CardTile(
            art: Opacity(
              opacity: 0.75,
              child: CredentialTypeThumbnail(
                descriptor: descriptor,
                width: SharedCardTile.miniWidth,
              ),
            ),
            title: descriptor.name,
            subtitle: how,
            subtitleMaxLines: 2,
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: palette.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}
