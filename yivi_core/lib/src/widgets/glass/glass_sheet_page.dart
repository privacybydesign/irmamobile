part of "glass_sheet.dart";

/// One page of a sheet: its [GlassSheetHeader], [child] in a
/// [GlassSheetScrollView], and [bottom] (a button) pinned to the bottom of
/// the sheet, as on a full screen.
///
/// The content scrolls on under the header and the [pinned] part; once it
/// is under them, they get the hard scroll edge of iOS ([ScrollEdgeBand]).
class GlassSheetPage extends StatefulWidget {
  final String title;

  /// In the title's place while not null (see [GlassSheetHeader.titleWidget]).
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final Widget? child;

  /// Instead of [child]: slivers, built as they scroll into view, for a long
  /// list.
  final List<Widget>? slivers;
  final Widget? bottom;

  /// The way on: at the bottom on a phone held upright (under [bottom]), in
  /// the bar at the top right elsewhere ([sheetActionInBar]). Screens inside
  /// the page can put theirs in its [SheetActionSlot] instead.
  final SheetAction? action;

  /// False on a page that is left by dragging its header down (the pages
  /// of adding a card) or by its way on ("Success"): no close button, no
  /// "Cancel" in the bar.
  final bool closable;

  /// See [GlassSheetHeader.closeAtStart].
  final bool closeAtStart;

  /// See [GlassSheetHeader.leading].
  final Widget? leading;

  /// Right under the title bar, the full width of the sheet, and above the
  /// scrolling [child], staying put while the page scrolls (the progress of
  /// adding a card).
  final Widget? pinned;

  /// On a phone held sideways: a second line under the title (see
  /// [GlassSheetHeader.subtitle]).
  final Widget? subtitle;

  /// Around [child] in the scroll view; zero when [child] pads itself.
  final EdgeInsets padding;

  /// False for a [child] that fills the page and fits itself to it (a PIN
  /// pad) instead of scrolling.
  final bool scrolls;

  /// With [scrolls] false: [child] keeps clear of the home indicator itself
  /// (screens with their own bottom bar), so the page adds no room for it.
  final bool childClearsBottom;

  // `split` (constructor only): [child] lays itself out in the sheet's two
  // columns (a `SheetSplit`, on a phone held sideways). The page then adds
  // no padding, does not scroll (each column scrolls on its own) and leaves
  // the bottom to the columns, whatever [padding], [scrolls] and
  // [childClearsBottom] say for upright.

  /// Whether the bar gets the hard scroll edge once content scrolls under
  /// it. Without it, only the buttons float over the content (a page whose
  /// bar has no title).
  final bool edge;

  /// With [scrolls] false, on a phone held upright: the bottom bar shows
  /// the buttons the screens inside put in the page's [SheetActionSlot]
  /// (the document steps), and stays put while they change; it keeps its
  /// room while a screen has none.
  final bool slotBottom;

  /// The sheet is as high as this page's content, while it is the page on
  /// top: a short choice is a low sheet. It grows into the full sheet as a
  /// page without [fit] comes in over it, and goes back as that page goes.
  final bool fit;

  /// [titleWidget] stays in the middle of the bar on a phone held sideways
  /// too (a tag), instead of standing next to the title at the start.
  final bool titleWidgetCentred;

  /// The title shows only once the page has scrolled this far: its heading
  /// is in the page, and the bar names the page once that is under it.
  /// Null: the title always shows.
  final double? titleAfterScroll;

  /// The page's own big heading: the bar's title shows only once all of it
  /// has scrolled up under the bar (measured, so a heading that wraps is
  /// waited for). Null: see [titleAfterScroll].
  final GlobalKey? titleUnder;

  /// See the constructor's `split`.
  final bool split;

  /// On a phone held sideways, [bottom] (the progress) goes into the bar,
  /// right after [titleWidget], instead of under the content.
  final bool bottomInBar;

  const GlassSheetPage({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.child,
    this.slivers,
    this.bottom,
    this.action,
    this.closable = true,
    this.closeAtStart = false,
    this.leading,
    this.pinned,
    this.subtitle,
    EdgeInsets padding = EdgeInsets.zero,
    bool scrolls = true,
    bool childClearsBottom = false,
    bool split = false,
    this.edge = true,
    this.slotBottom = false,
    this.fit = false,
    this.titleWidgetCentred = false,
    this.titleAfterScroll,
    this.titleUnder,
    this.bottomInBar = false,
  }) : split = split,
       padding = split ? EdgeInsets.zero : padding,
       scrolls = scrolls && !split,
       childClearsBottom = childClearsBottom || split,
       assert((child == null) != (slivers == null), "child or slivers"),
       assert(
         (scrolls && !split) || child != null,
         "a page that fills itself has a child",
       );

  @override
  State<GlassSheetPage> createState() => _GlassSheetPageState();
}

class _GlassSheetPageState extends State<GlassSheetPage> {
  final _under = ScrollEdgeNotifier();
  final _slot = SheetActionSlot();

  /// Whether the page has scrolled past [GlassSheetPage.titleAfterScroll].
  final _past = ValueNotifier(false);

  @override
  void dispose() {
    _under.dispose();
    _slot.dispose();
    _past.dispose();
    super.dispose();
  }

  /// The bar, to measure the page's heading against.
  final _barKey = GlobalKey();

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final heading = widget.titleUnder?.currentContext.laidOutBox;
    final bar = _barKey.currentContext.laidOutBox;
    if (heading != null && bar != null) {
      final bottom = heading.localToGlobal(Offset(0, heading.size.height)).dy;
      _past.value = bottom < bar.localToGlobal(Offset(0, bar.size.height)).dy;
      return false;
    }
    final after = widget.titleAfterScroll;
    if (after != null) _past.value = n.metrics.pixels > after;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final role = _SheetPageRole.maybeOf(context);
    final title = widget.title;
    final onBack = widget.onBack;
    final pinned = widget.pinned;
    final action = widget.action;
    final inBar = sheetActionInBar(context);
    final bottomUp =
        widget.bottomInBar &&
        useSheetColumns(context) &&
        !_GlassSheetFloating.of(context);
    _slot.takesBottom =
        widget.slotBottom &&
        !widget.scrolls &&
        !inBar &&
        !useSheetColumns(context);
    role?.chrome[role.pageKey] = (
      back: onBack != null,
      pinned: pinned != null,
      action: inBar && (action != null || _slot.action != null),
    );
    // While pages change, what only one of the two pages has fades; what
    // both have stays put (the top page's stands in for the other's).
    final moving = role != null && role.otherKey != null;
    final other = role?.other;
    if (moving && other == null) {
      // The other page builds after this one, the first time: look again
      // once it has noted its bar. Until then, nothing fades.
      afterFrame(() {
        if (role.other != null) setState(() {});
      });
    }
    final top = role?.top ?? true;
    // The page on top says how high the sheet should be: as its content, or
    // full.
    final report = top ? _SheetFit.of(context) : null;
    if (report != null && !widget.fit) {
      afterFrame(() => report(null));
    }
    final pinnedFades = moving && other != null && !other.pinned;
    // Underneath, the top page's pinned part stands in for this one, unless
    // it has none.
    final pinnedShown = pinned == null
        ? null
        : _kept(
            top || pinnedFades,
            pinnedFades
                ? FadeTransition(opacity: role.ownOpacity, child: pinned)
                : pinned,
          );
    final head = <Widget>[
      // In pages the bar stays put while pages change; only the titles fade
      // into each other. The way on in the bar comes from the page, or from
      // a screen inside it (the slot).
      ListenableBuilder(
        listenable: Listenable.merge([_slot, _past]),
        builder: (context, _) {
          final slotted = action == null ? _slot.action : null;
          // Until the page has scrolled its heading away, nothing in the
          // title's place (the title still names the page).
          final hideTitle =
              (widget.titleAfterScroll != null || widget.titleUnder != null) &&
              !_past.value;
          return GlassSheetHeader(
            title: title,
            titleWidget:
                widget.titleWidget ??
                (hideTitle ? const SizedBox.shrink() : null),
            titleWidgetCentred:
                widget.titleWidgetCentred || widget.titleWidget == null,
            onBack: onBack,
            action: inBar ? (action ?? slotted) : null,
            onAction: slotted == null
                ? null
                : () => _slot.action?.onTap?.call(),
            closable: widget.closable,
            closeAtStart: widget.closeAtStart,
            leading: widget.leading,
            buttons: top,
            titleOpacity: role?.titleOpacity,
            backOpacity: moving && other != null && !other.back
                ? role.ownOpacity
                : null,
            actionOpacity: moving && other != null && !other.action
                ? role.ownOpacity
                : null,
            subtitle: widget.subtitle,
            extra: bottomUp ? widget.bottom : null,
          );
        },
      ),
      // The progress: a line the full width of the sheet, under the bar.
      ?pinnedShown,
    ];
    final body = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ScrollEdgeListener(
        notifier: _under,
        child: Column(
          mainAxisSize: role == null ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _body(context, inBar ? null : action, bottomUp: bottomUp),
        ),
      ),
    );
    // Taps on the bar stay on the bar, also where content is under it.
    final bar = Listener(
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Clipped to the sheet's top corners itself: it is drawn outside
          // the sheet's rounded clip, and filled the corners square.
          if (widget.edge)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: _GlassSheet._radius,
                ),
                // The band is the edge of this page's content: it goes
                // with it as pages change, so it never switches at the end,
                // and the content under it never shows through the bar.
                child: role == null
                    ? ScrollEdgeBand(under: _under, color: palette.sheet)
                    : role.slide(
                        ScrollEdgeBand(under: _under, color: palette.sheet),
                      ),
              ),
            ),
          Column(
            key: _barKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: head,
          ),
        ],
      ),
    );
    final page = SheetActionSlotScope(
      slot: _slot,
      child: BarOverBody(
        expand: role != null,
        bar: bar,
        body: role == null ? body : role.slide(body),
      ),
    );
    return report != null && widget.fit
        ? _FitPage(report: report, child: page)
        : page;
  }

  /// What scrolls, and the buttons under it: [GlassSheetPage.bottom] and
  /// [action] (the way on, when it is not in the bar).
  List<Widget> _body(
    BuildContext context,
    SheetAction? action, {
    bool bottomUp = false,
  }) {
    final padding = widget.padding;
    final child = widget.child;
    final slivers = widget.slivers;
    final button = action == null
        ? null
        : SheetActionRow(
            primaryKey: action.key,
            primaryLabel: action.label,
            onPrimary: action.enabled ? action.onTap : null,
            primaryLeading: action.busy ? const SheetBusySpinner() : null,
            primaryNeutral: action.neutral,
          );
    final given = bottomUp ? null : widget.bottom;
    final bottom = button == null
        ? given
        : given == null
        ? button
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [given, button],
          );
    if (_slot.takesBottom) return _slotBody(padding, child!);
    // Sideways with the way on out of the bar: at the bottom of the split's
    // left column, not in a bar across the sheet.
    // The document steps' screens lay themselves out in a split sideways
    // too ([slotBottom]).
    if ((widget.split || widget.slotBottom) &&
        bottom != null &&
        useSheetColumns(context)) {
      return [
        Expanded(
          child: Padding(
            padding: padding,
            child: SheetSplitBottom(bottom: bottom, child: child!),
          ),
        ),
      ];
    }
    return [
      if (!widget.scrolls) ...[
        Expanded(
          child: Padding(
            padding: widget.childClearsBottom || bottom != null
                ? padding
                : padding.add(
                    EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
            child: child,
          ),
        ),
        if (bottom != null) SheetBottomBar(child: bottom),
      ] else if (bottom == null)
        Flexible(
          child: GlassSheetScrollView(
            padding: padding,
            slivers: slivers,
            child: child,
          ),
        )
      else ...[
        Expanded(
          // Cut off where the bottom (a note, the buttons) starts, so the
          // content doesn't run on under it as text over text; open at the
          // top, where it goes on under the header.
          child: OpenTop(
            child: GlassSheetScrollView(
              padding: padding,
              clearBottom: false,
              slivers: slivers,
              child: child,
            ),
          ),
        ),
        SheetBottomBar(child: bottom),
      ],
    ];
  }
}

/// The body of a page whose bottom bar shows the slot's buttons
/// ([GlassSheetPage.slotBottom]).
extension on _GlassSheetPageState {
  List<Widget> _slotBody(EdgeInsets padding, Widget child) {
    SheetAction? latest(SheetAction? a, SheetAction? Function() now) =>
        a == null || !a.enabled
        ? a
        : SheetAction(
            key: a.key,
            label: a.label,
            busy: a.busy,
            // The latest callback (the slot takes a new one without a
            // rebuild).
            onTap: () => now()?.onTap?.call(),
          );
    return [
      Expanded(
        child: Padding(
          padding: padding,
          // The bar under it keeps clear of the home indicator.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: child,
          ),
        ),
      ),
      ListenableBuilder(
        listenable: _slot,
        builder: (context, _) {
          final primary = latest(_slot.action, () => _slot.action);
          final secondary = latest(_slot.secondary, () => _slot.secondary);
          final empty = primary == null && secondary == null;
          final row = SheetActionRow(
            primaryKey: primary?.key,
            // A screen without buttons: the bar keeps its room, empty.
            primaryLabel: empty ? " " : primary?.label,
            onPrimary: primary?.onTap,
            primaryLeading: primary?.busy ?? false
                ? const SheetBusySpinner()
                : null,
            secondaryKey: secondary?.key,
            secondaryLabel: secondary?.label,
            onSecondary: secondary?.onTap,
          );
          // What the page puts above the buttons (the progress) stays,
          // also while a screen has no buttons.
          final above = widget.bottom;
          return SheetBottomBar(
            child: above == null
                ? _kept(!empty, row)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [above, _kept(!empty, row)],
                  ),
          );
        },
      ),
    ];
  }
}

/// The scrolling body of a sheet, under its [GlassSheetHeader]: it pulls the
/// sheet down from its top (see [GlassSheetScope]), goes on under the header
/// (which clips it no more than the sheet does; see [GlassSheetPage]), and
/// ends clear of the home indicator. [child] pads itself from the
/// sides unless [padding] does.
class GlassSheetScrollView extends StatelessWidget {
  final Widget? child;

  /// Instead of [child]: slivers, built as they scroll into view (a long
  /// list).
  final List<Widget>? slivers;
  final EdgeInsets padding;

  /// Ends clear of the home indicator; off when a button sits under it.
  final bool clearBottom;

  const GlassSheetScrollView({
    super.key,
    this.child,
    this.slivers,
    this.padding = EdgeInsets.zero,
    this.clearBottom = true,
  }) : assert((child == null) != (slivers == null), "child or slivers");

  /// Room between the header and the content at rest.
  static const _top = 6.0;

  @override
  Widget build(BuildContext context) {
    // Not clipped at the top: the content goes on under a
    // [GlassSheetPage]'s header (its hard scroll edge). The page clips the
    // bottom.
    final inset = _padding(context);
    final physics = glassSheetScrollPhysics(context);
    final fit = slivers == null ? _FitPage.maybeOf(context) : null;
    if (fit != null) {
      return _FitMeasure(
        report: fit.report,
        padding: inset,
        child: SingleChildScrollView(
          physics: physics,
          clipBehavior: Clip.none,
          padding: inset,
          child: _SizeReport(child: child!),
        ),
      );
    }
    return switch (slivers) {
      final slivers? => CustomScrollView(
        physics: physics,
        clipBehavior: Clip.none,
        slivers: [
          SliverPadding(
            padding: inset,
            sliver: SliverMainAxisGroup(slivers: slivers),
          ),
        ],
      ),
      null => SingleChildScrollView(
        physics: physics,
        clipBehavior: Clip.none,
        padding: inset,
        child: child,
      ),
    };
  }

  EdgeInsets _padding(BuildContext context) => padding.copyWith(
    top: padding.top + _top,
    bottom:
        padding.bottom +
        (clearBottom ? MediaQuery.paddingOf(context).bottom : 16),
  );
}

/// A sheet with the title [titleKey] over [child]: a [GlassSheetPage] in
/// [showGlassSheet].
Future<void> showTitledGlassSheet({
  required BuildContext context,
  required String titleKey,
  required Widget child,
}) => showGlassSheet<void>(
  context: context,
  builder: (context) => GlassSheetPage(
    title: FlutterI18n.translate(context, titleKey),
    child: child,
  ),
);

/// How many sheets are fully open: the band behind Android's buttons then
/// takes the sheet's colour.
abstract final class GlassSheetCover {
  static final covering = ValueNotifier<int>(0);
}

/// Measures a fitting page's content after each layout: how much room its
/// scroll view leaves ([report] gets the slack; negative when it scrolls).
class _FitMeasure extends StatefulWidget {
  final ValueChanged<double?> report;
  final EdgeInsets padding;
  final Widget child;

  const _FitMeasure({
    required this.report,
    required this.padding,
    required this.child,
  });

  @override
  State<_FitMeasure> createState() => _FitMeasureState();
}

class _FitMeasureState extends State<_FitMeasure> {
  final _content = GlobalKey(debugLabel: "sheet_fit_content");

  /// The room the scroll view has: the height the content could take.
  double? _room;

  void _measure() {
    if (!mounted) return;
    final content = _SizeReport.find(_content.currentContext);
    final room = _room;
    if (room == null || !room.isFinite || content == null || !content.hasSize) {
      return;
    }
    widget.report(room - (content.size.height + widget.padding.vertical));
  }

  @override
  Widget build(BuildContext context) {
    return _SizeChanged(
      onChanged: () =>
          WidgetsBinding.instance.addPostFrameCallback((_) => _measure()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight != _room) {
            _room = constraints.maxHeight;
            WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
          }
          return KeyedSubtree(key: _content, child: widget.child);
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // On top again (back from a page over it): say so once more.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(_FitMeasure old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }
}

/// Tells [onChanged] when its subtree's [_SizeReport] changes size.
class _SizeChanged extends InheritedWidget {
  final VoidCallback onChanged;

  const _SizeChanged({required this.onChanged, required super.child});

  @override
  bool updateShouldNotify(_SizeChanged old) => false;
}

/// The content of a fitting page, whose size [_FitMeasure] reads.
class _SizeReport extends SingleChildRenderObjectWidget {
  const _SizeReport({required Widget super.child});

  /// The content's box under [context].
  static RenderBox? find(BuildContext? context) {
    RenderBox? found;
    void visit(Element e) {
      if (found != null) return;
      if (e.widget is _SizeReport) {
        found = e.renderObject as RenderBox?;
        return;
      }
      e.visitChildren(visit);
    }

    if (context is Element) context.visitChildren(visit);
    return found;
  }

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReport(
    context.getInheritedWidgetOfExactType<_SizeChanged>()?.onChanged,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderSizeReport render,
  ) {
    render.onChanged = context
        .getInheritedWidgetOfExactType<_SizeChanged>()
        ?.onChanged;
  }
}

class _RenderSizeReport extends RenderProxyBox {
  _RenderSizeReport(this.onChanged);

  VoidCallback? onChanged;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size != _last) {
      _last = size;
      onChanged?.call();
    }
  }
}
