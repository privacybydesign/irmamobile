import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../package_name.dart";
import "../../data/feature_flags.dart";
import "../../models/credential_events.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/credentials_search.dart";
import "../../providers/email_linking_provider.dart";
import "../../providers/feature_flag_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../providers/schemaless_credentials_provider.dart";
import "../../theme/theme.dart";
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
import "empty_data_routes.dart";
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
  String _query = "";

  // We use the global key of the add_data button to provide the 'pointing man' image with the
  // global location of the button, so it can calculate the correct angle to point to.
  // We don't want a completely global key, as that would cause problems since GoRouter keeps multiple instances
  // of a page alive for transitions, so we have to pass it down the widget tree.
  final _addDataButtonKey = GlobalKey(debugLabel: "add_data_button_key");

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    final top = padding.top + FloatingBarPlacement.topGap(context);

    // The cards scroll under the floating search row; the edge goes away
    // with the row when a card opens.
    final list = ScrollEdge(
      height: top + _topBarHeight + 8,
      band: (context, under) => PushAway(
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
                        onChanged: (q) => setState(() => _query = q),
                      ),
                    ),
                    GlassIconButton(
                      key: _addDataButtonKey,
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
      child: _Content(
        query: _query,
        addDataButtonKey: _addDataButtonKey,
        topInset: top + _topBarHeight + 8,
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: palette.background,
      body: isExpandedLayout(context) ? _withDetailPane(list) : list,
    );
  }

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

class _Content extends ConsumerWidget {
  final String query;
  final GlobalKey addDataButtonKey;
  final double topInset;

  const _Content({
    required this.query,
    required this.addDataButtonKey,
    required this.topInset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = YiviPalette.of(context);
    final snapshot = ref.watch(schemalessCredentialsProvider);
    final ordered = ref.watch(schemalessCredentialOrderControllerProvider);
    // Read next to the credentials so it has loaded by the time they have.
    final onboardingV2 =
        ref.watch(featureFlagProvider(FeatureFlag.onboardingV2)).value ?? false;

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
                      child: onboardingV2
                          ? const EmptyDataRoutes()
                          : _NoCredentialsYet(
                              addDataButtonKey: addDataButtonKey,
                            ),
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
        // side), so its cards are a little smaller.
        final stackWidth = min(constraints.maxWidth - 48, 640.0);
        final stackSide = (constraints.maxWidth - stackWidth) / 2;

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
                padding: EdgeInsets.symmetric(
                  horizontal: view == WalletView.stack ? stackSide : side,
                ),
                sliver: switch (view) {
                  WalletView.stack => SliverToBoxAdapter(
                    child: _StackView(
                      cards: visible,
                      hintTexts: hintTexts,
                      width: stackWidth,
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
  if (isExpandedLayout(cardContext)) {
    // The tablet layout shows the card in the detail pane next to the list.
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

  const ViewSwitcher({super.key, required this.view, required this.onChanged});

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
  final VoidCallback onTap;

  const _Segment({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
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

  final List<schemaless.Credential> cards;
  final Map<String, String> hintTexts;
  final double width;

  const _StackView({
    required this.cards,
    required this.hintTexts,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cardHeight = width / CredentialCardArt.aspectRatio;
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
                    child: _CardButton(
                      credential: c,
                      hintText: hintTexts[c.hash],
                      pressDepth: 6,
                      child: CardHero(
                        credential: c,
                        width: width,
                        hintText: hintTexts[c.hash],
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
  if (!isExpandedLayout(context)) return false;
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
        shape: RoundedSuperellipseBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
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
                    child: CardHero(
                      credential: c,
                      width: cardWidth,
                      hintText: hintTexts[c.hash],
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

  const _CardButton({
    required this.credential,
    required this.child,
    this.hintText,
    this.pressDepth = 0,
  });

  @override
  State<_CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<_CardButton> {
  bool _pressed = false;

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

// ============================================================================================

// Image of a man that always points towards the add data button to indicate that button should be pressed
class _ToAddDataButtonPointingImage extends StatefulWidget {
  const _ToAddDataButtonPointingImage({required this.addDataButtonKey});

  final GlobalKey addDataButtonKey;

  @override
  State<_ToAddDataButtonPointingImage> createState() =>
      _ToAddDataButtonPointingImageState();
}

class _ToAddDataButtonPointingImageState
    extends State<_ToAddDataButtonPointingImage> {
  final _imageKey = GlobalKey(debugLabel: "to_add_data_pointing_image_key");
  static const pi = 3.1415;
  double rotationAngle = 0.0;

  double _calculateRotation() {
    final addDataButtonRenderBox =
        widget.addDataButtonKey.currentContext?.findRenderObject()
            as RenderBox?;
    final imageRenderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;

    if (imageRenderBox == null || addDataButtonRenderBox == null) {
      return 100.0;
    }

    final plusButtonCenter = addDataButtonRenderBox.localToGlobal(
      addDataButtonRenderBox.size.center(Offset.zero),
    );
    final imageCenter = imageRenderBox.localToGlobal(
      imageRenderBox.size.center(Offset.zero),
    );

    final deltaX = plusButtonCenter.dx - imageCenter.dx;
    final deltaY = imageCenter.dy - plusButtonCenter.dy;
    final targetAngle = atan2(deltaY, deltaX);

    final referenceAngleDeg =
        55.0; // angle of the arm inside the image in degrees
    final referenceAngle = referenceAngleDeg * pi / 180.0;

    return targetAngle - referenceAngle;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rotation = _calculateRotation();
      if ((rotationAngle * 10000).round() != (rotation * 10000).round()) {
        setState(() => rotationAngle = rotation);
      }
    });

    return Transform(
      key: const Key("to_add_data_button_pointing_image"),
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(pi) // 180-degree flip (π radians)
        ..rotateZ(rotationAngle),
      child: SvgPicture.asset(
        key: _imageKey,
        yiviAsset("arrow_back/pointing_up.svg"),
      ),
    );
  }
}

class _NoCredentialsYet extends StatelessWidget {
  const _NoCredentialsYet({required this.addDataButtonKey});

  final GlobalKey addDataButtonKey;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return _buildPortraitOrientation(context);
        }
        return _buildLandscapeOrientation(context);
      },
    );
  }

  Padding _buildLandscapeOrientation(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  "data_tab.empty.title",
                  style: palette.display(26, weight: FontWeight.w700),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16),
                TranslatedText(
                  "data_tab.empty.subtitle",
                  textAlign: TextAlign.start,
                  style: palette.body(16),
                ),
              ],
            ),
          ),
          _ToAddDataButtonPointingImage(addDataButtonKey: addDataButtonKey),
        ],
      ),
    );
  }

  Padding _buildPortraitOrientation(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _ToAddDataButtonPointingImage(addDataButtonKey: addDataButtonKey),
            const SizedBox(height: 32),
            TranslatedText(
              "data_tab.empty.title",
              style: palette.display(26, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TranslatedText(
              "data_tab.empty.subtitle",
              textAlign: TextAlign.center,
              style: palette.body(16),
            ),
          ],
        ),
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
      shape: const RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
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
