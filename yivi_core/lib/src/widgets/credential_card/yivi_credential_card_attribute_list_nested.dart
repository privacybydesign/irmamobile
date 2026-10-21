part of "yivi_credential_card_attribute_list.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Nested claims (design option C, canvas page "Nested claims").
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

  const _Ctx({
    required this.foldable,
    required this.showDividers,
    required this.disclosure,
    required this.layout,
  });
}

// ── Shape of the tree ────────────────────────────────────────────────────────

/// Makes every array a [_GroupNode] whose children are all items, and drops
/// headers that only repeat what is below them.
List<_Node> _normalize(List<_Node> nodes) {
  final out = <_Node>[];
  var i = 0;
  while (i < nodes.length) {
    final n = nodes[i];
    if (n is _ItemNode) {
      // Items of an array that has no header of its own.
      final run = <_ItemNode>[];
      while (i < nodes.length && nodes[i] is _ItemNode) {
        run.add(nodes[i] as _ItemNode);
        i++;
      }
      final first = run.first;
      out.add(
        _GroupNode(
          label: first.parentLabel,
          path: first.path.sublist(0, first.path.length - 1),
          children: [for (final item in run) _normalizeItem(item)],
        ),
      );
      continue;
    }
    i++;
    if (n is! _GroupNode) {
      out.add(n);
      continue;
    }
    // A list of plain values under a header of the same name.
    if (n.children.length == 1 &&
        n.children.first is _PrimArrayNode &&
        n.label != null &&
        (n.children.first as _PrimArrayNode).label == n.label) {
      out.add(n.children.first);
      continue;
    }
    final allItems =
        n.children.isNotEmpty && n.children.every((c) => c is _ItemNode);
    out.add(
      _GroupNode(
        label: n.label,
        path: n.path,
        children: allItems
            ? [for (final c in n.children) _normalizeItem(c as _ItemNode)]
            : _normalize(n.children),
      ),
    );
  }
  return out;
}

_ItemNode _normalizeItem(_ItemNode item) {
  var children = item.children;
  // A header at the item's own path wraps the item's values.
  if (children.length == 1 &&
      children.first is _GroupNode &&
      listEquals((children.first as _GroupNode).path, item.path)) {
    children = (children.first as _GroupNode).children;
  }
  return _ItemNode(
    parentLabel: item.parentLabel,
    itemIndex: item.itemIndex,
    path: item.path,
    children: _normalize(children),
  );
}

bool _isList(_Node n) =>
    n is _GroupNode &&
    n.children.isNotEmpty &&
    n.children.every((c) => c is _ItemNode);

bool _isNested(_Node n) => n is _GroupNode && n.children.isNotEmpty;

String _labelOf(_GroupNode g) =>
    g.label ??
    g.path.lastWhere((s) => s is String, orElse: () => "").toString();

/// An item's title: its first value, when that is text.
_RowNode? _titleRow(_ItemNode item) {
  final first = item.children.firstOrNull;
  if (first is _RowNode &&
      first.attribute.value?.type == schemaless.AttributeType.string) {
    return first;
  }
  return null;
}

/// The item's place in the credential's list, counted from 1.
int _itemNumber(_ItemNode item) {
  final last = item.path.lastOrNull;
  return last is num ? last.toInt() + 1 : item.itemIndex;
}

/// The item's name: its title, or else its place in the list. Without a
/// title it is drawn muted, so it does not read as a shared value.
({String text, bool muted}) _itemName(
  BuildContext context,
  _ItemNode item,
  String listLabel,
) {
  final title = _titleRow(item);
  if (title != null) {
    return (
      text: formatAttributeValue(context, title.attribute.value!),
      muted: false,
    );
  }
  return (
    text: FlutterI18n.translate(
      context,
      "credential.nested.item",
      translationParams: {"label": listLabel, "number": "${_itemNumber(item)}"},
    ),
    muted: true,
  );
}

/// What an item holds, without its title.
List<_Node> _itemBody(_ItemNode item) =>
    _titleRow(item) == null ? item.children : item.children.sublist(1);

Iterable<String> _values(BuildContext context, _Node n) sync* {
  switch (n) {
    case _RowNode r when r.attribute.value != null && !_isImage(r.attribute):
      yield formatAttributeValue(context, r.attribute.value!);
    case _PrimArrayNode p:
      for (final v in p.values) {
        yield formatAttributeValue(context, v);
      }
    case _GroupNode g:
      for (final c in g.children) {
        yield* _values(context, c);
      }
    case _ItemNode i:
      for (final c in i.children) {
        yield* _values(context, c);
      }
    default:
      break;
  }
}

/// One line for something folded: a list's item names, else its values.
String _summary(BuildContext context, List<_Node> nodes) {
  final names = [
    for (final n in nodes)
      if (_isList(n))
        for (final i in (n as _GroupNode).children.cast<_ItemNode>())
          _itemName(context, i, _labelOf(n)).text,
  ];
  if (names.isNotEmpty) return names.join(", ");
  return nodes.expand((n) => _values(context, n)).join(", ");
}

// ── The list's own rows ──────────────────────────────────────────────────────

class _NestedList extends StatelessWidget {
  final List<_Node> nodes;
  final _Ctx ctx;

  const _NestedList({required this.nodes, required this.ctx});

  static bool _lined(_Node n) => _isNested(n) || _rowDrawsBorder(n);

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
    _Node node, {
    required bool isFirst,
    required bool divider,
  }) {
    if (_isNested(node)) {
      final g = node as _GroupNode;
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
  final _GroupNode group;
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
    final palette = YiviPalette.of(context);
    final label = _labelOf(g);
    final list = _isList(g);
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
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: list
                  ? [
                      for (final item in g.children.cast<_ItemNode>())
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
        else if (widget.divider)
          Container(height: 1, color: palette.divider),
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

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 8,
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
            if (count case final count?) _CountChip(count: count),
            if (onTap != null)
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
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
  final _ItemNode item;
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
    final body = _itemBody(widget.item);
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
              padding: const EdgeInsets.only(bottom: 4),
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
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
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
  final List<_Node> nodes;
  final _Ctx ctx;

  const _CardBody({required this.nodes, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    void add(List<_Node> nodes) {
      for (final n in nodes) {
        if (!_isNested(n)) {
          children.add(_FlatRow(node: n, isFirst: false, ctx: ctx));
          continue;
        }
        final g = n as _GroupNode;
        final label = _labelOf(g);
        if (!_isList(g)) {
          children.add(_BlockName(text: label, line: children.isNotEmpty));
          add(g.children);
          continue;
        }
        children.add(_ListHeading(label: label, count: g.children.length));
        for (final (i, item) in g.children.cast<_ItemNode>().indexed) {
          final name = _itemName(context, item, label);
          children.add(
            _BlockName(text: name.text, muted: name.muted, line: i > 0),
          );
          add(_itemBody(item));
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
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Semantics(
        header: true,
        child: Row(
          spacing: 6,
          children: [
            Flexible(
              child: Text(
                label,
                style: palette
                    .body(12, weight: FontWeight.w600)
                    .copyWith(color: palette.secondaryText),
              ),
            ),
            _CountChip(count: count),
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
      margin: const EdgeInsets.only(top: 8),
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

class _CountChip extends StatelessWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      height: 22,
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: StadiumBorder(side: BorderSide(color: palette.outline)),
      ),
      alignment: Alignment.center,
      child: Text(
        "$count",
        style: palette
            .body(12, weight: FontWeight.w600)
            .copyWith(color: palette.heading, height: 1),
      ),
    );
  }
}
