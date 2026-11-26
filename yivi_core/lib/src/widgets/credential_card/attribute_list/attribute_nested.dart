part of "../card_attribute_list.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Nested claims.
//
// Panels in panels. A top-level object or list is a row that folds it in
// place, above a box with the object's fields or a box per item. Every object
// and every item is a box, at every level, the name of a field outside the
// box it names. The items of a list of more than one have a header with
// their place ("1 van 2") that folds them, also inside an open box.
// Everything starts open. Where [_Ctx.foldable] is off, nothing folds.
// ─────────────────────────────────────────────────────────────────────────────

class _Ctx {
  // Folding is offered.
  final bool foldable;
  final bool showDividers;
  final bool disclosure;
  final CredentialCardLayout layout;
  final String? matchedTag;
  final String? mismatchedTag;
  final String? hideLabel;

  /// Said of a value the requestor keeps, beside its marker; null: no
  /// markers.
  final String? keptLabel;

  const _Ctx({
    required this.foldable,
    required this.showDividers,
    required this.disclosure,
    required this.layout,
    this.matchedTag,
    this.mismatchedTag,
    this.hideLabel,
    this.keptLabel,
  });
}

// ── The list's own rows ──────────────────────────────────────────────────────

class _NestedList extends StatelessWidget {
  final List<AttributeNode> nodes;
  final _Ctx ctx;

  const _NestedList({required this.nodes, required this.ctx});

  static bool _lined(AttributeNode n) => isNestedNode(n) || rowDrawsBorder(n);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < nodes.length; i++)
          _row(
            context,
            nodes[i],
            isFirst: i == 0,
            divider:
                ctx.showDividers && i + 1 < nodes.length && _lined(nodes[i]),
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    AttributeNode node, {
    required bool isFirst,
    required bool divider,
  }) {
    if (isNestedNode(node)) {
      final g = node as GroupNode;
      return _Fold(
        key: ValueKey(claimPathKey(g.path)),
        group: g,
        ctx: ctx,
        divider: divider,
      );
    }
    final row = _FlatRow(node: node, isFirst: isFirst, ctx: ctx);
    if (!divider) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Container(height: 1, color: AttributeColors.of(context).divider),
      ],
    );
  }
}

/// A top-level object or list: a row that folds it, then the object as one
/// card or the list as a column of cards. Starts open.
class _Fold extends StatefulWidget {
  final GroupNode group;
  final _Ctx ctx;
  // Draw a line below the row while folded, as below an ordinary row.
  final bool divider;

  const _Fold({
    super.key,
    required this.group,
    required this.ctx,
    required this.divider,
  });

  @override
  State<_Fold> createState() => _FoldState();
}

class _FoldState extends State<_Fold> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final ctx = widget.ctx;
    final label = groupLabel(g);
    final list = isListNode(g);
    final open = _open || !ctx.foldable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FoldHeader(
          title: label,
          count: list ? g.children.length : null,
          summary: open ? null : _summary(context, [g]),
          titleStyle: attributeLabelStyle(context, layout: ctx.layout),
          summaryStyle: attributeValueStyle(
            context,
            AttributeColors.of(context).value,
            layout: ctx.layout,
          ),
          minHeight: 60,
          open: open,
          onTap: ctx.foldable ? () => setState(() => _open = !_open) : null,
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.only(bottom: YiviSpace.x12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: list
                  ? [
                      for (final (i, item)
                          in g.children.cast<ItemNode>().indexed)
                        _ItemBox(
                          key: ValueKey(claimPathKey(item.path)),
                          item: item,
                          index: i,
                          count: g.children.length,
                          listLabel: label,
                          level: 0,
                          ctx: ctx,
                        ),
                    ]
                  : [
                      _Box(
                        level: 0,
                        child: _BoxBody(nodes: g.children, level: 0, ctx: ctx),
                      ),
                    ],
            ),
          )
        // The list's own line, as under every other row.
        else if (widget.divider)
          Container(height: 1, color: AttributeColors.of(context).divider),
      ],
    );
  }
}

/// The row of a fold: a label (and count) over a one-line summary while
/// folded, and a chevron. Without [onTap] it is a plain heading.
class _FoldHeader extends StatelessWidget {
  final String title;
  final bool titleMuted;
  final int? count;
  final String? summary;
  final TextStyle titleStyle;
  final TextStyle summaryStyle;
  final double minHeight;
  final bool open;
  final VoidCallback? onTap;

  const _FoldHeader({
    required this.title,
    this.titleMuted = false,
    required this.count,
    required this.summary,
    required this.titleStyle,
    required this.summaryStyle,
    required this.minHeight,
    required this.open,
    required this.onTap,
  });

  /// Marks a fold's heading, so readers of the list (and tests) can tell it
  /// from an attribute's label.
  static const headingKey = Key("attribute_fold_header");

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final row = ConstrainedBox(
      key: headingKey,
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: YiviSpace.x8),
        child: Row(
          spacing: YiviSpace.x8,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: titleMuted
                        ? titleStyle.copyWith(color: palette.secondaryText)
                        : titleStyle,
                  ),
                  if (summary case final summary?)
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: summaryStyle,
                    ),
                ],
              ),
            ),
            if (count case final count?) StatusChip(label: "$count"),
            if (onTap != null)
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: YiviMotion.quick,
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 22,
                  color: palette.faint,
                ),
              ),
          ],
        ),
      ),
    );
    if (onTap == null) return Semantics(header: true, child: row);
    return Semantics(
      button: true,
      expanded: open,
      label: [title, if (count != null) "$count", ?summary].join(", "),
      excludeSemantics: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// One box of the value list: an object, or an item of a list. Boxes
/// alternate: tinted in the white card ([level] 0, 2, …), white in a tinted
/// one. Every box is the same: 8 above it, 12 inside it, corners 8; the
/// outermost keeps the card's 16 at its sides.
class _Box extends StatelessWidget {
  final int level;
  final Widget child;
  const _Box({super.key, required this.level, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final tinted = level.isEven;
    return Padding(
      padding: const EdgeInsets.only(top: YiviSpace.x8),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          // The design's panel: a step off the white group it sits in,
          // lighter than the page tint.
          color: tinted
              ? (palette.isDark
                    ? const Color(0xFF222831)
                    : const Color(0xFFF2F7FA))
              : palette.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: level == 0 ? YiviSpace.x16 : YiviSpace.x12,
            vertical: YiviSpace.x12 - YiviSpace.x4,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// One item of a list, in its own box. A list of more than one item gives
/// every item the same header, its place ("1 van 2"), which folds it; the
/// item of a one-item list has no header and does not fold on its own. No
/// value is ever the item's title: every value is a labelled row.
class _ItemBox extends StatefulWidget {
  final ItemNode item;
  final int index;
  final int count;
  final String listLabel;
  final int level;
  final _Ctx ctx;

  const _ItemBox({
    super.key,
    required this.item,
    required this.index,
    required this.count,
    required this.listLabel,
    required this.level,
    required this.ctx,
  });

  @override
  State<_ItemBox> createState() => _ItemBoxState();
}

class _ItemBoxState extends State<_ItemBox> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final palette = YiviPalette.of(context);
    final body = widget.item.children;
    final header = widget.count > 1;
    final foldable = header && ctx.foldable && body.isNotEmpty;
    final open = _open || !foldable;

    return _Box(
      level: widget.level,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header)
            _FoldHeader(
              title: context.tr("credential.nested.place", {
                "index": "${widget.index + 1}",
                "count": "${widget.count}",
              }),
              titleMuted: true,
              count: null,
              summary: open ? null : _summary(context, body),
              titleStyle: palette.display(14),
              summaryStyle: palette
                  .body(13)
                  .copyWith(color: palette.secondaryText),
              minHeight: 36,
              open: open,
              onTap: foldable ? () => setState(() => _open = !_open) : null,
            ),
          if (open && body.isNotEmpty)
            _BoxBody(nodes: body, level: widget.level, ctx: ctx),
        ],
      ),
    );
  }
}

// ── Inside a box ─────────────────────────────────────────────────────────────

/// What a box holds, at any depth: values as rows; an object as its name
/// (the small grey label, outside the box) and a box with its fields; a list
/// as its name with a count and a box per item.
class _BoxBody extends StatelessWidget {
  final List<AttributeNode> nodes;
  final int level;
  final _Ctx ctx;

  const _BoxBody({required this.nodes, required this.level, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final n in nodes)
          if (!isNestedNode(n))
            _FlatRow(node: n, isFirst: false, ctx: ctx)
          else
            ..._nested(context, n as GroupNode),
      ],
    );
  }

  List<Widget> _nested(BuildContext context, GroupNode g) {
    final label = groupLabel(g);
    if (!isListNode(g)) {
      return [
        _FieldName(text: label),
        _Box(
          key: ValueKey(claimPathKey(g.path)),
          level: level + 1,
          child: _BoxBody(nodes: g.children, level: level + 1, ctx: ctx),
        ),
      ];
    }
    final items = g.children.cast<ItemNode>();
    return [
      _FieldName(text: label, count: items.length),
      for (final (i, item) in items.indexed)
        _ItemBox(
          key: ValueKey(claimPathKey(item.path)),
          item: item,
          index: i,
          count: items.length,
          listLabel: label,
          level: level + 1,
          ctx: ctx,
        ),
    ];
  }
}

/// The name of an object or list inside a box: the small grey label, with
/// the count of a list.
class _FieldName extends StatelessWidget {
  final String text;
  final int? count;
  const _FieldName({required this.text, this.count});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      key: _FoldHeader.headingKey,
      padding: const EdgeInsets.only(top: YiviSpace.x12),
      child: Semantics(
        header: true,
        child: Row(
          spacing: YiviSpace.x8,
          children: [
            Flexible(
              child: Text(
                text,
                style: palette
                    .body(12, weight: FontWeight.w600)
                    .copyWith(color: palette.secondaryText),
              ),
            ),
            if (count case final count?) StatusChip(label: "$count"),
          ],
        ),
      ),
    );
  }
}

// ── Words for the tree ──────────────────────────────────────────────────────

Iterable<String> _values(BuildContext context, AttributeNode n) sync* {
  switch (n) {
    case RowNode r
        when r.attribute.value != null && !isImageAttribute(r.attribute):
      yield formatAttributeValue(context, r.attribute.value!);
    case PrimArrayNode p:
      for (final v in p.values) {
        yield formatAttributeValue(context, v);
      }
    default:
      for (final c in nodeChildren(n) ?? const <AttributeNode>[]) {
        yield* _values(context, c);
      }
  }
}

/// An item's first value, for a summary: its first text value, else its
/// place in the list ("Alignment 2").
String _itemFirst(BuildContext context, ItemNode item, String listLabel) {
  final first = item.children.firstWhereOrNull(
    (c) => c is RowNode && c.attribute.value?.type == AttributeType.string,
  );
  if (first is RowNode) {
    return formatAttributeValue(context, first.attribute.value!);
  }
  return context.tr("credential.nested.item", {
    "label": listLabel,
    "number": "${itemNumber(item)}",
  });
}

/// One line for something folded: its own plain values; else the first
/// values of the items of its lists; else every value in it.
String _summary(BuildContext context, List<AttributeNode> nodes) {
  final plain = [
    for (final n in nodes)
      if (n is RowNode) ..._values(context, n),
  ];
  if (plain.isNotEmpty) return plain.join(", ");
  final names = [
    for (final n in nodes)
      if (isListNode(n))
        for (final i in (n as GroupNode).children.cast<ItemNode>())
          _itemFirst(context, i, groupLabel(n)),
  ];
  if (names.isNotEmpty) return names.join(", ");
  return nodes.expand((n) => _values(context, n)).join(", ");
}
