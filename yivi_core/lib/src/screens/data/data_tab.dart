import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/credential_events.dart";
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
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/instance_hint.dart";
import "../../util/navigation.dart";
import "../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../widgets/credential_card/delete_credential_confirmation_dialog.dart";
import "../../widgets/glass/floating_bar_placement.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/glass_surface.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/glass/scroll_edge.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/two_pane.dart";
import "../add_data/add_data_sheet.dart";
import "credential_detail/credential_detail_screen.dart";
import "empty_data_start.dart";
import "wallet/card_hero.dart";
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealCard(context, hash, top: topInset);
      });
    });

    // The cards scroll under the floating search row; the edge goes away
    // with the row when a card opens.
    final list = ScrollEdge(
      height: top + _topBarHeight + 8,
      // Held sideways the search row just floats over the cards, with no
      // band under it.
      band: (context, under) => usePhoneLandscape(context)
          ? const SizedBox.shrink()
          : PushAway(
              direction: PushAwayDirection.up,
              child: ScrollEdgeBand(under: under),
            ),
      bar: [
        Positioned(
          left: 16,
          right: 16,
          top: top,
          child: PushAway(
            direction: PushAwayDirection.up,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Row(
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
                      semanticsLabel: FlutterI18n.translate(
                        context,
                        "wallet.add_data",
                      ),
                      icon: Icon(Icons.add, size: 26, color: palette.text),
                      onTap: () => showAddDataSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
    final cards =
        ref.watch(schemalessCredentialOrderControllerProvider).value ??
        const <schemaless.Credential>[];
    final selected = ref.watch(selectedCardProvider);
    final hash = cards.any((c) => c.hash == selected)
        ? selected
        : cards.firstOrNull?.hash;
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
  final cards =
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(schemalessCredentialOrderControllerProvider).value ??
      const <schemaless.Credential>[];
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
    // Reordering only makes sense for the full list, in List view.
    final reorderable =
        view == WalletView.list && visible.length == cards.length;
    final bottom =
        MediaQuery.paddingOf(context).bottom + bottomBarSpace(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = min(constraints.maxWidth - 32, 640.0);
        final side = (constraints.maxWidth - contentWidth) / 2;
        // The stack sits a little further in than the rest (1.5 times the
        // side), so its cards are a little smaller. Next to a detail pane
        // it is 16 narrower than the column instead: the card open in the
        // pane slides that far to the right, out of the stack.
        final panes = useHomePanes(context);
        final stackWidth = panes
            ? contentWidth - _StackView.nudge
            : min(constraints.maxWidth - 48, 640.0);
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
                child: _Header(count: visible.length, view: view),
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
                      openHash: panes ? _openInPane(ref, cards) : null,
                    ),
                  ),
                  WalletView.list => _ListView(
                    cards: visible,
                    hintTexts: hintTexts,
                    reorderable: reorderable,
                  ),
                  WalletView.grid => _GridView(
                    cards: visible,
                    hintTexts: hintTexts,
                    width: contentWidth,
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
  final int count;
  final WalletView view;

  const _Header({required this.count, required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final countText = count == 1
        ? FlutterI18n.translate(context, "wallet.count_one")
        : FlutterI18n.translate(
            context,
            "wallet.count_many",
            translationParams: {"count": "$count"},
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              countText,
              style: palette.body(14).copyWith(color: palette.heading),
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

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    const icons = {
      WalletView.stack: Icons.view_agenda_outlined,
      WalletView.list: Icons.view_list_rounded,
      WalletView.grid: Icons.grid_view_rounded,
    };
    return Semantics(
      container: true,
      label: FlutterI18n.translate(context, "wallet.view.label"),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: palette.outline)),
          color: palette.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in WalletView.values)
              _Segment(
                key: Key("wallet_view_${v.name}"),
                label: FlutterI18n.translate(context, "wallet.view.${v.name}"),
                icon: icons[v]!,
                selected: v == view,
                compact: compact,
                onTap: () => onChanged(v),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _Segment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final fg = selected ? palette.surface : palette.heading;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.heading : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(icon, size: 16, color: fg),
                  if (!compact)
                    Text(label, style: palette.display(12).copyWith(color: fg)),
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
/// shown in full.
class _StackView extends StatelessWidget {
  static const double _stripHeight = 64;

  /// How far the card open in the detail pane slides out of the stack.
  static const double nudge = 16;

  /// How far it tilts to the right (clockwise), in radians: about 2°.
  static const double tilt = 0.035;

  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final double width;

  /// The card open in the detail pane, if there is one.
  final String? openHash;

  const _StackView({
    required this.cards,
    required this.hintTexts,
    required this.width,
    this.openHash,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = width / CredentialCardArt.aspectRatio;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // When a flight starts the cards close the gap at once, under the
    // curtain; they slide only to make room for the new card.
    final flight = IssuanceFlight.state.value;
    final slide = flight != null && !flight.inserted
        ? Duration.zero
        : const Duration(milliseconds: 400);
    return SizedBox(
      height: (cards.length - 1) * _stripHeight + cardHeight,
      child: Stack(
        children: [
          for (final (i, c) in cards.indexed)
            // Animated, so the cards slide down when a received card joins
            // the top.
            AnimatedPositioned(
              key: ValueKey(c.hash),
              duration: slide,
              curve: IssuanceFlight.curve,
              top: i * _stripHeight,
              left: 0,
              right: 0,
              child: PushAway(
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
                        // Under the next card only its strip shows.
                        revealHeight: i == cards.length - 1
                            ? null
                            : _stripHeight,
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
              ),
            ),
        ],
      ),
    );
  }
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

/// The card the detail pane shows: the picked one, or the first.
String? _openInPane(WidgetRef ref, List<schemaless.Credential> cards) {
  final selected = ref.watch(selectedCardProvider);
  return cards.any((c) => c.hash == selected)
      ? selected
      : cards.firstOrNull?.hash;
}

class _ListView extends ConsumerWidget {
  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final bool reorderable;

  const _ListView({
    required this.cards,
    required this.hintTexts,
    required this.reorderable,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(
      schemalessCredentialOrderControllerProvider.notifier,
    );
    return SliverReorderableList(
      itemCount: cards.length,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      onReorderEnd: (_) => HapticFeedback.mediumImpact(),
      onReorderItem: controller.reorder,
      proxyDecorator: (child, index, animation) =>
          Material(type: MaterialType.transparency, child: child),
      itemBuilder: (context, i) {
        final c = cards[i];
        final row = Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PushAway(
            hash: c.hash,
            fadeWhenOpening: true,
            child: IssuanceFlightHidden(
              hash: c.hash,
              child: _ListRow(
                credential: c,
                hintText: hintTexts[c.hash],
                flightTarget: i == 0,
              ),
            ),
          ),
        );
        return KeyedSubtree(
          key: ValueKey(c.hash),
          child: reorderable
              ? ReorderableDelayedDragStartListener(index: i, child: row)
              : row,
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
  final cards =
      container.read(schemalessCredentialOrderControllerProvider).value ??
      const <schemaless.Credential>[];
  final open = cards.any((c) => c.hash == selected)
      ? selected
      : cards.firstOrNull?.hash;
  return open == credential.hash;
}

class _ListRow extends StatelessWidget {
  final schemaless.Credential credential;
  final String? hintText;

  /// The thumbnail is where a received card lands.
  final bool flightTarget;

  const _ListRow({
    required this.credential,
    this.hintText,
    this.flightTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final selected = _isOpenInPane(context, credential);
    return _CardButton(
      credential: credential,
      hintText: hintText,
      pressDepth: 4,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(
            Radius.circular(YiviCorners.card),
          ),
          side: BorderSide(
            width: 2,
            color: selected ? palette.primary : Colors.transparent,
          ),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            spacing: 16,
            children: [
              _flightSlot(
                first: flightTarget,
                child: CardHero(
                  credential: credential,
                  width: 88,
                  hintText: hintText,
                ),
              ),
              Expanded(
                child: Column(
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

class _GridView extends StatelessWidget {
  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final double width;

  const _GridView({
    required this.cards,
    required this.hintTexts,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    const gap = 16.0;
    final cardWidth = (width - gap) / 2;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final captionHeight = 8 + 40 * textScale;
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        mainAxisExtent:
            cardWidth / CredentialCardArt.aspectRatio + captionHeight,
      ),
      delegate: SliverChildBuilderDelegate(childCount: cards.length, (
        context,
        i,
      ) {
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
      }),
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

  const _CardButton({
    required this.credential,
    required this.child,
    this.hintText,
    this.pressDepth = 0,
    this.revealHeight,
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
      excludeSemantics: true,
      child: GestureDetector(
        key: Key("${credential.credentialId}_tile"),
        behavior: HitTestBehavior.opaque,
        // A tap down arrives only once it is not a scroll (or after a short
        // wait), so scrolling over the stack does not push cards.
        onTapDown: depth == 0 ? null : (_) => _press(true),
        onTapUp: depth == 0 ? null : (_) => _press(false),
        onTapCancel: depth == 0 ? null : () => _press(false),
        onTap: () => openCard(context, credential),
        child: depth == 0
            ? widget.child
            : TweenAnimationBuilder<double>(
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
      ),
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
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => DeleteCredentialConfirmationDialog(),
        ) ??
        false;
    if (confirmed && context.mounted) {
      ref
          .read(irmaRepositoryProvider)
          .bridgedDispatch(
            DeleteCredentialEvent(
              hashByFormat: credential.credentialInstanceIds,
            ),
          );
    }
  }
}

/// The cards of the same type as [credential] (including itself), in the
/// user's order.
List<schemaless.Credential> sameTypeCards(
  List<schemaless.Credential> cards,
  schemaless.Credential credential,
) => cards
    .where((c) => c.credentialId == credential.credentialId)
    .sortedBy<num>((c) => cards.indexOf(c));

/// Marks the first card picture as the landing slot of a received card, and
/// hides the card that is flying in (with [hash]).
Widget _flightSlot({required bool first, String? hash, required Widget child}) {
  Widget slot = child;
  if (hash != null) slot = IssuanceFlightHidden(hash: hash, child: slot);
  if (first) slot = IssuanceFlightTarget(child: slot);
  return slot;
}
