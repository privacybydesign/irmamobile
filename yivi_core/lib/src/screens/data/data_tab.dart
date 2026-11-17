import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/cupertino.dart" show CupertinoIcons;
import "package:flutter/semantics.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../routing.dart";
import "../../models/credential.dart";
import "../../providers/credential_field_search.dart";
import "../../providers/credentials_provider.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/search_query_provider.dart";
import "../../providers/wallet_cards_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_motion.dart";
import "../../theme/yivi_palette.dart";
import "../../theme/yivi_space.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/haptics.dart";
import "../../util/i18n.dart";
import "../../util/instance_hint.dart";
import "../../util/navigation.dart";
import "../../widgets/app_toast.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/glass/glass_menu.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/press_scale.dart";
import "../../widgets/search_mark.dart";
import "../../widgets/surface_card.dart";
import "../../widgets/tab_layout.dart";
import "../../widgets/title_scroll_edge.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_spinner.dart";
import "../add_data/add_data_sheet.dart";
import "../home/widgets/home_tab_top.dart";
import "../home/widgets/search_tab_controller.dart";
import "../home/widgets/search_tab_scaffold.dart";
import "card_transition/card_transition.dart";
import "card_transition/card_transition_layer.dart";
import "card_transition/stack_cards.dart";
import "credential_detail/credential_detail_screen.dart";
import "empty_data_start.dart";
import "wallet/card_hero.dart";
import "wallet/drag_to_arrange.dart";
import "wallet/issuance_flight.dart";
import "wallet/wallet_transition.dart";
import "wallet_search.dart";
import "widgets/email_link_banner.dart";

part "card_views.dart";
part "problematic_card.dart";
part "wallet_view_menu.dart";

class DataTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<DataTab> with RouteAware {
  /// The search outlives this State ([dataSearchProvider]): the tab is
  /// built anew when a card opened from the results closes.
  late String _query = ref.read(dataSearchProvider).query;

  /// As in Activity: a tap in the field switches to the search right away,
  /// before anything is typed; Cancel ends it, losing focus does not.
  late final _search = SearchTabController(
    this,
    text: _query,
    onFocus: () => ref.read(dataSearchProvider.notifier).start(),
  );

  /// What the search looks in, made again only when the cards change.
  final _searchIndex = WalletSearchCache();

  @override
  void initState() {
    super.initState();
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

  /// Gives the field the keyboard back when it had it as a card opened.
  void _refocus() => _search.showKeyboardWhenOnTop(
    () => ref.read(dataSearchProvider.notifier).takeRefocus(),
  );

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() => _query = q);
    ref.read(dataSearchProvider.notifier).type(q);
  }

  /// The field under the large title, or the bar's search button: search
  /// mode, with the field in the bar and the keyboard up.
  void _startSearching() =>
      _search.startInBar(ref.read(dataSearchProvider.notifier).start);

  void _stopSearching() {
    _search.stop();
    setState(() => _query = "");
    ref.read(dataSearchProvider.notifier).stop();
  }

  @override
  Widget build(BuildContext context) {
    final panes = useHomePanes(context);
    // Next to a pane, and while searching, the list starts under the bar;
    // on a phone held upright its large title is on the bar's row.
    final topInset = panes
        ? SearchTabScaffold.edge(context)
        : HomeTabTop.listTop(context);
    final searching =
        ref.watch(dataSearchProvider.select((s) => s.active)) ||
        _query.trim().isNotEmpty;

    // A card that opens in the detail pane (tapped, or picked among the
    // cards of its type in the pane) comes into view in the list: to the
    // middle when it was not all in view.
    ref.listen(selectedCardProvider, (_, hash) {
      if (hash == null || !useHomePanes(context)) return;
      afterFrame(() => _revealCard(context, hash, top: topInset));
    });

    Widget field(double height) => GlassSearchField(
      fieldKey: const Key("search_field"),
      hintKey: "wallet.search_placeholder",
      controller: _search.field,
      focusNode: _search.focus,
      onChanged: _onQuery,
      height: height,
    );
    final cancel = SearchCancelButton(
      key: const Key("data_search_cancel"),
      labelKey: "wallet.search_cancel",
      onPressed: _stopSearching,
    );
    final add = YiviIconButton(
      key: const Key("data_tab_add_data"),
      icon: CupertinoIcons.add,
      label: context.tr("wallet.add_data"),
      onTap: () => showAddDataSheet(context),
      look: IconButtonLook.bar,
    );
    final hash = panes ? ref.watch(dataPaneCardProvider) : null;

    return SearchTabScaffold(
      searching: searching,
      title: context.tr("home.nav_bar.data"),
      searchLabel: context.tr("wallet.search_placeholder"),
      searchButtonKey: const Key("data_search_button"),
      onStartSearch: _startSearching,
      field: field,
      barAction: cancel,
      // Next to a pane: + beside the field, Cancel in its place.
      rowAction: searching ? cancel : add,
      // On a phone held upright "…" at the bar's left and + at its right;
      // the + turns into the close button of a card that opens.
      leading: const _ViewMenuButton(),
      trailing: add,
      trailingTurnsIntoClose: true,
      list: _Content(
        searchIndex: _searchIndex,
        query: _query,
        searching: searching,
        topInset: topInset,
        titleTop: HomeTabTop.titleTop(context),
        onStartSearch: panes ? null : _startSearching,
      ),
      // The details of the open card: the first until the user picks one.
      placeholder: const EmptyDataPane(),
      detail: hash == null
          ? null
          : _paneFor(hash, switch (ref.watch(foundCardFieldProvider)) {
              (hash: final h, :final claimKey) when h == hash => claimKey,
              _ => null,
            }),
    );
  }

  CredentialDetailPane? _pane;

  /// The details of [hash]: the same widget while the card and its found
  /// field stay, so the pane does not build again for every letter typed.
  CredentialDetailPane _paneFor(String hash, String? found) {
    final pane = _pane;
    if (pane != null && pane.hash == hash && pane.found == found) return pane;
    final selection = ref.read(selectedCardProvider.notifier);
    return _pane = CredentialDetailPane(
      key: ValueKey(hash),
      hash: hash,
      found: found,
      onSwitch: selection.select,
      onDeleted: () => selection.select(null),
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
  final WalletSearchCache searchIndex;
  final bool searching;
  final double topInset;

  /// A phone held upright: the list starts with the large title and the
  /// search field, whose tap starts this.
  final VoidCallback? onStartSearch;

  /// Where the large title starts, on the bar's row ([onStartSearch]).
  final double titleTop;

  const _Content({
    required this.query,
    required this.searchIndex,
    required this.searching,
    required this.topInset,
    this.titleTop = 0,
    this.onStartSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final snapshot = ref.watch(credentialsProvider);
    final ordered = ref.watch(credentialOrderControllerProvider);

    return switch ((snapshot, ordered)) {
      (AsyncError(), _) || (_, AsyncError()) => Center(
        child: Padding(
          padding: const EdgeInsets.all(YiviSpace.x16),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: YiviSpace.x16,
                                ),
                                child: EmptyDataTitle(),
                              ),
                            )
                          : const EmptyDataStart(),
                    ),
                  ],
                ),
              )
            : _CardList(
                searchIndex: searchIndex,
                cards: cards,
                problematic: snap.problematic,
                query: query,
                searching: searching,
                topInset: topInset,
                titleTop: titleTop,
                onStartSearch: onStartSearch,
              ),
      _ => const Center(child: YiviSpinner()),
    };
  }
}

/// The cards, in the view the user picked.
class _CardList extends ConsumerWidget {
  final List<Credential> cards;

  /// The tab's search index, kept across builds.
  final WalletSearchCache searchIndex;
  final List<ProblematicCredential> problematic;
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
    required this.searchIndex,
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

  Widget _build(BuildContext context, WidgetRef ref, List<Credential> cards) {
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
        ? searchIndex.indexFor(context, cards, hintTexts).search(query)
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
                      padding: const EdgeInsets.only(bottom: YiviSpace.x8),
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
                    padding: EdgeInsets.only(bottom: YiviSpace.x16),
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
                    padding: const EdgeInsets.only(bottom: YiviSpace.x8),
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
}

/// Opens the detail view of [credential], starting the Wallet-style
/// transition from [cardContext] (the tapped card).
/// [found]: the field (a claim path key) a search found it by; it opens on
/// that field.
void openCard(
  BuildContext cardContext,
  Credential credential, {
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
      .read(dataSearchProvider.notifier)
      .cardOpened(keyboardUp: View.of(cardContext).viewInsets.bottom > 0);
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
  Credential credential,
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
      padding: const EdgeInsets.only(top: YiviSpace.x8, bottom: YiviSpace.x8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.plural("wallet.count", count),
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

class _NoResults extends StatelessWidget {
  final YiviPalette palette;

  const _NoResults({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: YiviSpace.x32),
      child: Column(
        children: [
          TranslatedText(
            "wallet.no_results.title",
            textAlign: TextAlign.center,
            style: palette.display(16),
          ),
          const SizedBox(height: YiviSpace.x4),
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
