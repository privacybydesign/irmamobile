part of "glass_sheet.dart";

/// The top of a sheet, as the navigation bar of a native iOS sheet: the
/// title in the middle, the ways out at the sides, and in the bar the way
/// on ([action]) where [sheetActionInBar] puts it there.
///
/// - Phone: the round back button at the left when [onBack] is set,
///   [action] and the round close button at the right.
/// - Tablet (a floating form sheet): text buttons, as on an iPad: "‹ Back"
///   when [onBack] is set, else "Cancel", at the left; [action] at the
///   right; no close button (a tap outside the sheet closes it).
///
/// Explanatory text goes at the top of the sheet's scrolling content, not
/// here.
class GlassSheetHeader extends StatelessWidget {
  static Duration _switch(BuildContext context) =>
      YiviMotion.duration(context, const Duration(milliseconds: 200));

  final String title;

  /// In the title's place while not null (Add data's search field, once the
  /// list has scrolled it away): between the buttons, the title faded out.
  /// On a phone held sideways it stands next to the title instead.
  final Widget? titleWidget;
  final VoidCallback? onBack;

  /// The way on, in the bar at the right (see [sheetActionInBar]).
  final SheetAction? action;

  /// Called instead of [action]'s own callback (a slot's latest one).
  final VoidCallback? onAction;

  /// False on a page that is left by dragging its header down (the pages of
  /// adding a card) or by its way on ("Success"): no close button, no
  /// "Cancel".
  final bool closable;

  /// The close button at the start of the bar instead of the end (the
  /// first page of Add data, whose pages after it have the way on there).
  /// Without [onBack] only.
  final bool closeAtStart;

  /// The title fades while pages of [GlassSheetPages] change (the bar
  /// itself stays put); null when it simply shows.
  final Animation<double>? titleOpacity;

  /// The back button fades in or out while pages change, when the page it
  /// comes from or goes back to has none; null when it simply shows.
  final Animation<double>? backOpacity;

  /// [action] fades in or out while pages change, when the other page has
  /// none; null when it simply shows.
  final Animation<double>? actionOpacity;

  /// Off for the page under the top one: its buttons sit under the top
  /// page's own.
  final bool buttons;

  /// [titleWidget] stays centred between the buttons on a phone held
  /// sideways too, as upright (a tag, or nothing while the title waits for
  /// its heading to scroll away).
  final bool titleWidgetCentred;

  /// On a phone held sideways: something right after [titleWidget] at the
  /// start of the bar (the progress of adding a card); the bar then reads
  /// from the start: the back or close button, [titleWidget], this, and the
  /// way on at the end.
  final Widget? extra;

  const GlassSheetHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.action,
    this.onAction,
    this.closable = true,
    this.closeAtStart = false,
    this.titleOpacity,
    this.backOpacity,
    this.actionOpacity,
    this.buttons = true,
    this.titleWidgetCentred = false,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final sideways = useSheetColumns(context);
    if (sideways && extra != null && !_GlassSheetFloating.of(context)) {
      return _startRow(context);
    }
    if (sideways && this.titleWidget != null && !titleWidgetCentred) {
      return _row(context);
    }
    final palette = YiviPalette.of(context);
    final floating = _GlassSheetFloating.of(context);
    final titleWidget = this.titleWidget;
    final action = sheetActionInBar(context) ? this.action : null;
    final onBack = this.onBack;

    // Names the page (see GlassSheetPages): a screen reader reads it when
    // the page comes in. A new title on the same page (a screen changing
    // below the bar) fades in over the old one.
    final text = Semantics(
      header: true,
      namesRoute: true,
      child: AnimatedSwitcher(
        duration: _switch(context),
        child: KeyedSubtree(
          key: ValueKey(title),
          child: Text(
            title,
            key: const Key("glass_sheet_title"),
            textAlign: TextAlign.center,
            maxLines: sideways ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: palette
                .display(17)
                .copyWith(
                  height: (sideways ? 20 : 22) / 17,
                  color: palette.text,
                ),
          ),
        ),
      ),
    );
    final heading = FadeTransition(
      opacity: titleOpacity ?? kAlwaysCompleteAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            // Gone while a widget takes its place; it still names the page,
            // also for screen readers.
            opacity: titleWidget == null ? 1 : 0,
            alwaysIncludeSemantics: true,
            duration: _switch(context),
            child: text,
          ),
          AnimatedSwitcher(
            duration: _switch(context),
            child: titleWidget == null
                ? const SizedBox.shrink()
                : KeyedSubtree(
                    key: const ValueKey("glass_sheet_title_widget"),
                    child: titleWidget,
                  ),
          ),
        ],
      ),
    );

    Widget shown(Widget child) => _kept(buttons, child);
    // Through closeGlassSheet, so a [GlassSheetConfirmDismiss] can ask first.
    void close() => closeGlassSheet(context);
    final keepsClose = SheetKeepsClose.of(context);
    // A phone held sideways: the way on takes the close button's place;
    // a page without one keeps the close button.
    final adding = sideways && !floating && SheetKeepsClose.inScope(context);
    final closable = adding && action != null
        ? closeAtStart && onBack == null
        : this.closable || keepsClose || adding;
    final closeStart =
        !floating && closable && closeAtStart && onBack == null && !keepsClose;
    final Widget? start = closeStart
        ? _closeButton(context)
        : floating
        ? (onBack != null || closable
              ? shown(
                  _BarTextButton(
                    key: const Key("glass_sheet_text_back"),
                    label: FlutterI18n.translate(
                      context,
                      onBack != null ? "ui.previous" : "ui.cancel",
                    ),
                    chevron: onBack != null,
                    onTap: onBack ?? close,
                  ),
                )
              : null)
        : (onBack != null ? _backButton(onBack) : null);
    final end = <Widget>[
      if (action != null)
        Flexible(
          child: shown(
            FadeTransition(
              opacity: actionOpacity ?? kAlwaysCompleteAnimation,
              // Changes in place (a new label, the spinner, greyed out or not),
              // as the button at the bottom does; only its width eases. A
              // cross-fade showed two capsules at once.
              child: AnimatedSize(
                duration: _switch(context),
                curve: Curves.easeOutCubic,
                alignment: AlignmentDirectional.centerEnd,
                // Drawn whole while the room eases: clipped, a growing
                // capsule showed a square edge.
                clipBehavior: Clip.none,
                child: SheetBarButton(action: action, onTap: onAction),
              ),
            ),
          ),
        ),
      if (!floating && closable && !closeStart) _closeButton(context),
    ];
    return Padding(
      // A little room under the buttons, for the band once content scrolls
      // under the bar; less above them on a phone held sideways.
      padding: EdgeInsets.fromLTRB(16, sideways ? 12 : 16, 16, 4),
      child: SizedBox(
        height: 44,
        child: CustomMultiChildLayout(
          delegate: _BarLayout(
            Directionality.of(context),
            fill: titleWidget != null && !titleWidgetCentred,
          ),
          children: [
            if (start != null) LayoutId(id: _BarSlot.start, child: start),
            LayoutId(id: _BarSlot.title, child: heading),
            if (end.isNotEmpty)
              LayoutId(
                id: _BarSlot.end,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: end,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The round back button, faded with [backOpacity] while pages change.
  Widget _backButton(VoidCallback onBack) => _kept(
    buttons,
    FadeTransition(
      opacity: backOpacity ?? kAlwaysCompleteAnimation,
      child: YiviBackButton(onTap: onBack),
    ),
  );

  /// The round close button. Through [closeGlassSheet], so a
  /// [GlassSheetConfirmDismiss] can ask first.
  Widget _closeButton(BuildContext context) =>
      _kept(buttons, IrmaCloseButton(onTap: () => closeGlassSheet(context)));

  /// A phone held sideways with [extra]: one row from the start, the back
  /// button (or the close button on a first page), [titleWidget], [extra],
  /// and at the end the way on ([action]), or the close button when there is
  /// none.
  Widget _startRow(BuildContext context) {
    final action = sheetActionInBar(context) ? this.action : null;
    final onBack = this.onBack;
    Widget shown(Widget child) => _kept(buttons, child);
    final Widget? start = onBack != null
        ? _backButton(onBack)
        : closeAtStart || closable
        ? _closeButton(context)
        : null;
    final titleWidget = this.titleWidget;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          spacing: 12,
          children: [
            ?start,
            if (titleWidget != null)
              Flexible(
                flex: 3,
                child: FadeTransition(
                  opacity: titleOpacity ?? kAlwaysCompleteAnimation,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: titleWidget,
                  ),
                ),
              ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: extra,
                ),
              ),
            ),
            if (action != null)
              shown(
                FadeTransition(
                  opacity: actionOpacity ?? kAlwaysCompleteAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: SheetBarButton(action: action, onTap: onAction),
                  ),
                ),
              )
            else if (onBack != null)
              _closeButton(context),
          ],
        ),
      ),
    );
  }

  /// A phone held sideways with a search field ([titleWidget], Add data's
  /// list): one row, the back button, the title at the start, the search
  /// field next to it, and the close button.
  Widget _row(BuildContext context) {
    final palette = YiviPalette.of(context);
    final titleWidget = this.titleWidget!;
    final text = Semantics(
      header: true,
      namesRoute: true,
      child: Text(
        title,
        key: const Key("glass_sheet_title"),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: palette
            .display(17)
            .copyWith(height: 20 / 17, color: palette.text),
      ),
    );
    final heading = FadeTransition(
      opacity: titleOpacity ?? kAlwaysCompleteAnimation,
      child: text,
    );
    return Padding(
      // A little room under the buttons, for the band once content scrolls
      // under the bar.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          spacing: 12,
          children: [
            if (onBack case final onBack?) _backButton(onBack),
            heading,
            Expanded(
              child: FadeTransition(
                opacity: titleOpacity ?? kAlwaysCompleteAnimation,
                child: titleWidget,
              ),
            ),
            if (closable) _closeButton(context),
          ],
        ),
      ),
    );
  }
}

enum _BarSlot { start, title, end }

/// The bar's three parts: the buttons at the start and the end as wide as
/// they are, the title in the middle of the bar, kept clear of the wider
/// side on both sides so it stays centred.
class _BarLayout extends MultiChildLayoutDelegate {
  final TextDirection direction;

  /// The title's place fills the room between the buttons, not centred
  /// (a search field in it).
  final bool fill;

  _BarLayout(this.direction, {this.fill = false});

  static const double _gap = 12;

  @override
  void performLayout(Size size) {
    // A long label (the success's "Back to {requestor}") shortens itself
    // rather than squeeze the title out.
    final loose = BoxConstraints.loose(Size(size.width * 0.42, size.height));
    var startWidth = 0.0, endWidth = 0.0;
    Size? startSize, endSize;
    if (hasChild(_BarSlot.start)) {
      startSize = layoutChild(_BarSlot.start, loose);
      startWidth = startSize.width;
    }
    if (hasChild(_BarSlot.end)) {
      endSize = layoutChild(_BarSlot.end, loose);
      endWidth = endSize.width;
    }
    final ltr = direction == TextDirection.ltr;
    double clear(double width) => width == 0 ? 0.0 : width + _gap;
    // Centred: as much room on either side. Filling: up to each button.
    final side = math.max(startWidth, endWidth);
    final before = fill ? clear(ltr ? startWidth : endWidth) : clear(side);
    final after = fill ? clear(ltr ? endWidth : startWidth) : clear(side);
    final titleWidth = math.max(0.0, size.width - before - after);
    final titleSize = layoutChild(
      _BarSlot.title,
      BoxConstraints(
        minWidth: titleWidth,
        maxWidth: titleWidth,
        maxHeight: size.height,
      ),
    );
    positionChild(
      _BarSlot.title,
      Offset(before, (size.height - titleSize.height) / 2),
    );
    if (startSize != null) {
      positionChild(
        _BarSlot.start,
        Offset(
          ltr ? 0 : size.width - startSize.width,
          (size.height - startSize.height) / 2,
        ),
      );
    }
    if (endSize != null) {
      positionChild(
        _BarSlot.end,
        Offset(
          ltr ? size.width - endSize.width : 0,
          (size.height - endSize.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_BarLayout old) =>
      old.direction != direction || old.fill != fill;
}

/// A text button in the bar of a tablet's form sheet: "Cancel", or "‹ Back"
/// with a chevron.
class _BarTextButton extends StatelessWidget {
  final String label;
  final bool chevron;
  final VoidCallback onTap;

  const _BarTextButton({
    super.key,
    required this.label,
    required this.chevron,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chevron)
                Icon(Icons.chevron_left_rounded, size: 28, color: palette.link),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: chevron ? 0 : 4,
                  end: 4,
                ),
                child: Text(
                  label,
                  style: palette.body(17).copyWith(color: palette.link),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
