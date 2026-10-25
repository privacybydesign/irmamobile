import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/semantics.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/credentials_search.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../providers/schemaless_credentials_provider.dart";
import "../../providers/search_query_provider.dart";
import "../../theme/theme.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_shadows.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/i18n.dart";
import "../../util/instance_hint.dart";
import "../../util/navigation.dart";
import "../../widgets/app_toast.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/glass/floating_bar_placement.dart";
import "../../widgets/glass/glass_menu.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/glass/search_scroll_edge.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/two_pane.dart";
import "../add_data/add_data_sheet.dart";
import "credential_detail/credential_detail_screen.dart";
import "empty_data_start.dart";
import "wallet/card_hero.dart";
import "wallet/drag_to_arrange.dart";
import "wallet/issuance_flight.dart";
import "wallet/wallet_transition.dart";
import "widgets/email_link_banner.dart";

/// Height of the floating search row at the top of the tab.
const double _topBarHeight = 48;

class DataTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<DataTab> {
  /// The search outlives this State ([dataSearchQueryProvider]): the tab is
  /// built anew when a card opened from the results closes.
  late String _query = ref.read(dataSearchQueryProvider);
  late final _search = TextEditingController(text: _query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() => _query = q);
    ref.read(dataSearchQueryProvider.notifier).set(q);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final top = padding.top + FloatingBarPlacement.topGap(context);
    final topInset = top + _topBarHeight + 8;

    // A card that opens in the detail pane (tapped, or picked among the
    // cards of its type in the pane) comes into view in the list: to the
    // middle when it was not all in view.
    ref.listen(selectedCardProvider, (_, hash) {
      if (hash == null || !_withPane(context)) return;
      afterFrame(() => _revealCard(context, hash, top: topInset));
    });

    // The cards scroll under the floating search row; the edge goes away
    // with the row when a card opens.
    final list = SearchScrollEdge(
      height: top + _topBarHeight + 8,
      top: top,
      row: Row(
        spacing: 8,
        children: [
          Expanded(
            child: GlassSearchField(
              fieldKey: const Key("search_field"),
              hintKey: "wallet.search_placeholder",
              controller: _search,
              onChanged: _onQuery,
            ),
          ),
          GlassIconButton(
            key: const Key("data_tab_add_data"),
            size: 48,
            semanticsLabel: FlutterI18n.translate(context, "wallet.add_data"),
            icon: Icon(Icons.add, size: 26, color: palette.text),
            onTap: () => showAddDataSheet(context),
          ),
        ],
      ),
      child: _Content(query: _query, topInset: topInset),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: palette.background,
      body: _withPane(context) ? _withDetailPane(list) : list,
    );
  }

  /// Whether the cards sit next to a detail pane: on a tablet, and on a
  /// phone held sideways. Without cards the pane offers the ways to get
  /// started.
  bool _withPane(BuildContext context) => useHomePanes(context);

  /// The tablet layout: the cards next to the details of the open card
  /// (the first card until the user picks one).
  Widget _withDetailPane(Widget list) {
    final cards = ref.watch(walletCardsProvider);
    final hash = _paneCardHash(ref.watch(selectedCardProvider), cards);
    final selection = ref.read(selectedCardProvider.notifier);
    return TwoPane(
      list: list,
      placeholder: const EmptyDataPane(),
      detail: hash == null
          ? null
          : CredentialDetailPane(
              key: ValueKey(hash),
              hash: hash,
              onSwitch: selection.select,
              onDeleted: () => selection.select(null),
            ),
    );
  }
}

/// Brings the card [hash] into view in the list next to the detail pane:
/// when part of it (or of its strip, in the stack) is under the search row
/// at the top ([top] high) or the bottom, or off screen, the list scrolls
/// it to the middle of what is in view. A card not built yet (far down a
/// long list or grid) is first scrolled to by its place in the list.
void _revealCard(
  BuildContext context,
  String hash, {
  required double top,
  bool again = true,
}) {
  final card = _CardButtonState.shown[hash];
  final cardBox = card?.context.findRenderObject();
  if (card == null || cardBox is! RenderBox || !cardBox.hasSize) {
    if (again) _scrollTowards(context, hash, top: top);
    return;
  }
  final scrollable = Scrollable.maybeOf(card.context);
  final viewBox = scrollable?.context.findRenderObject();
  if (scrollable == null || viewBox is! RenderBox) return;
  final position = scrollable.position;
  final view = viewBox.localToGlobal(Offset.zero) & viewBox.size;
  final bottom = MediaQuery.paddingOf(context).bottom + bottomBarSpace(context);
  final visible = Rect.fromLTRB(
    view.left,
    view.top + top,
    view.right,
    view.bottom - bottom,
  );
  final origin = cardBox.localToGlobal(Offset.zero);
  final target = Rect.fromLTWH(
    origin.dx,
    origin.dy,
    cardBox.size.width,
    min(card.widget.revealHeight ?? cardBox.size.height, cardBox.size.height),
  );
  if (target.top >= visible.top && target.bottom <= visible.bottom) return;
  final to = (position.pixels + target.center.dy - visible.center.dy).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if (MediaQuery.disableAnimationsOf(context)) {
    position.jumpTo(to);
  } else {
    position.animateTo(
      to,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }
}

/// A card that is not built yet: jumps the list to about where it is (by
/// its place among the cards built), then reveals it properly.
void _scrollTowards(BuildContext context, String hash, {required double top}) {
  final built = _CardButtonState.shown.values.where((s) => s.mounted).toList();
  if (built.isEmpty) return;
  final scrollable = Scrollable.maybeOf(built.first.context);
  if (scrollable == null) return;
  final cards = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(walletCardsProvider);
  final index = cards.indexWhere((c) => c.hash == hash);
  if (index < 0) return;
  // The built cards' places and offsets give the room one card takes.
  final placed = <(int, double)>[
    for (final s in built)
      if (cards.indexWhere((c) => c.hash == s.widget.credential.hash)
          case final i when i >= 0)
        if (s.context.findRenderObject() case final RenderBox box
            when box.hasSize)
          (i, box.localToGlobal(Offset.zero).dy),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  if (placed.length < 2) return;
  final (firstIndex, firstY) = placed.first;
  final (lastIndex, lastY) = placed.last;
  if (lastIndex == firstIndex) return;
  final perCard = (lastY - firstY) / (lastIndex - firstIndex);
  final position = scrollable.position;
  final targetY = firstY + (index - firstIndex) * perCard;
  final viewBox = scrollable.context.findRenderObject();
  if (viewBox is! RenderBox) return;
  final viewTop = viewBox.localToGlobal(Offset.zero).dy;
  position.jumpTo(
    (position.pixels + targetY - viewTop - viewBox.size.height / 2).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) _revealCard(context, hash, top: top, again: false);
  });
}

class _Content extends ConsumerWidget {
  final String query;
  final double topInset;

  const _Content({required this.query, required this.topInset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final snapshot = ref.watch(schemalessCredentialsProvider);
    final ordered = ref.watch(schemalessCredentialOrderControllerProvider);

    return switch ((snapshot, ordered)) {
      (AsyncError(), _) || (_, AsyncError()) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TranslatedText(
            "error.title",
            textAlign: TextAlign.center,
            style: palette.body(16),
          ),
        ),
      ),
      (AsyncData(value: final snap), AsyncData(value: final cards)) =>
        // Problematic credentials keep the overview non-empty even when every
        // loadable credential is gone, so the user can still see and delete them.
        cards.isEmpty && snap.problematic.isEmpty
            ? Padding(
                padding: EdgeInsets.only(top: topInset),
                child: Column(
                  children: [
                    if (ref.watch(emailBannerVisibleProvider))
                      const EmailLinkBanner(),
                    Expanded(
                      // Next to the pane only the title; the pane has the
                      // ways to get started.
                      child: useHomePanes(context)
                          // In the upper half: the Scan tip shows beside the
                          // rail's Scan button, low in the column.
                          ? const Align(
                              alignment: Alignment(0, -0.5),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: EmptyDataTitle(),
                              ),
                            )
                          : const EmptyDataStart(),
                    ),
                  ],
                ),
              )
            : _CardList(
                cards: cards,
                problematic: snap.problematic,
                query: query,
                topInset: topInset,
              ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// The cards, in the view the user picked.
class _CardList extends ConsumerWidget {
  final List<schemaless.Credential> cards;
  final List<schemaless.ProblematicCredential> problematic;
  final String query;
  final double topInset;

  const _CardList({
    required this.cards,
    required this.problematic,
    required this.query,
    required this.topInset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // While a received card flies in, it joins the list a little late.
    return ValueListenableBuilder<IssuanceFlightState?>(
      valueListenable: IssuanceFlight.state,
      builder: (context, flight, _) =>
          _build(context, ref, withoutIncomingCard(cards, flight)),
    );
  }

  Widget _build(
    BuildContext context,
    WidgetRef ref,
    List<schemaless.Credential> cards,
  ) {
    final palette = YiviPalette.of(context);
    final hints = ref.watch(instanceHintsProvider);
    final view = ref.watch(walletViewProvider) ?? WalletView.stack;
    final hintTexts = {
      for (final c in cards)
        c.hash: instanceHintText(context, hints[c.hash] ?? const NoHint()),
    };

    final visible = query.trim().isEmpty
        ? cards
        : _search(cards, hintTexts, query);
    // Dragging cards to another place only makes sense with all of them
    // shown, and not while a received card flies in.
    final arrangeable =
        visible.length == cards.length && IssuanceFlight.state.value == null;
    final bottom =
        MediaQuery.paddingOf(context).bottom + bottomBarSpace(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = min(
          constraints.maxWidth - 32,
          mediumContentMaxWidth,
        );
        final side = (constraints.maxWidth - contentWidth) / 2;
        // The stack sits a little further in than the rest (1.5 times the
        // side), so its cards are a little smaller. Next to a detail pane
        // it is 16 narrower than the column instead: the card open in the
        // pane slides that far to the right, out of the stack.
        final panes = useHomePanes(context);
        final stackWidth = panes
            ? contentWidth - _StackView.nudge
            : min(constraints.maxWidth - 48, mediumContentMaxWidth);
        final stackSide = (constraints.maxWidth - stackWidth) / 2;
        final stackPadding = panes
            ? EdgeInsets.only(left: side, right: side + _StackView.nudge)
            : EdgeInsets.symmetric(horizontal: stackSide);

        Widget box(Widget child) => SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: side),
          sliver: SliverToBoxAdapter(child: child),
        );

        return CustomScrollView(
          key: const Key("wallet_scroll"),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: topInset)),
            if (ref.watch(emailBannerVisibleProvider))
              box(
                const PushAway(
                  direction: PushAwayDirection.up,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: EmailLinkBanner(),
                  ),
                ),
              ),
            box(
              PushAway(
                direction: PushAwayDirection.up,
                // Above the stack on a phone held upright, which sits further
                // in, the arrange button lines up with the search icon.
                child: _Header(
                  arrangeable: cards.length > 1,
                  view: view,
                  start: view == WalletView.stack && !panes
                      ? GlassSearchField.iconInset
                      : 0,
                ),
              ),
            ),
            for (final pc in problematic)
              box(
                PushAway(
                  direction: PushAwayDirection.up,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ProblematicCredentialCard(credential: pc),
                  ),
                ),
              ),
            if (visible.isEmpty)
              box(_NoResults(palette: palette))
            else
              SliverPadding(
                padding: view == WalletView.stack
                    ? stackPadding
                    : EdgeInsets.symmetric(horizontal: side),
                sliver: switch (view) {
                  WalletView.stack => SliverToBoxAdapter(
                    child: _StackView(
                      cards: visible,
                      hintTexts: hintTexts,
                      width: stackWidth,
                      arrangeable: arrangeable,
                      openHash: panes ? _openInPane(ref, cards) : null,
                    ),
                  ),
                  WalletView.list => SliverToBoxAdapter(
                    child: _ListView(
                      cards: visible,
                      hintTexts: hintTexts,
                      width: contentWidth,
                      arrangeable: arrangeable,
                    ),
                  ),
                  WalletView.grid => SliverToBoxAdapter(
                    child: _GridView(
                      cards: visible,
                      hintTexts: hintTexts,
                      width: contentWidth,
                      arrangeable: arrangeable,
                    ),
                  ),
                },
              ),
            SliverToBoxAdapter(child: SizedBox(height: bottom)),
          ],
        );
      },
    );
  }

  static List<schemaless.Credential> _search(
    List<schemaless.Credential> cards,
    Map<String, String> hintTexts,
    String query,
  ) {
    final entries = cards
        .map(
          (c) => SearchEntry(
            hash: c.hash,
            credentialType: normaliseForSearch(
              "${c.name} ${hintTexts[c.hash]}",
            ),
            issuerName: normaliseForSearch(c.issuer.name),
          ),
        )
        .toList();
    final byHash = {for (final c in cards) c.hash: c};
    return searchCredentials(
      entries,
      query,
    ).map((e) => byHash[e.hash]!).toList();
  }
}

/// Opens the detail view of [credential], starting the Wallet-style
/// transition from [cardContext] (the tapped card).
void openCard(BuildContext cardContext, schemaless.Credential credential) {
  if (useHomePanes(cardContext)) {
    // The tablet and landscape layouts show the card in the detail pane
    // next to the list.
    ProviderScope.containerOf(
      cardContext,
      listen: false,
    ).read(selectedCardProvider.notifier).select(credential.hash);
    return;
  }
  WalletTransition.begin(cardContext, credential.hash);
  cardContext.pushCredentialDetailScreen(credential.hash);
}

class _Header extends ConsumerWidget {
  /// Whether there is anything to arrange: more than one card.
  final bool arrangeable;
  final WalletView view;

  /// How far in the arrange button starts: where the cards do.
  final double start;

  const _Header({
    required this.arrangeable,
    required this.view,
    this.start = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nearer the cards than the search row above it: both are about how
    // the cards are shown, their order and their view.
    return Padding(
      padding: EdgeInsetsDirectional.only(start: start, top: 12, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: arrangeable ? const _ArrangeButton() : null,
            ),
          ),
          ViewSwitcher(
            view: view,
            // The narrow list beside the pane of a phone held sideways.
            compact: usePhoneLandscape(context),
            onChanged: (v) => ref.read(walletViewProvider.notifier).set(v),
          ),
        ],
      ),
    );
  }
}

/// "Arrange": a menu that tidies the cards up once, by name, newest first or
/// by issuer. There is one order, the user's: what comes out is simply
/// that, to drag on from. A toast says what happened and can undo it.
class _ArrangeButton extends ConsumerWidget {
  const _ArrangeButton();

  static const _icons = {
    CardArrangement.name: Icons.sort_by_alpha_rounded,
    CardArrangement.newest: Icons.schedule_rounded,
    CardArrangement.issuer: Icons.account_balance_outlined,
  };

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final by = await showGlassMenu<CardArrangement>(
      context,
      items: [
        for (final way in CardArrangement.values)
          GlassMenuItem(
            key: Key("wallet_arrange_${way.name}"),
            value: way,
            label: context.tr("wallet.arrange.${way.name}"),
            icon: _icons[way]!,
          ),
      ],
      footnote: context.tr("wallet.arrange.hint"),
    );
    if (by == null || !context.mounted) return;
    final order = ref.read(
      schemalessCredentialOrderControllerProvider.notifier,
    );
    final before = order.arrange(by);
    HapticFeedback.mediumImpact();
    showAppToast(
      context,
      context.tr("wallet.arrange.done_${by.name}"),
      key: const Key("wallet_arrange_toast"),
      overTabBar: true,
      action: (
        label: context.tr("wallet.arrange.undo"),
        onTap: () => order.restore(before),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final style = palette.display(14).copyWith(color: palette.heading);
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const Key("wallet_arrange"),
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, ref),
        child: PressScale(
          child: ConstrainedBox(
            // A finger's room, though the text is small.
            constraints: const BoxConstraints(minHeight: 44),
            // Smaller rather than cut off when the view switch leaves
            // little room (large text, a narrow phone).
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Icon(Icons.swap_vert_rounded, size: 18, color: style.color),
                  const SizedBox(width: 2),
                  Text(
                    context.tr("wallet.arrange.button"),
                    maxLines: 1,
                    style: style,
                  ),
                  Icon(Icons.expand_more_rounded, size: 18, color: style.color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Stack / List / Grid switch.
class ViewSwitcher extends StatelessWidget {
  final WalletView view;
  final ValueChanged<WalletView> onChanged;

  /// Icons only, without their names (still read by a screen reader).
  final bool compact;

  const ViewSwitcher({
    super.key,
    required this.view,
    required this.onChanged,
    this.compact = false,
  });

  static const _icons = {
    WalletView.stack: Icons.view_agenda_outlined,
    WalletView.list: Icons.view_list_rounded,
    WalletView.grid: Icons.grid_view_rounded,
  };

  /// A segment's width: padding, the icon, and its name when not [compact].
  double _widthOf(BuildContext context, String label) {
    if (compact) return _Segment.minWidth;
    final palette = YiviPalette.of(context);
    final text = TextPainter(
      text: TextSpan(text: label, style: palette.display(12)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return max(
      _Segment.minWidth,
      (2 * _Segment.padding + _Segment.icon + _Segment.gap + text.width)
          .ceilToDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final labels = {
      for (final v in WalletView.values)
        v: FlutterI18n.translate(context, "wallet.view.${v.name}"),
    };
    final widths = [
      for (final v in WalletView.values) _widthOf(context, labels[v]!),
    ];
    final index = WalletView.values.indexOf(view);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final before = widths.take(index).fold(0.0, (a, w) => a + w);
    final total = widths.fold(0.0, (a, w) => a + w);
    final start = rtl ? total - before - widths[index] : before;
    // As the tab bar: one choice marker that slides to the picked view.
    // Its edges overshoot each on their own but stop at the ends of the
    // switch, so at an end it squashes a little instead of being cut off.
    final segments = SizedBox(
      width: total,
      height: _Segment.height,
      child: Stack(
        children: [
          TweenAnimationBuilder<Offset>(
            duration: YiviMotion.duration(
              context,
              const Duration(milliseconds: 360),
            ),
            curve: YiviMotion.overshoot,
            tween: Tween(end: Offset(start, start + widths[index])),
            builder: (context, edges, child) {
              final left = edges.dx.clamp(0.0, total);
              final right = edges.dy.clamp(left, total);
              return Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: right - left,
                child: child!,
              );
            },
            child: DecoratedBox(
              key: const Key("wallet_view_marker"),
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: palette.isDark ? palette.lens : palette.heading,
                shadows: palette.isDark ? YiviShadows.lens : null,
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, v) in WalletView.values.indexed)
                _Segment(
                  key: Key("wallet_view_${v.name}"),
                  label: labels[v]!,
                  icon: _icons[v]!,
                  width: widths[i],
                  selected: v == view,
                  compact: compact,
                  onTap: () => onChanged(v),
                ),
            ],
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: FlutterI18n.translate(context, "wallet.view.label"),
      // Dark: glass with a lens on the choice, as the tab bar.
      child: palette.isDark
          ? GlassSurface(padding: const EdgeInsets.all(3), child: segments)
          : Container(
              padding: const EdgeInsets.all(3),
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: palette.outline)),
                color: palette.surface,
              ),
              child: segments,
            ),
    );
  }
}

/// One choice of [ViewSwitcher]: its icon and name over the sliding
/// marker, in the marker's ink while it is the choice.
class _Segment extends StatelessWidget {
  static const double height = 36;
  static const double minWidth = 44;
  static const double padding = 12;
  static const double icon = 16;
  static const double gap = 6;

  final String label;
  final IconData iconData;
  final double width;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _Segment({
    super.key,
    required this.label,
    required IconData icon,
    required this.width,
    required this.selected,
    required this.compact,
    required this.onTap,
  }) : iconData = icon;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final dark = palette.isDark;
    final fg = selected
        ? (dark ? palette.selectedTab : palette.surface)
        : palette.heading;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PressScale(
          child: SizedBox(
            width: width,
            height: height,
            // The ink follows the marker: it changes as the marker comes.
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: fg),
              duration: YiviMotion.duration(
                context,
                const Duration(milliseconds: 200),
              ),
              builder: (context, color, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: gap,
                children: [
                  Icon(iconData, size: icon, color: color),
                  if (!compact)
                    Text(
                      label,
                      maxLines: 1,
                      style: palette.display(12).copyWith(color: color),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The cards overlap, each showing a strip of [_stripHeight]; the last one is
/// shown in full. Hold a card to drag it to another place.
class _StackView extends ConsumerWidget {
  static const double _stripHeight = 64;

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
    final onMove = ref
        .read(schemalessCredentialOrderControllerProvider.notifier)
        .reorder;
    return DragToArrange(
      keys: [for (final c in cards) c.hash],
      size: Size(width, (cards.length - 1) * _stripHeight + cardHeight),
      slotWidth: width,
      slot: (i) => Offset(0, i * _stripHeight),
      indexAt: (at) => (at.dy / _stripHeight).round(),
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
                  child: CardHero(
                    credential: c,
                    width: width,
                    hintText: hintTexts[c.hash],
                    edge: true,
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

/// The card the detail pane shows, followed as the pick changes.
String? _openInPane(WidgetRef ref, List<schemaless.Credential> cards) =>
    _paneCardHash(ref.watch(selectedCardProvider), cards);

/// A row a card: its picture, name, hint and issuer. Hold a row to drag it
/// to another place.
class _ListView extends ConsumerWidget {
  static const double gap = 8;

  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final double width;
  final bool arrangeable;

  const _ListView({
    required this.cards,
    required this.hintTexts,
    required this.width,
    required this.arrangeable,
  });

  /// The height of every row: its picture, or its three lines of text when
  /// they are taller (large text), and its padding. One height for all, so
  /// the rows have fixed places to be dragged between; a row without a hint
  /// has its text in the middle.
  static double rowHeight(BuildContext context) {
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
        line(palette.body(12));
    return 2 * _ListRow.padding +
        max(
          _ListRow.picture / CredentialCardArt.aspectRatio,
          text,
        ).ceilToDouble();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onMove = ref
        .read(schemalessCredentialOrderControllerProvider.notifier)
        .reorder;
    final row = rowHeight(context);
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
              flightTarget: i == 0,
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

/// Whether [credential] is the card shown in the tablet detail pane.
bool _isOpenInPane(BuildContext context, schemaless.Credential credential) {
  if (!useHomePanes(context)) return false;
  final container = ProviderScope.containerOf(context);
  final selected = container.read(selectedCardProvider);
  final cards = container.read(walletCardsProvider);
  return _paneCardHash(selected, cards) == credential.hash;
}

class _ListRow extends StatelessWidget {
  /// The width of its card picture, and the room around it.
  static const double picture = 88;
  static const double padding = 8;

  final schemaless.Credential credential;
  final String? hintText;

  /// The thumbnail is where a received card lands.
  final bool flightTarget;

  /// The screen reader's ways to move it ([moveActions]).
  final Map<CustomSemanticsAction, VoidCallback>? moves;

  const _ListRow({
    required this.credential,
    this.hintText,
    this.flightTarget = false,
    this.moves,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final selected = _isOpenInPane(context, credential);
    return _CardButton(
      credential: credential,
      hintText: hintText,
      pressDepth: 4,
      moves: moves,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: YiviCorners.cardRadius,
          side: BorderSide(
            width: 2,
            color: selected ? palette.primary : Colors.transparent,
          ),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
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
                    Text(
                      credential.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.display(16).copyWith(color: palette.text),
                    ),
                    if ((hintText ?? "").isNotEmpty)
                      Text(
                        hintText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: palette.body(14),
                      ),
                    Text(
                      credential.issuer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: palette.body(12).copyWith(color: palette.heading),
                    ),
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

  const _GridView({
    required this.cards,
    required this.hintTexts,
    required this.width,
    required this.arrangeable,
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
    final onMove = ref
        .read(schemalessCredentialOrderControllerProvider.notifier)
        .reorder;
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
                            color: _isOpenInPane(context, c)
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

  const _CardButton({
    required this.credential,
    required this.child,
    this.hintText,
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
        onTap: () => openCard(context, credential),
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

class _NoResults extends StatelessWidget {
  final YiviPalette palette;

  const _NoResults({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          TranslatedText(
            "wallet.no_results.title",
            textAlign: TextAlign.center,
            style: palette.display(16),
          ),
          const SizedBox(height: 4),
          TranslatedText(
            "wallet.no_results.body",
            textAlign: TextAlign.center,
            style: palette.body(14).copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// A card for a credential the wallet stored but cannot render (see
/// [schemaless.ProblematicCredential]). Shown in a danger style with the failure
/// reason and a trashcan to remove a credential that would otherwise be stuck in
/// storage — it has no detail screen to route to, so deletion is inline.
class _ProblematicCredentialCard extends ConsumerWidget {
  const _ProblematicCredentialCard({required this.credential});

  final schemaless.ProblematicCredential credential;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final palette = YiviPalette.of(context);
    final title = FlutterI18n.translate(context, "data.problematic.title");

    return Material(
      color: palette.errorSurface,
      shape: const RoundedRectangleBorder(borderRadius: YiviCorners.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: palette.danger, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: palette.display(16).copyWith(color: palette.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FlutterI18n.translate(
                      context,
                      "data.problematic.explanation",
                    ),
                    style: palette.body(14).copyWith(color: palette.heading),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    credential.reason,
                    style: palette.body(12).copyWith(color: palette.heading),
                  ),
                ],
              ),
            ),
            SizedBox(width: theme.smallSpacing),
            PlainIconButton(
              key: Key("${credential.credentialId ?? "problematic"}_delete"),
              icon: Icons.delete_outline_rounded,
              danger: true,
              semanticsLabel: FlutterI18n.translate(
                context,
                "accessibility.remove",
              ),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDeleteCredential(context);
    if (confirmed && context.mounted) {
      ref
          .read(irmaRepositoryProvider)
          .deleteCredential(credential.credentialInstanceIds);
    }
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
