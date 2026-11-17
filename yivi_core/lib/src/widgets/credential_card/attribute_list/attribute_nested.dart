part of "../yivi_credential_card_attribute_list.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Nested claims.
//
// A top-level object or list is a row that folds it in place; the items of a
// list are cards in one column, each folding on its own. Everything starts
// open, so nothing needs a tap to be read. Whatever a card holds, at any
// depth, is drawn inside it. When the values are being shared or compared,
// nothing folds at all.
// ─────────────────────────────────────────────────────────────────────────────

class _Ctx {
  // Folding is offered; false when the values are shared or compared.
  final bool foldable;
  final bool showDividers;
  final bool disclosure;
  final CredentialCardLayout layout;
  final String? matchedTag;
  final String? mismatchedTag;
  final String? hideLabel;

  const _Ctx({
    required this.foldable,
    required this.showDividers,
    required this.disclosure,
    required this.layout,
    this.matchedTag,
    this.mismatchedTag,
    this.hideLabel,
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
              spacing: YiviSpace.x8,
              children: list
                  ? [
                      for (final item in g.children.cast<ItemNode>())
                        _ItemCard(
                          key: ValueKey(claimPathKey(item.path)),
                          item: item,
                          listLabel: label,
                          ctx: ctx,
                        ),
                    ]
                  : [
                      _Card(
                        child: _CardBody(nodes: g.children, ctx: ctx),
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

/// One item of a top-level list. Folds on its own to its name and a
/// summary; starts open.
class _ItemCard extends StatefulWidget {
  final ItemNode item;
  final String listLabel;
  final _Ctx ctx;

  const _ItemCard({
    super.key,
    required this.item,
    required this.listLabel,
    required this.ctx,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final palette = YiviPalette.of(context);
    final name = _itemName(context, widget.item, widget.listLabel);
    final body = itemBody(widget.item);
    final open = _open || !ctx.foldable || body.isEmpty;

    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FoldHeader(
            title: name.text,
            titleMuted: name.muted,
            count: null,
            summary: open ? null : _summary(context, body),
            titleStyle: palette.display(15),
            summaryStyle: palette
                .body(13)
                .copyWith(color: palette.secondaryText),
            minHeight: 44,
            open: open,
            onTap: ctx.foldable && body.isNotEmpty
                ? () => setState(() => _open = !_open)
                : null,
          ),
          if (open && body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: YiviSpace.x4),
              child: _CardBody(nodes: body, ctx: ctx),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        // The design's panel: a step off the white group it sits in, lighter
        // than the page tint.
        color: palette.isDark
            ? const Color(0xFF222831)
            : const Color(0xFFF2F7FA),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          YiviSpace.x16,
          YiviSpace.x4,
          YiviSpace.x16,
          YiviSpace.x8,
        ),
        child: child,
      ),
    );
  }
}

// ── Inside a card: everything drawn, nothing folds ───────────────────────────

/// What a card holds, at any depth: values as rows; a list as a small heading
/// with its count and each item as a named block under a thin line; an
/// object as a named block.
class _CardBody extends StatelessWidget {
  final List<AttributeNode> nodes;
  final _Ctx ctx;

  const _CardBody({required this.nodes, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    void add(List<AttributeNode> nodes) {
      for (final n in nodes) {
        if (!isNestedNode(n)) {
          children.add(_FlatRow(node: n, isFirst: false, ctx: ctx));
          continue;
        }
        final g = n as GroupNode;
        final label = groupLabel(g);
        if (!isListNode(g)) {
          children.add(_BlockName(text: label, line: children.isNotEmpty));
          add(g.children);
          continue;
        }
        children.add(_ListHeading(label: label, count: g.children.length));
        for (final (i, item) in g.children.cast<ItemNode>().indexed) {
          final name = _itemName(context, item, label);
          children.add(
            _BlockName(text: name.text, muted: name.muted, line: i > 0),
          );
          add(itemBody(item));
        }
      }
    }

    add(nodes);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _ListHeading extends StatelessWidget {
  final String label;
  final int count;
  const _ListHeading({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      key: _FoldHeader.headingKey,
      padding: const EdgeInsets.only(top: YiviSpace.x12, bottom: YiviSpace.x2),
      child: Semantics(
        header: true,
        child: Row(
          spacing: YiviSpace.x8,
          children: [
            Flexible(
              child: Text(
                label,
                style: palette
                    .body(12, weight: FontWeight.w600)
                    .copyWith(color: palette.secondaryText),
              ),
            ),
            StatusChip(label: "$count"),
          ],
        ),
      ),
    );
  }
}

/// The name of an item or object inside a card, under a thin line unless it
/// comes right after its list's heading.
class _BlockName extends StatelessWidget {
  final String text;
  final bool muted;
  final bool line;
  const _BlockName({required this.text, this.muted = false, this.line = true});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      key: _FoldHeader.headingKey,
      margin: const EdgeInsets.only(top: YiviSpace.x8),
      padding: EdgeInsets.only(top: line ? 8 : 0),
      decoration: line
          ? BoxDecoration(
              border: Border(top: BorderSide(color: palette.divider)),
            )
          : null,
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: palette
              .body(14, weight: FontWeight.w600)
              .copyWith(color: muted ? palette.secondaryText : palette.text),
        ),
      ),
    );
  }
}

// ── Words for the tree ──────────────────────────────────────────────────────

/// The item's name: its title, or else its place in the list. Without a
/// title it is drawn muted, so it does not read as a shared value.
({String text, bool muted}) _itemName(
  BuildContext context,
  ItemNode item,
  String listLabel,
) {
  final title = itemTitleRow(item);
  if (title != null) {
    return (
      text: formatAttributeValue(context, title.attribute.value!),
      muted: false,
    );
  }
  return (
    text: context.tr("credential.nested.item", {
      "label": listLabel,
      "number": "${itemNumber(item)}",
    }),
    muted: true,
  );
}

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

/// One line for something folded: a list's item names, else its values.
String _summary(BuildContext context, List<AttributeNode> nodes) {
  final names = [
    for (final n in nodes)
      if (isListNode(n))
        for (final i in (n as GroupNode).children.cast<ItemNode>())
          _itemName(context, i, groupLabel(n)).text,
  ];
  if (names.isNotEmpty) return names.join(", ");
  return nodes.expand((n) => _values(context, n)).join(", ");
}
