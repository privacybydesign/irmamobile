import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter/semantics.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../routing.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/credential_field_search.dart";
import "../../providers/credentials_search.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../providers/schemaless_credentials_provider.dart";
import "../../providers/search_query_provider.dart";
import "../../theme/theme.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_edges.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/i18n.dart";
import "../../util/instance_hint.dart";
import "../../util/navigation.dart";
import "../../widgets/app_toast.dart";
import "../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../widgets/credential_card/attribute_groups/attribute_value_formatting.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/floating_bar_placement.dart";
import "../../widgets/glass/glass_menu.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/glass/round_icon_button.dart";
import "../../widgets/press_scale.dart";
import "../../widgets/search_mark.dart";
import "../../widgets/slot_registry.dart";
import "../../widgets/tab_layout.dart";
import "../../widgets/title_scroll_edge.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/two_pane.dart";
import "../add_data/add_data_sheet.dart";
import "../home/widgets/home_tab_top.dart";
import "../home/widgets/search_scroll_edge.dart";
import "card_transition/card_transition.dart";
import "card_transition/card_transition_layer.dart";
import "card_transition/stack_cards.dart";
import "credential_detail/credential_detail_screen.dart";
import "empty_data_start.dart";
import "wallet/card_hero.dart";
import "wallet/drag_to_arrange.dart";
import "wallet/issuance_flight.dart";
import "wallet/wallet_transition.dart";
import "widgets/email_link_banner.dart";

part "card_views.dart";

/// Height of the floating search row at the top of the tab.
const double _topBarHeight = 48;

class DataTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<DataTab> with RouteAware {
  /// The search outlives this State ([dataSearchQueryProvider]): the tab is
  /// built anew when a card opened from the results closes.
  late String _query = ref.read(dataSearchQueryProvider);
  late final _search = TextEditingController(text: _query);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // As in Activity: a tap in the field switches to the search right away,
    // before anything is typed; Cancel ends it, losing focus does not.
    _focus.addListener(() {
      if (!_focus.hasFocus) return;
      ref.read(dataSearchActiveProvider.notifier).set(true);
    });
    // Built anew while a card opened from the search was open.
    _refocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context) case final PageRoute<dynamic> route) {
      routeObserver.subscribe(this, route);
    }
  }

  /// Back from a card opened while typing in the search: the keyboard comes
  /// back, to type on.
  @override
  void didPopNext() => _refocus();

  /// Gives the field the keyboard back when it had it as a card opened,
  /// once this page is on top again: the tab is also built anew while the
  /// card is still open, and then it waits for [didPopNext].
  void _refocus() => afterFrame(() {
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    if (!ref.read(dataSearchRefocusProvider)) return;
    ref.read(dataSearchRefocusProvider.notifier).set(false);
    _whenCardGone(_showKeyboard);
  });

  /// Runs [then] once the card above this page has finished going, looked
  /// at frame by frame: the route's animation does not report it.
  void _whenCardGone(VoidCallback then, {int frames = 120}) {
    final going = ModalRoute.of(context)?.secondaryAnimation;
    if (going == null || going.isDismissed || frames == 0) return then();
    afterFrame(() {
      if (mounted) _whenCardGone(then, frames: frames - 1);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// As the card goes, the page gives the field its focus back by itself,
  /// but without the keyboard, and asking a field that has the focus does
  /// not bring it up then (seen on iOS): the field lets go and is asked
  /// afresh, as a tap on it would.
  void _showKeyboard() {
    void ask() => _focus.context
        ?.findAncestorStateOfType<EditableTextState>()
        ?.requestKeyboard();
    if (!_focus.hasFocus) return ask();
    _focus.unfocus();
    afterFrame(() {
      if (mounted) ask();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() => _query = q);
    ref.read(dataSearchQueryProvider.notifier).set(q);
  }

  /// The field under the large title, or the bar's search button: search
  /// mode, with the field in the bar and the keyboard up.
  void _startSearching() {
    ref.read(dataSearchActiveProvider.notifier).set(true);
    afterFrame(() {
      if (mounted) _focus.requestFocus();
    });
  }

  void _stopSearching() {
    _search.clear();
    _focus.unfocus();
    _onQuery("");
    ref.read(dataSearchActiveProvider.notifier).set(false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final panes = useHomePanes(context);
    final top = panes
        ? padding.top + FloatingBarPlacement.topGap(context)
        : padding.top;
    // Next to a pane, and while searching, the list starts under the bar;
    // on a phone held upright its large title is on the bar's row.
    final topInset = panes
        ? top + _topBarHeight + 8
        : HomeTabTop.listTop(context);
    final searching =
        ref.watch(dataSearchActiveProvider) || _query.trim().isNotEmpty;

    // A card that opens in the detail pane (tapped, or picked among the
    // cards of its type in the pane) comes into view in the list: to the
    // middle when it was not all in view.
    ref.listen(selectedCardProvider, (_, hash) {
      if (hash == null || !useHomePanes(context)) return;
      afterFrame(() => _revealCard(context, hash, top: topInset));
    });

    final field = GlassSearchField(
      fieldKey: const Key("search_field"),
      hintKey: "wallet.search_placeholder",
      controller: _search,
      focusNode: _focus,
      onChanged: _onQuery,
      height: panes ? 48 : 44,
    );
    // Blue, as a plain action next to a field (the red is for the main one).
    final cancel = TextButton(
      key: const Key("data_search_cancel"),
      style: TextButton.styleFrom(foregroundColor: palette.link),
      onPressed: _stopSearching,
      child: Text(FlutterI18n.translate(context, "wallet.search_cancel")),
    );
    final add = RoundIconButton(
      key: const Key("data_tab_add_data"),
      icon: CupertinoIcons.add,
      label: FlutterI18n.translate(context, "wallet.add_data"),
      onTap: () => showAddDataSheet(context),
    );
    final content = _Content(
      query: _query,
      searching: searching,
      topInset: topInset,
      titleTop: HomeTabTop.titleTop(context),
      onStartSearch: panes ? null : _startSearching,
    );

    // Next to a pane: the field floats over the list, with + beside it.
    final list = panes
        ? SearchScrollEdge(
            height: top + _topBarHeight + 8,
            top: top,
            row: Row(
              spacing: 8,
              children: [
                Expanded(child: field),
                if (searching) cancel else add,
              ],
            ),
            child: content,
          )
        // A phone held upright: the large title scrolls under a solid bar,
        // with "…" at its left and + at its right.
        : HomeTabTop(
            title: FlutterI18n.translate(context, "home.nav_bar.data"),
            searching: searching,
            searchRow: Row(
              spacing: 4,
              children: [
                Expanded(child: field),
                cancel,
              ],
            ),
            searchButtonKey: const Key("data_search_button"),
            searchLabel: FlutterI18n.translate(
              context,
              "wallet.search_placeholder",
            ),
            onSearch: _startSearching,
            leading: const _ViewMenuButton(),
            // The + turns into the close button of a card that opens.
            trailingTurnsIntoClose: true,
            trailing: add,
            child: content,
          );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: palette.background,
      body: panes ? _withDetailPane(list) : list,
    );
  }

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
              found: switch (ref.watch(foundCardFieldProvider)) {
                (hash: final h, :final claimKey) when h == hash => claimKey,
                _ => null,
              },
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
  final bool searching;
  final double topInset;

  /// A phone held upright: the list starts with the large title and the
  /// search field, whose tap starts this.
  final VoidCallback? onStartSearch;

  /// Where the large title starts, on the bar's row ([onStartSearch]).
  final double titleTop;

  const _Content({
    required this.query,
    required this.searching,
    required this.topInset,
    this.titleTop = 0,
    this.onStartSearch,
  });

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
                searching: searching,
                topInset: topInset,
                titleTop: titleTop,
                onStartSearch: onStartSearch,
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

  /// From a tap in the search field until Cancel: the cards are list rows,
  /// all of them until something is typed.
  final bool searching;
  final double topInset;

  /// See [_Content.onStartSearch] and [_Content.titleTop].
  final VoidCallback? onStartSearch;
  final double titleTop;

  const _CardList({
    required this.cards,
    required this.problematic,
    required this.query,
    required this.searching,
    required this.topInset,
    required this.titleTop,
    this.onStartSearch,
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
    final hintTexts = instanceHintTexts(context, cards, hints);

    // While searching the results are always list rows, whatever view was
    // picked: only a row has room to say why a card matched. The view
    // itself is kept for when the search ends. Before anything is typed
    // every card shows, as a row.
    final typed = query.trim().isNotEmpty;
    final results = typed
        ? _search(context, cards, hintTexts, query)
        : const <CardSearchResult>[];
    final byHash = {for (final c in cards) c.hash: c};
    final visible = typed ? [for (final r in results) byHash[r.hash]!] : cards;
    final shownView = searching ? WalletView.list : view;
    // Dragging cards to another place only makes sense with all of them
    // shown, and not while a received card flies in.
    final arrangeable = !searching && IssuanceFlight.state.value == null;
    final bottom =
        MediaQuery.paddingOf(context).bottom + bottomBarSpace(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = min(
          constraints.maxWidth - 32,
          mediumContentMaxWidth,
        );
        final side = (constraints.maxWidth - contentWidth) / 2;
        // The stack is as wide as the rest (the search field, the rows of
        // the list): one edge down the page. Next to a detail pane it is 16
        // narrower than the column: the card open in the pane slides that
        // far to the right, out of the stack.
        final panes = useHomePanes(context);
        // The card the detail pane shows, followed as the pick changes.
        final openHash = panes
            ? _paneCardHash(ref.watch(selectedCardProvider), this.cards)
            : null;
        final stackWidth = panes
            ? contentWidth - _StackView.nudge
            : contentWidth;
        final stackPadding = panes
            ? EdgeInsets.only(left: side, right: side + _StackView.nudge)
            : EdgeInsets.symmetric(horizontal: side);

        Widget box(Widget child) => SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: side),
          sliver: SliverToBoxAdapter(child: child),
        );

        return CustomScrollView(
          key: const Key("wallet_scroll"),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: !searching && onStartSearch != null
                    ? titleTop
                    : topInset,
              ),
            ),
            if (!searching && onStartSearch != null)
              box(
                PushAway(
                  direction: PushAwayDirection.up,
                  child: CardTransitionFade(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HomeTabHeader(
                        title: const TabLargeTitle("wallet.title"),
                        field: HomeTabSearchField(
                          key: const Key("search_field"),
                          hint: context.tr("wallet.search_placeholder"),
                          onTap: onStartSearch!,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!searching && ref.watch(emailBannerVisibleProvider))
              box(
                const PushAway(
                  direction: PushAwayDirection.up,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: EmailLinkBanner(),
                  ),
                ),
              ),
            // Next to a pane; on a phone held upright the view menu is in the
            // bar's top left.
            if (!searching && onStartSearch == null)
              box(
                PushAway(
                  direction: PushAwayDirection.up,
                  // In line with the search field above it, in every view.
                  child: _Header(count: cards.length, view: view),
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
                padding: shownView == WalletView.stack
                    ? stackPadding
                    : EdgeInsets.symmetric(horizontal: side),
                sliver: switch (shownView) {
                  WalletView.stack => SliverToBoxAdapter(
                    child: _StackView(
                      cards: visible,
                      hintTexts: hintTexts,
                      width: stackWidth,
                      arrangeable: arrangeable,
                      openHash: openHash,
                    ),
                  ),
                  WalletView.list => SliverToBoxAdapter(
                    child: _ListView(
                      cards: visible,
                      hintTexts: hintTexts,
                      width: contentWidth,
                      arrangeable: arrangeable,
                      query: query,
                      results: {for (final r in results) r.hash: r},
                      openHash: openHash,
                    ),
                  ),
                  WalletView.grid => SliverToBoxAdapter(
                    child: _GridView(
                      cards: visible,
                      hintTexts: hintTexts,
                      width: contentWidth,
                      arrangeable: arrangeable,
                      openHash: openHash,
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

  /// The cards [query] finds, best first, each with the fields it matched.
  static List<CardSearchResult> _search(
    BuildContext context,
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
    return rankCards(
      order: [for (final c in cards) c.hash],
      byName: [for (final e in searchCredentials(entries, query)) e.hash],
      fields: {for (final c in cards) c.hash: _searchFields(context, c)},
      query: query,
    );
  }

  /// The fields of [credential] the search looks in: every attribute with a
  /// value, by its label and its value as the card shows it. Yes/no values
  /// and images are found by their label only.
  static List<SearchField> _searchFields(
    BuildContext context,
    schemaless.Credential credential,
  ) => [
    for (final a in credential.attributes)
      if (a.value case final value? when value.hasConcreteValue)
        SearchField(
          claimKey: claimPathKey(a.claimPath),
          label: a.effectiveDisplayName,
          value: switch (value.type) {
            schemaless.AttributeType.string ||
            schemaless.AttributeType.integer => formatAttributeValue(
              context,
              value,
            ),
            _ => null,
          },
        ),
  ];
}

/// Opens the detail view of [credential], starting the Wallet-style
/// transition from [cardContext] (the tapped card).
/// [found]: the field (a claim path key) a search found it by; it opens on
/// that field.
void openCard(
  BuildContext cardContext,
  schemaless.Credential credential, {
  String? found,
}) {
  final container = ProviderScope.containerOf(cardContext, listen: false);
  container
      .read(foundCardFieldProvider.notifier)
      .select(found == null ? null : (hash: credential.hash, claimKey: found));
  if (useHomePanes(cardContext)) {
    // The tablet and landscape layouts show the card in the detail pane
    // next to the list.
    container.read(selectedCardProvider.notifier).select(credential.hash);
    return;
  }
  // Opened while typing in the search (the keyboard is still on its way
  // down): it comes back with the search when the card closes.
  container
      .read(dataSearchRefocusProvider.notifier)
      .set(
        container.read(dataSearchActiveProvider) &&
            View.of(cardContext).viewInsets.bottom > 0,
      );
  // One card at a time: a tap while one opens or closes does nothing.
  final transitions = CardTransitionScope.maybeOf(cardContext);
  if (transitions != null && transitions.busy) return;
  if (transitions != null &&
      !MediaQuery.disableAnimationsOf(cardContext) &&
      _openFromStack(cardContext, transitions, credential, found)) {
    return;
  }
  WalletTransition.begin(cardContext, credential.hash);
  cardContext.pushCredentialDetailScreen(credential.hash, found: found);
}

/// Opens [credential] from the stack with its card transition: its details
/// come over the home screen at once, the card where it was tapped, and
/// stay there while it is open. False when the card is not in the stack
/// (another view) or the stack is not measured.
bool _openFromStack(
  BuildContext cardContext,
  CardTransitionsState transitions,
  schemaless.Credential credential,
  String? found,
) {
  final picked = StackCards.hashes.indexOf(credential.hash);
  if (picked < 0) return false;
  final snapshot = StackCards.snapshot(cardContext, picked);
  if (snapshot == null) return false;
  return transitions.open(
    snapshot: snapshot,
    list: Scrollable.maybeOf(cardContext)?.position,
    details: (context, transition) => CredentialDetailScreen(
      hash: credential.hash,
      found: found,
      transition: transition,
    ),
  );
}

/// "16 cards", and the menu that picks the view and arranges the cards.
class _Header extends StatelessWidget {
  final int count;
  final WalletView view;

  const _Header({required this.count, required this.view});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              FlutterI18n.plural(context, "wallet.count", count),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette.display(14).copyWith(color: palette.secondaryText),
            ),
          ),
          // Nothing to arrange with one card: the views only.
          _ViewMenu(view: view, arrangeable: count > 1),
        ],
      ),
    );
  }
}

/// The view (Stack, List, Grid) and "Arrange" in one menu, under a button
/// that says which view is shown. Arranging tidies the cards up once, by
/// name, newest first or by issuer: there is one order, the user's, and
/// what comes out is simply that, to drag on from. A toast says what
/// happened and can undo it.
class _ViewMenu extends ConsumerWidget {
  final WalletView view;
  final bool arrangeable;

  const _ViewMenu({required this.view, required this.arrangeable});

  static const _viewIcons = {
    WalletView.stack: Icons.view_agenda_outlined,
    WalletView.list: Icons.view_list_rounded,
    WalletView.grid: Icons.grid_view_rounded,
  };

  static const _arrangeIcons = {
    CardArrangement.name: Icons.sort_by_alpha_rounded,
    CardArrangement.newest: Icons.schedule_rounded,
    CardArrangement.issuer: Icons.account_balance_outlined,
  };

  Future<void> _open(BuildContext context, WidgetRef ref) =>
      open(context, ref, view: view, arrangeable: arrangeable);

  /// The menu, under the button at [context].
  static Future<void> open(
    BuildContext context,
    WidgetRef ref, {
    required WalletView view,
    required bool arrangeable,
  }) async {
    final picked = await showGlassMenu<Object>(
      context,
      items: [
        for (final (i, v) in WalletView.values.indexed)
          GlassMenuItem(
            key: Key("wallet_view_${v.name}"),
            value: v,
            label: context.tr("wallet.view.${v.name}"),
            icon: _viewIcons[v]!,
            section: i == 0 ? context.tr("wallet.view.label") : null,
            checked: v == view,
          ),
        if (arrangeable)
          for (final (i, way) in CardArrangement.values.indexed)
            GlassMenuItem(
              key: Key("wallet_arrange_${way.name}"),
              value: way,
              label: context.tr("wallet.arrange.${way.name}"),
              icon: _arrangeIcons[way]!,
              section: i == 0 ? context.tr("wallet.arrange.button") : null,
            ),
      ],
      footnote: arrangeable ? context.tr("wallet.arrange.hint") : null,
    );
    if (!context.mounted) return;
    switch (picked) {
      case final WalletView v:
        ref.read(walletViewProvider.notifier).set(v);
      case final CardArrangement by:
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final label = context.tr("wallet.view.${view.name}");
    return Semantics(
      button: true,
      label: "${context.tr("wallet.view.label")}: $label",
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key("wallet_arrange"),
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, ref),
        child: PressScale(
          // A finger's room around the 36 high pill.
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              height: 36,
              padding: const EdgeInsetsDirectional.only(start: 10, end: 8),
              decoration: ShapeDecoration(
                color: palette.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  side: BorderSide(color: palette.divider),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(_viewIcons[view], size: 18, color: palette.text),
                  Text(
                    label,
                    maxLines: 1,
                    style: palette.display(14).copyWith(color: palette.text),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: palette.text,
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

/// The view menu's button at the top left of the phone's bar: "…", for the
/// view (Stack, List, Grid) and arranging the cards. Nothing without cards.
class _ViewMenuButton extends ConsumerWidget {
  const _ViewMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(walletCardsProvider).length;
    if (count == 0) return const SizedBox.shrink();
    final view = ref.watch(walletViewProvider) ?? WalletView.stack;
    return RoundIconButton(
      key: const Key("wallet_arrange"),
      icon: CupertinoIcons.ellipsis,
      label:
          "${context.tr("wallet.view.label")}: "
          "${context.tr("wallet.view.${view.name}")}",
      onTap: () =>
          _ViewMenu.open(context, ref, view: view, arrangeable: count > 1),
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
