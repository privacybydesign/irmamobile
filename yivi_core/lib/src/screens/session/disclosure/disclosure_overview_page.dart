import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/requestor_trust.dart";
import "../../../models/session_state.dart";
import "../../../models/session_user_interaction.dart";
import "../../../providers/last_shared_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../providers/wallet_cards_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../theme/yivi_tone.dart";
import "../../../util/after_frame.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/action_bar.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/bars/compact_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/feedback/dialog.dart";
import "../../../widgets/flight/flight.dart";
import "../../../widgets/layout/fill_scroll_view.dart";
import "../../../widgets/text/caps_label.dart";
import "../issuance/received_card_tile.dart";
import "../layout/session_heading.dart";
import "../layout/session_layout.dart";
import "../layout/session_scaffold.dart";
import "../models/disclosure_plan_view.dart";
import "../models/technical_details.dart";
import "../requestor/requestor_card.dart";
import "../requestor/requestor_trust_sheet.dart";
import "../result/done_flight.dart";
import "disclosure_keys.dart";
import "disclosure_value_list.dart";
import "disclosure_words.dart";
import "signed_message.dart";

/// "Het overzicht" (2.2): who asks, one list of what is shared, the pile of
/// cards it comes from with "Wijzig", a hint at optional data that is not
/// shared, and one button. It never asks a question: changes are made on
/// "Kies wat je deelt" ([onChange]).
///
/// Everything comes from [session] and the user's selection
/// ([disclosureSelectionProvider]); the rules are in
/// `disclosure_plan_view.dart`.
class DisclosureOverviewPage extends ConsumerStatefulWidget {
  final SessionState session;
  final VoidCallback onDismiss;

  /// Ends the session without asking ("Niet delen" in the trust sheet).
  final VoidCallback onClose;

  /// Shares [choices]; [shared] are the cards that go, for the done screen.
  final void Function(
    List<ChoiceSelection> choices,
    List<SelectableCredentialInstance> shared,
  )
  onShare;

  /// Opens "Kies wat je deelt"; with a choice, scrolled to it (the hint).
  /// Null while there is no such page.
  final void Function(int? choice)? onChange;

  const DisclosureOverviewPage({
    super.key,
    required this.session,
    required this.onDismiss,
    required this.onClose,
    required this.onShare,
    this.onChange,
  });

  @override
  ConsumerState<DisclosureOverviewPage> createState() =>
      _DisclosureOverviewPageState();
}

class _DisclosureOverviewPageState
    extends ConsumerState<DisclosureOverviewPage> {
  /// The requestor card, and whether it has scrolled under the bar (the
  /// compact bar then says who asks).
  final _headerKey = GlobalKey(debugLabel: "share_requestor_card");
  final _scrolledPast = ValueNotifier(false);
  double _scrolled = 0;

  /// What flies into the done screen: the message, the logo (in its card or
  /// in the compact bar) and the cards of the pile.
  final _messageKey = GlobalKey(debugLabel: "share_message");
  final _logoKey = GlobalKey(debugLabel: "share_requestor_logo");
  final _barLogoKey = GlobalKey(debugLabel: "share_bar_logo");
  final _pileKeys = <String, GlobalKey>{};

  GlobalKey _pileKey(String hash) =>
      _pileKeys[hash] ??= GlobalKey(debugLabel: "share_pile_$hash");

  @override
  void dispose() {
    _scrolledPast.dispose();
    super.dispose();
  }

  void _checkHeader() {
    if (!mounted) return;
    _scrolledPast.value =
        headerUnderBar(context, _headerKey, at: 12) ?? _scrolled > 0;
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final t = context.tr;
    final session = widget.session;
    final requestor = session.requestor.name;
    final plan = session.disclosurePlan ?? DisclosurePlan(choices: const []);
    final selection = ref.watch(disclosureSelectionProvider(session.id));
    final sharesOf = ref.watch(sharesOfProvider(session.id));
    final wallet = ref.watch(walletCardsProvider);

    final signing = session.type == SessionType.signature;
    final offered = session.offeredCredentials ?? const <Credential>[];
    final kind = signing
        ? "sign"
        : offered.isNotEmpty
        ? "share_receive"
        : "share";
    final nothing = nothingRequired(plan);
    final blocks = overviewBlocks(plan, selection, sharesOf: sharesOf);
    final cards = usedCards(plan, selection, sharesOf: sharesOf);
    final hint = optionalHint(plan, selection, sharesOf: sharesOf);
    final kept = keptNames(plan, selection, sharesOf: sharesOf);
    final risky = requestorTrustOf(session.requestor).risky;
    final layout = SessionLayout.of(context);
    if (!layout.split) afterFrame(_checkHeader);

    void openTrust() => showRequestorTrustSheet(
      context: context,
      requestor: session.requestor,
      logoHeroTag: requestorLogoHeroTag(session.requestor),
      onDontShare: widget.onClose,
      technicalDetails: technicalDetailsOf(session, cards, t),
    );

    SessionHeading heading({required double gap}) => SessionHeading(
      title: nothing && !signing
          ? t("share.nothing.title")
          : t("share.title.$kind"),
      titleKey: DisclosureKeys.title,
      party: session.requestor,
      onInfo: openTrust,
      cardKey: _headerKey,
      logoKey: _logoKey,
      logoHeroTag: requestorLogoHeroTag(session.requestor),
      gap: gap,
    );

    final messageText = signing ? session.messageToSign : null;
    final change = widget.onChange;

    // The page under the requestor card (beside it, held sideways).
    final list = <Widget>[
      if (messageText != null) ...[
        _Gap.section,
        _SectionLabel(t("share.message_label")),
        FlightSpot(
          flightKey: _messageKey,
          child: SignedMessage(
            key: DisclosureKeys.message,
            message: messageText,
            clamp: SignedMessage.shareClamp,
            onReadAll: () => showSignedMessageSheet(
              context: context,
              message: messageText,
              lead: t("share.message_sheet.lead", {"requestor": requestor}),
              from: _messageKey,
            ),
          ),
        ),
      ],
      if (nothing)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 0),
          child: Text(
            t(signing ? "share.nothing.lead_sign" : "share.nothing.lead"),
            key: DisclosureKeys.lead,
            style: palette
                .body(15)
                .copyWith(height: 21 / 15, color: palette.text),
          ),
        ),
      if (blocks.isNotEmpty) ...[
        _Gap.section,
        _SectionLabel(
          t(
            signing
                ? "share.section.with_signature"
                : "share.section.you_share",
          ),
        ),
        ..._valueCards(blocks, requestor),
      ],
      if (cards.isNotEmpty)
        _PileRow(
          cards: [for (final c in cards) sharedCardFor(c, wallet)],
          keyOf: _pileKey,
          text: cards.length == 1
              ? t("share.overview.from_one")
              : t("share.overview.from_many", {
                  "count": countWord(context, cards.length),
                }),
          action: canChangeAnything(plan)
              ? t("share.overview.change")
              : t("share.overview.view"),
          onTap: change == null ? null : () => change(null),
        ),
      if (hint.isNotEmpty)
        _HintRow(
          text: t(
            "share.optional.hint_${hint.length == 1 ? "one" : "many"}"
            "${signing ? "_sign" : ""}",
            {"count": countWord(context, hint.length)},
          ),
          onTap: change == null ? null : () => change(hint.first),
        ),
      if (kept.isNotEmpty)
        _KeepCard(
          head: t("share.keep.head", {"requestor": requestor}),
          names: joinAnd(context, kept),
        ),
      if (offered.isNotEmpty) ...[
        _Gap.section,
        _SectionLabel(t("share.receive.section")),
        for (final (n, card) in offered.indexed)
          Padding(
            padding: const EdgeInsets.only(top: YiviSpace.x8),
            child: ReceivedCardTile(
              key: DisclosureKeys.offered(n),
              card: card,
              subtitle: card.issuer.name,
            ),
          ),
      ],
    ];

    void share() {
      DoneFlight.capture(
        context,
        messageKey: _messageKey,
        logoKey: _scrolledPast.value ? _barLogoKey : _logoKey,
        cards: [
          for (final c in cards.take(4))
            if (_pileKeys[c.hash] case final key?) (key, c.hash),
        ],
      );
      widget.onShare(answerFor(plan, selection, sharesOf: sharesOf), cards);
    }

    final label = risky
        ? t(
            signing
                ? "share.trust.risky.sign_anyway"
                : "share.trust.risky.share_anyway",
          )
        : signing
        ? t("share.button.sign_and_share")
        : offered.isNotEmpty
        ? t(
            cards.isEmpty
                ? "share.receive.button_only"
                : "share.receive.button",
          )
        : nothing && cards.isEmpty
        ? t("share.nothing.button")
        : t("share.button.share");
    final ready = canShare(plan);
    final bar = _ShareBar(
      inBar: !layout.split,
      reason: risky
          ? t(
              signing
                  ? "share.trust.risky.reason_sign"
                  : "share.trust.risky.reason",
              {"requestor": requestor},
            )
          : null,
      label: label,
      risky: risky,
      onPressed: !ready
          ? null
          : risky
          ? () async {
              if (await _confirmShareAnyway(requestor)) share();
            }
          : share,
    );

    if (layout.split) {
      return SessionScaffold(
        appBarTitle: "share.bar.$kind",
        onDismiss: widget.onDismiss,
        wide: true,
        scrollsUnderBars: true,
        cornerClose: true,
        body: TrustWash(
          on: risky,
          washKey: DisclosureKeys.trustWash,
          height: 300,
          fill: true,
          child: SidewaysLayout(
            panel: SessionPanel(
              key: DisclosureKeys.panel,
              top: heading(gap: YiviSpace.x16),
              action: bar,
            ),
            content: SessionPanelContent(
              key: DisclosureKeys.overview,
              scrollKey: DisclosureKeys.scrollView,
              children: _dropFirstGap(list),
            ),
          ),
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "share.bar.$kind",
      onDismiss: widget.onDismiss,
      scrollsUnderBars: true,
      bottomNavigationBar: bar,
      edgeColor: risky ? palette.errorSurface : null,
      startBar: CompactBarDropIn(
        shown: _scrolledPast,
        bar: (o) => RequestorCompactBar(
          requestor: session.requestor,
          subtitle: t("share.ask.$kind"),
          opacity: o,
          logoKey: _barLogoKey,
        ),
      ),
      body: TrustWash(
        on: risky,
        washKey: DisclosureKeys.trustWash,
        fill: true,
        child: Builder(
          builder: (context) {
            final insets = BarInsets.of(context);
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                _scrolled = n.metrics.pixels;
                _checkHeader();
                return false;
              },
              child: FillScrollView(
                key: DisclosureKeys.overview,
                scrollKey: DisclosureKeys.scrollView,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16 + insets.left,
                  16 + insets.top,
                  16 + insets.right,
                  16 + insets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [heading(gap: 18), ...list],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The white cards of the list: one with the values of the required
  /// choices, a hairline between blocks; one per shared optional choice,
  /// with its chip.
  List<Widget> _valueCards(List<ValueBlock> blocks, String requestor) {
    final required = blocks.where((b) => !b.optional).toList();
    final optional = blocks.where((b) => b.optional).toList();
    Widget block(ValueBlock b, {required bool line, bool chip = false}) =>
        _ValueBlock(
          cards: b.cards,
          requestor: requestor,
          line: line,
          chip: chip,
        );
    return [
      if (required.isNotEmpty)
        _WhiteCard(
          key: DisclosureKeys.values,
          children: [
            for (final (n, b) in required.indexed) block(b, line: n > 0),
          ],
        ),
      for (final (n, b) in optional.indexed)
        Padding(
          padding: EdgeInsets.only(
            top: required.isEmpty && n == 0 ? 0 : YiviSpace.x8,
          ),
          child: _WhiteCard(
            key: DisclosureKeys.optionalCard(b.choice),
            children: [block(b, line: false, chip: true)],
          ),
        ),
    ];
  }

  static List<Widget> _dropFirstGap(List<Widget> list) =>
      list.isNotEmpty && list.first is _Gap ? list.sublist(1) : list;

  /// "Delen met een partij die Yivi niet kent?": the safe answer is the big
  /// button.
  Future<bool> _confirmShareAnyway(String requestor) async {
    String t(String key) => context.tr(key, {"requestor": requestor});
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => YiviDialog(
            cardKey: DisclosureKeys.anywayDialog,
            icon: const ToneDisc(
              icon: Icons.warning_rounded,
              tone: YiviTone.danger,
            ),
            title: t("share.trust.confirm.title"),
            message: t("share.trust.confirm.text"),
            actions: [
              PrimaryPillButton(
                key: DisclosureKeys.anywayCancel,
                size: PillSize.regular,
                label: t("share.trust.confirm.dont_share"),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              PillButton(
                key: DisclosureKeys.anywayConfirm,
                label: t("share.trust.risky.share_anyway"),
                style: PillStyle.danger,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }
}

/// The room above a section label.
class _Gap extends StatelessWidget {
  final double height;
  const _Gap(this.height);

  static const section = _Gap(26);

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) =>
      CapsLabel(title, padding: const EdgeInsets.fromLTRB(4, 0, 4, 8));
}

class _WhiteCard extends StatelessWidget {
  final List<Widget> children;
  const _WhiteCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: YiviPalette.of(context).surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// One block of the list: the values of its cards, a hairline above it
/// ([line]), and for shared optional data the "Niet verplicht" chip.
class _ValueBlock extends StatelessWidget {
  final List<SelectableCredentialInstance> cards;
  final String requestor;
  final bool line;
  final bool chip;

  const _ValueBlock({
    required this.cards,
    required this.requestor,
    required this.line,
    required this.chip,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      decoration: line
          ? BoxDecoration(
              border: Border(top: BorderSide(color: palette.divider)),
            )
          : null,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chip)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: palette.tint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.tr("share.optional.chip"),
                  style: palette
                      .body(11.5, weight: FontWeight.w600)
                      .copyWith(height: 17 / 11.5, color: palette.text),
                ),
              ),
            ),
          for (final card in cards)
            DisclosureValueList(
              key: ValueKey(card.hash),
              card: card,
              requestor: requestor,
              foldable: true,
            ),
        ],
      ),
    );
  }
}

/// "Uit 2 kaartjes in je app · Wijzig ›": the cards the values come from,
/// fanned, and the one way to change.
class _PileRow extends StatelessWidget {
  final List<Credential> cards;
  final GlobalKey Function(String hash) keyOf;
  final String text;
  final String action;
  final VoidCallback? onTap;

  const _PileRow({
    required this.cards,
    required this.keyOf,
    required this.text,
    required this.action,
    required this.onTap,
  });

  /// Where each of up to four cards lies: offset and turn (degrees).
  static const _fan = [
    (Offset(-7, 1), -9.0),
    (Offset(-1, 0), -2.0),
    (Offset(5, 1), 5.0),
    (Offset(10, 2), 11.0),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final shown = cards.take(4).toList();
    return Semantics(
      button: onTap != null,
      label: "$text, $action",
      excludeSemantics: true,
      child: GestureDetector(
        key: DisclosureKeys.pile,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 4, 8),
            child: Row(
              spacing: YiviSpace.x12,
              children: [
                SizedBox(
                  width: 60,
                  height: 38,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final (i, card) in shown.indexed)
                        Positioned(
                          left: 8 + _fan[i].$1.dx,
                          top: 6 + _fan[i].$1.dy,
                          child: Transform.rotate(
                            angle: _fan[i].$2 * 3.14159265 / 180,
                            child: FlightSpot(
                              flightKey: keyOf(card.hash),
                              child: CredentialCardArt(
                                credential: card,
                                width: 40,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: palette
                        .body(14)
                        .copyWith(height: 20 / 14, color: palette.text),
                  ),
                ),
                Row(
                  key: DisclosureKeys.change,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 7,
                  children: [
                    Text(
                      action,
                      style: palette
                          .body(15, weight: FontWeight.w600)
                          .copyWith(color: palette.link),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: palette.link,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Je kunt nog één ding delen als je wil ›".
class _HintRow extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _HintRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = palette
        .body(14.5, weight: FontWeight.w600)
        .copyWith(height: 20 / 14.5, color: palette.link);
    return Semantics(
      button: onTap != null,
      label: text,
      excludeSemantics: true,
      child: GestureDetector(
        key: DisclosureKeys.optionalHint,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              spacing: 10,
              children: [
                Expanded(child: Text(text, style: style)),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: palette.link,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "{Requestor} bewaart": the names of the shared values the requestor
/// keeps, on a warm tint.
class _KeepCard extends StatelessWidget {
  final String head;
  final String names;
  const _KeepCard({required this.head, required this.names});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: DisclosureKeys.keepCard,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: palette.keepSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: YiviSpace.x12,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 22,
              color: palette.keepText,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  head,
                  style: palette
                      .display(15, weight: FontWeight.w600)
                      .copyWith(height: 21 / 15, color: palette.keepText),
                ),
                Text(
                  names,
                  style: palette
                      .body(14.5)
                      .copyWith(height: 21 / 14.5, color: palette.keepText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom of the overview: for a party nobody vouches for the reason in
/// red and a sober "Toch delen"; else the red button.
class _ShareBar extends StatelessWidget {
  final String? reason;
  final String label;
  final bool risky;
  final VoidCallback? onPressed;

  /// In a bar across the bottom; otherwise just its content (the panel).
  final bool inBar;

  const _ShareBar({
    required this.reason,
    required this.label,
    required this.risky,
    required this.onPressed,
    required this.inBar,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: YiviSpace.x8,
      children: [
        if (reason case final r?)
          Text(
            r,
            key: DisclosureKeys.reason,
            textAlign: TextAlign.center,
            style: palette
                .body(15, weight: FontWeight.w600)
                .copyWith(height: 20 / 15, color: palette.errorText),
          ),
        KeyedSubtree(
          key: DisclosureKeys.button,
          child: risky
              ? PillButton(
                  label: label,
                  style: PillStyle.neutral,
                  size: PillSize.large,
                  onPressed: onPressed,
                )
              : PrimaryPillButton(label: label, onPressed: onPressed),
        ),
      ],
    );
    return inBar ? ActionBar(actions: [content]) : content;
  }
}
