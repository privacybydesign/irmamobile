part of "sheet.dart";

/// What the bar of a sheet page shows in its middle.
@immutable
class SheetTitle {
  const SheetTitle(
    this.text, {
    this.widget,
    this.centred = false,
    this.reveal = const SheetTitleReveal.always(),
  });

  /// Names the page, also for screen readers.
  final String text;

  /// In the title's place: a tag, a search field (see
  /// [SheetHeader.titleWidget]).
  final Widget? widget;

  /// [widget] stays in the middle of the bar on a phone held sideways too
  /// (a tag), instead of standing next to the title at the start.
  final bool centred;
  final SheetTitleReveal reveal;
}

/// When the bar's title shows.
sealed class SheetTitleReveal {
  const SheetTitleReveal();

  const factory SheetTitleReveal.always() = _Always;

  /// Once the page has scrolled [offset] far: its heading is in the page,
  /// and the bar names the page once that is under it.
  const factory SheetTitleReveal.afterScroll(double offset) = _AfterScroll;

  /// Once all of the page's own big [heading] has scrolled up under the bar
  /// (measured, so a heading that wraps is waited for).
  const factory SheetTitleReveal.under(GlobalKey heading) = _Under;
}

final class _Always extends SheetTitleReveal {
  const _Always();
}

final class _AfterScroll extends SheetTitleReveal {
  const _AfterScroll(this.offset);
  final double offset;
}

final class _Under extends SheetTitleReveal {
  const _Under(this.heading);
  final GlobalKey heading;
}

/// Where a sheet page's close button is: at the end of the bar, at its
/// start (see [SheetHeader.closeAtStart]), or none (a page left by
/// dragging its header down, or by its way on).
enum SheetClose { end, start, none }

/// The ways out of a sheet page.
@immutable
class SheetExits {
  const SheetExits({this.onBack, this.close = SheetClose.end});
  final VoidCallback? onBack;
  final SheetClose close;
}

/// A row that sticks under the bar, over the content, on the bar's band,
/// once the top of [after] has scrolled under the bar (who gives the card,
/// once their card has gone up). It drops in without moving the content.
typedef SheetUnderBar = ({Widget row, GlobalKey after});

/// How a page lays out its content.
enum _PageBody {
  /// Scrolls under the bar.
  scroll,

  /// Fills the page and keeps clear of the home indicator itself.
  fill,

  /// Lays itself out in the sheet's two columns ([SheetSplit]).
  split,
}

/// One page of a sheet: its [SheetHeader], its content, and [bottom]
/// (a button) pinned to the bottom of the sheet, as on a full screen.
///
/// The content scrolls on under the header; once it is under it, the header
/// gets the hard scroll edge of iOS ([ScrollEdgeBand]).
class SheetPage extends StatefulWidget {
  final SheetTitle title;
  final SheetExits exits;
  final _PageBody _body;
  final Widget? child;

  /// Instead of [child]: slivers, built as they scroll into view, for a long
  /// list.
  final List<Widget>? slivers;
  final Widget? bottom;

  /// The way on: at the bottom on a phone held upright (under [bottom]), in
  /// the bar at the top right elsewhere ([sheetActionInBar]). Screens inside
  /// the page can put theirs in its [SheetActionSlot] instead.
  final SheetAction? action;

  /// Around [child] in the scroll view; zero when [child] pads itself.
  final EdgeInsets padding;

  /// On a phone held upright: the bottom bar shows the buttons the screens
  /// inside put in the page's [SheetActionSlot] (the document steps), and
  /// stays put while they change; it keeps its room while a screen has none.
  final bool slotBottom;

  /// The sheet is as high as this page's content, while it is the page on
  /// top: a short choice is a low sheet. It grows into the full sheet as a
  /// page without [fit] comes in over it, and goes back as that page goes.
  final bool fit;

  /// On a phone held sideways, [bottom] (the progress) goes into the bar,
  /// right after the title's widget, instead of under the content.
  final bool bottomInBar;
  final SheetUnderBar? underBar;

  /// Content that scrolls under the bar: a [child] or [slivers].
  const SheetPage.scroll({
    super.key,
    required this.title,
    this.exits = const SheetExits(),
    this.child,
    this.slivers,
    this.padding = EdgeInsets.zero,
    this.bottom,
    this.action,
    this.fit = false,
    this.underBar,
  }) : _body = _PageBody.scroll,
       slotBottom = false,
       bottomInBar = false,
       assert((child == null) != (slivers == null), "child or slivers"),
       assert(!fit || child != null, "a page that fits has a child");

  /// A [child] that fills the page and keeps clear of the home indicator
  /// itself (a PIN pad, a camera, screens with their own buttons).
  const SheetPage.fill({
    super.key,
    required this.title,
    this.exits = const SheetExits(),
    required Widget this.child,
    this.padding = EdgeInsets.zero,
    this.bottom,
    this.action,
    this.slotBottom = false,
    this.bottomInBar = false,
  }) : _body = _PageBody.fill,
       slivers = null,
       fit = false,
       underBar = null;

  /// A [child] that lays itself out in a [SheetSplit]: only where the sheet
  /// has columns ([useSheetColumns]). No padding, no scroll of its own.
  const SheetPage.split({
    super.key,
    required this.title,
    this.exits = const SheetExits(),
    required Widget this.child,
    this.bottom,
    this.action,
    this.bottomInBar = false,
  }) : _body = _PageBody.split,
       slivers = null,
       padding = EdgeInsets.zero,
       slotBottom = false,
       fit = false,
       underBar = null;

  bool get _scrolls => _body == _PageBody.scroll;
  bool get _split => _body == _PageBody.split;

  @override
  State<SheetPage> createState() => _SheetPageState();
}

class _SheetPageState extends State<SheetPage> {
  final _under = ScrollEdgeNotifier();
  final _slot = SheetActionSlot();

  /// Whether the page has scrolled past [SheetPage.titleAfterScroll].
  final _past = ValueNotifier(false);

  /// Whether [SheetPage.underBar] shows.
  final _underBarShown = ValueNotifier(false);

  @override
  void dispose() {
    _under.dispose();
    _slot.dispose();
    _past.dispose();
    _underBarShown.dispose();
    super.dispose();
  }

  /// The bar, to measure the page's heading against.
  final _barKey = GlobalKey();

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final heading = switch (widget.title.reveal) {
      _Under(:final heading) => heading.currentContext.laidOutBox,
      _ => null,
    };
    final bar = _barKey.currentContext.laidOutBox;
    final after = widget.underBar?.after.currentContext.laidOutBox;
    if (after != null && bar != null) {
      // The top of the name, 12 into the card, as the share screen's bar.
      _underBarShown.value =
          after.localToGlobal(const Offset(0, 12)).dy <
          bar.localToGlobal(Offset(0, bar.size.height)).dy;
    }
    if (heading != null && bar != null) {
      final bottom = heading.localToGlobal(Offset(0, heading.size.height)).dy;
      _past.value = bottom < bar.localToGlobal(Offset(0, bar.size.height)).dy;
      return false;
    }
    final afterScroll = switch (widget.title.reveal) {
      _AfterScroll(:final offset) => offset,
      _ => null,
    };
    if (afterScroll != null) _past.value = n.metrics.pixels > afterScroll;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final role = _SheetPageRole.maybeOf(context);
    final title = widget.title.text;
    final onBack = widget.exits.onBack;
    final action = widget.action;
    final inBar = Sheet.actionInBar(context);
    final bottomUp =
        widget.bottomInBar &&
        useSheetColumns(context) &&
        !Sheet.of(context).floating;
    _slot.takesBottom =
        widget.slotBottom &&
        !widget._scrolls &&
        !inBar &&
        !useSheetColumns(context);
    role?.chrome[role.pageKey] = (
      back: onBack != null,
      action: inBar && (action != null || _slot.action != null),
      title: widget.title.widget?.key,
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
    // A title widget both pages have (same key) does not fade out and in:
    // the top page's stays, the one underneath is hidden under it.
    final titleKey = widget.title.widget?.key;
    final sharedTitle =
        moving && other != null && titleKey != null && other.title == titleKey;
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
          final hideTitle = widget.title.reveal is! _Always && !_past.value;
          return SheetHeader(
            title: title,
            titleWidget:
                widget.title.widget ??
                (hideTitle ? const SizedBox.shrink() : null),
            titleWidgetCentred:
                widget.title.centred || widget.title.widget == null,
            onBack: onBack,
            action: inBar ? (action ?? slotted) : null,
            onAction: slotted == null
                ? null
                : () => _slot.action?.onTap?.call(),
            closable: widget.exits.close != SheetClose.none,
            closeAtStart: widget.exits.close == SheetClose.start,
            buttons: top,
            titleOpacity: sharedTitle
                ? (top ? null : kAlwaysDismissedAnimation)
                : role?.titleOpacity,
            backOpacity: moving && other != null && !other.back
                ? role.ownOpacity
                : null,
            actionOpacity: moving && other != null && !other.action
                ? role.ownOpacity
                : null,
            extra: bottomUp ? widget.bottom : null,
          );
        },
      ),
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
    final underBar = widget.underBar?.row;
    final bar = Listener(
      behavior: HitTestBehavior.opaque,
      child: Stack(
        // The row under the bar hangs out of it.
        clipBehavior: Clip.none,
        children: [
          // Clipped to the sheet's top corners itself: it is drawn outside
          // the sheet's rounded clip, and filled the corners square.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: _SheetSurface._radius,
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
            children: [
              ...head,
              if (underBar != null)
                SizedBox(
                  height: 0,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: double.infinity,
                    child: role == null
                        ? _underBar(underBar)
                        : role.slide(_underBar(underBar)),
                  ),
                ),
            ],
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

  /// [SheetPage.underBar] on the bar's band (the band as it is with
  /// content under it), with the band's line under it instead of under the
  /// bar: it covers that line.
  Widget _underBar(Widget row) {
    final palette = YiviPalette.of(context);
    final line = 1 / MediaQuery.devicePixelRatioOf(context);
    return CompactBarDropIn(
      shown: _underBarShown,
      bar: (t) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -line),
          child: DecoratedBox(
            key: const Key("glass_sheet_under_bar"),
            decoration: BoxDecoration(
              color: ScrollEdgeBand.fill(palette, base: palette.sheet),
              border: Border(bottom: ScrollEdgeBand.lineSide(context)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                YiviSpace.x16,
                line + 4,
                YiviSpace.x16,
                10,
              ),
              child: row,
            ),
          ),
        ),
      ),
    );
  }

  /// What scrolls, and the buttons under it: [SheetPage.bottom] and
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
            primaryLeading: action.busy ? const YiviSpinner.onButton() : null,
            primaryNeutral: action.neutral,
          );
    final given = bottomUp ? null : widget.bottom;
    final bottom = button == null
        ? given
        : given == null
        ? button
        : sheetStack(given, button);
    if (_slot.takesBottom) return _slotBody(padding, child!);
    // Sideways with the way on out of the bar: at the bottom of the split's
    // left column, not in a bar across the sheet.
    // The document steps' screens lay themselves out in a split sideways
    // too ([slotBottom]).
    if ((widget._split || widget.slotBottom) &&
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
      if (!widget._scrolls) ...[
        Expanded(
          child: Padding(padding: padding, child: child),
        ),
        if (bottom != null) SheetBottomBar(child: bottom),
      ] else if (bottom == null)
        Flexible(
          child: SheetScrollView(
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
            child: SheetScrollView(
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
/// ([SheetPage.slotBottom]).
extension on _SheetPageState {
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
                ? const YiviSpinner.onButton()
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
                : sheetStack(above, _kept(!empty, row)),
          );
        },
      ),
    ];
  }
}

/// The scrolling body of a sheet, under its [SheetHeader]: it pulls the
/// sheet down from its top (see [SheetScope]), goes on under the header
/// (which clips it no more than the sheet does; see [SheetPage]), and
/// ends clear of the home indicator. [child] pads itself from the
/// sides unless [padding] does.
class SheetScrollView extends StatelessWidget {
  final Widget? child;

  /// Instead of [child]: slivers, built as they scroll into view (a long
  /// list).
  final List<Widget>? slivers;
  final EdgeInsets padding;

  /// Ends clear of the home indicator; off when a button sits under it.
  final bool clearBottom;

  const SheetScrollView({
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
    // [SheetPage]'s header (its hard scroll edge). The page clips the
    // bottom.
    final inset = _padding(context);
    final physics = _sheetScrollPhysics(context);
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

/// A sheet with the title [titleKey] over [child]: a [SheetPage] in
/// [showSheet].
Future<void> showTitledSheet({
  required BuildContext context,
  required String titleKey,
  required Widget child,
}) => showSheet<void>(
  context: context,
  builder: (context) =>
      SheetPage.scroll(title: SheetTitle(context.tr(titleKey)), child: child),
);

/// How many sheets are fully open: the band behind Android's buttons then
/// takes the sheet's colour.
abstract final class SheetCover {
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
      onChanged: () => afterFrame(_measure),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxHeight != _room) {
            _room = constraints.maxHeight;
            afterFrame(_measure);
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
    afterFrame(_measure);
  }

  @override
  void didUpdateWidget(_FitMeasure old) {
    super.didUpdateWidget(old);
    afterFrame(_measure);
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
