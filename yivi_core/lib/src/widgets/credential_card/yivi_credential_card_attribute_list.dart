import "dart:convert";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../models/translated_value.dart";
import "../../theme/theme.dart";
import "../irma_app_bar.dart";

class YiviCredentialCardAttributeList extends StatelessWidget {
  final List<schemaless.Attribute> attributes;
  final List<schemaless.Attribute>? compareTo;
  // When true, each leaf/primarray row draws a 1px horizontal divider at
  // its bottom (suppressed on the last row of any parent group).
  final bool showDividers;

  const YiviCredentialCardAttributeList(
    this.attributes, {
    this.compareTo,
    this.showDividers = false,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...attributes]
      ..sort((a, b) {
        final aIsImage =
            a.value?.type == schemaless.AttributeType.image ||
            a.value?.type == schemaless.AttributeType.base64Image;
        final bIsImage =
            b.value?.type == schemaless.AttributeType.image ||
            b.value?.type == schemaless.AttributeType.base64Image;
        if (aIsImage == bIsImage) return 0;
        return aIsImage ? 1 : -1;
      });

    final tree = _buildTree(sorted, compareTo: compareTo);
    final items = _flatten(tree);

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        for (var i = 0; i < items.length; i++)
          _RenderItemView(
            item: items[i],
            nextDepth: i + 1 < items.length ? items[i + 1].depth : -1,
            showDivider: showDividers,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree model
// ─────────────────────────────────────────────────────────────────────────────

sealed class _Node {
  const _Node();
}

class _GroupNode extends _Node {
  final TranslatedValue? label;
  final List<dynamic> path;
  final List<_Node> children;
  _GroupNode({this.label, required this.path, required this.children});
}

class _ItemNode extends _Node {
  final TranslatedValue? parentLabel;
  final int itemIndex;
  int totalItems;
  final List<dynamic> path;
  final List<_Node> children;
  _ItemNode({
    this.parentLabel,
    required this.itemIndex,
    required this.path,
    required this.children,
  }) : totalItems = 0;
}

class _RowNode extends _Node {
  final schemaless.Attribute attribute;
  final schemaless.AttributeValue? compareToValue;
  final bool hasCompareTo;
  _RowNode({
    required this.attribute,
    required this.hasCompareTo,
    this.compareToValue,
  });
}

class _PrimArrayNode extends _Node {
  final TranslatedValue label;
  final List<schemaless.AttributeValue> values;
  _PrimArrayNode({required this.label, required this.values});
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree builder
// ─────────────────────────────────────────────────────────────────────────────

String _pathKey(List<dynamic> p) => jsonEncode(p);

class _StackFrame {
  final List<dynamic> path;
  final List<_Node> childrenArr;
  final bool isItem;
  _StackFrame({
    required this.path,
    required this.childrenArr,
    required this.isItem,
  });
}

class _PrimCollector {
  final TranslatedValue label;
  final List<schemaless.AttributeValue> values;
  final List<_Node> parent;
  _PrimCollector({
    required this.label,
    required this.values,
    required this.parent,
  });
}

_GroupNode _buildTree(
  List<schemaless.Attribute> attrs, {
  List<schemaless.Attribute>? compareTo,
}) {
  final headers = <String, schemaless.Attribute>{};
  for (final e in attrs) {
    if (e.value == null) headers[_pathKey(e.claimPath)] = e;
  }

  schemaless.AttributeValue? lookupCompare(List<dynamic> claimPath) {
    return compareTo
        ?.firstWhereOrNull((c) => listEquals(c.claimPath, claimPath))
        ?.value;
  }

  final root = _GroupNode(path: const [], children: []);
  final stack = <_StackFrame>[
    _StackFrame(path: const [], childrenArr: root.children, isItem: false),
  ];
  final primCollectors = <String, _PrimCollector>{};

  void flushPrim(String key) {
    final c = primCollectors[key];
    if (c == null) return;
    c.parent.add(_PrimArrayNode(label: c.label, values: c.values));
    primCollectors.remove(key);
  }

  void flushAllPrims() {
    for (final k in primCollectors.keys.toList()) {
      flushPrim(k);
    }
  }

  bool isPrefix(List<dynamic> prefix, List<dynamic> p) {
    if (prefix.length > p.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i] != p[i]) return false;
    }
    return true;
  }

  void popToPrefix(List<dynamic> p) {
    while (stack.length > 1) {
      final top = stack.last;
      if (top.path.length > p.length || !isPrefix(top.path, p)) {
        stack.removeLast();
        continue;
      }
      break;
    }
  }

  void ensureItemFrames(List<dynamic> p) {
    for (var i = 0; i < p.length; i++) {
      if (p[i] is! int) continue;
      final itemPath = p.sublist(0, i + 1);
      final itemKey = _pathKey(itemPath);
      final alreadyOpen = stack.any(
        (f) => f.isItem && _pathKey(f.path) == itemKey,
      );
      if (alreadyOpen) continue;

      final arrayHeaderPath = p.sublist(0, i);
      popToPrefix(arrayHeaderPath);
      final arrayFrame = stack.last;
      final itemIndex =
          arrayFrame.childrenArr.whereType<_ItemNode>().length + 1;
      final parentHeader = headers[_pathKey(arrayHeaderPath)];
      final item = _ItemNode(
        parentLabel: parentHeader?.effectiveDisplayName,
        itemIndex: itemIndex,
        path: itemPath,
        children: [],
      );
      arrayFrame.childrenArr.add(item);
      stack.add(
        _StackFrame(path: itemPath, childrenArr: item.children, isItem: true),
      );
    }
  }

  for (final e in attrs) {
    final p = e.claimPath;

    if (e.value == null) {
      // Header → opens a group at this path.
      flushAllPrims();
      popToPrefix(p);
      ensureItemFrames(p);
      popToPrefix(p);

      final parentFrame = stack.last;
      final group = _GroupNode(
        label: e.effectiveDisplayName,
        path: p,
        children: [],
      );
      parentFrame.childrenArr.add(group);
      stack.add(
        _StackFrame(path: p, childrenArr: group.children, isItem: false),
      );
      continue;
    }

    // Leaf attribute.
    final parentArrPath = p.length > 1
        ? p.sublist(0, p.length - 1)
        : const <dynamic>[];
    final parentKey = _pathKey(parentArrPath);
    for (final k in primCollectors.keys.toList()) {
      if (k != parentKey) flushPrim(k);
    }

    final tail = p.last;
    final hasDisplayName = e.displayName.isNotEmpty;

    if (tail is int && !hasDisplayName) {
      // Primitive in array — collect under the parent header's label.
      final headerEntry = headers[parentKey];
      final label = headerEntry?.effectiveDisplayName ?? e.effectiveDisplayName;

      popToPrefix(parentArrPath);
      final frame = stack.last;

      primCollectors.putIfAbsent(
        parentKey,
        () =>
            _PrimCollector(label: label, values: [], parent: frame.childrenArr),
      );
      primCollectors[parentKey]!.values.add(e.value!);
      continue;
    }

    ensureItemFrames(p);
    popToPrefix(parentArrPath);
    final frame = stack.last;
    frame.childrenArr.add(
      _RowNode(
        attribute: e,
        hasCompareTo: compareTo != null,
        compareToValue: lookupCompare(p),
      ),
    );
  }

  flushAllPrims();
  _stampItemTotals(root);
  return root;
}

void _stampItemTotals(_Node node) {
  List<_Node>? children;
  if (node is _GroupNode) children = node.children;
  if (node is _ItemNode) children = node.children;
  if (children == null) return;

  final itemCount = children.whereType<_ItemNode>().length;
  for (final c in children) {
    if (c is _ItemNode) c.totalItems = itemCount;
    _stampItemTotals(c);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flatten — walk the tree depth-first and produce a list of rows. Each row
// is a single _RenderItem that knows its depth and whether it's the last
// child of its parent (used to suppress the bottom divider, matching the
// design's "borderBottom: isLast ? 'none'" rule).
// ─────────────────────────────────────────────────────────────────────────────

class _RenderItem {
  final _Node node;
  final int depth;
  final bool isLast;
  // Depth of the previously emitted row, or -1 if this is the first row.
  // Used by the renderer to decide which guide-line segments are newly
  // introduced (and should be inset slightly from the row top) versus
  // continuations from the row above (which stay flush so the line connects).
  final int previousDepth;
  _RenderItem({
    required this.node,
    required this.depth,
    required this.isLast,
    required this.previousDepth,
  });
}

List<_RenderItem> _flatten(_GroupNode root) {
  final out = <_RenderItem>[];
  var lastDepth = -1;

  void emit(_Node node, int depth, bool isLast) {
    out.add(
      _RenderItem(
        node: node,
        depth: depth,
        isLast: isLast,
        previousDepth: lastDepth,
      ),
    );
    lastDepth = depth;
  }

  void visit(List<_Node> children, int depth) {
    for (var i = 0; i < children.length; i++) {
      final c = children[i];
      final isLast = i == children.length - 1;

      if (c is _RowNode || c is _PrimArrayNode) {
        emit(c, depth, isLast);
        continue;
      }

      if (c is _GroupNode) {
        // Empty group → render as a single labelled row.
        if (c.children.isEmpty) {
          emit(c, depth, isLast);
          continue;
        }
        // Collapse: only child is a same-label primarray → drop the eyebrow.
        if (c.children.length == 1 &&
            c.children.first is _PrimArrayNode &&
            c.label != null &&
            (c.children.first as _PrimArrayNode).label == c.label) {
          emit(c.children.first, depth, isLast);
          continue;
        }
        // All-items: suppress the eyebrow (each item carries the parent
        // label, e.g. "DEPARTMENTS 1/2"). Don't add an indent level either —
        // the items render at the same depth as the suppressed group so they
        // sit at their parent's level instead of one step deeper.
        final allItems = c.children.every((cc) => cc is _ItemNode);
        if (allItems) {
          visit(c.children, depth);
          continue;
        }
        if (c.label != null) {
          emit(c, depth, false);
        }
        visit(c.children, depth + 1);
        continue;
      }

      if (c is _ItemNode) {
        emit(c, depth, false);
        visit(c.children, depth + 1);
        continue;
      }
    }
  }

  visit(root.children, 0);
  return out;
}

// ─────────────────────────────────────────────────────────────────────────────
// Render — every row is a full-width container. Indent and guide-line
// segments are drawn INSIDE each row so the bottom divider can span the
// card's content edge-to-edge.
// ─────────────────────────────────────────────────────────────────────────────

class _RenderItemView extends StatelessWidget {
  final _RenderItem item;
  // Depth of the row that follows this one in the flat list, or -1 if this
  // is the last row. Used to decide which guide-line segments end in this
  // row (so they should stop at the value bottom rather than continue down).
  final int nextDepth;
  // When false, suppresses the horizontal divider line entirely — guide
  // lines and indent are unaffected.
  final bool showDivider;
  const _RenderItemView({
    required this.item,
    required this.nextDepth,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final node = item.node;
    final drawDivider = showDivider && !item.isLast && _rowDrawsBorder(node);
    final indentLeft = item.depth * theme.defaultSpacing;
    final isEyebrow = _isEyebrow(node);
    final isFirstAtDepth =
        item.previousDepth >= 0 && item.depth > item.previousDepth;
    // Eyebrows get more breathing room above. First-at-depth claims drop top
    // padding to 0 so the visible glyph top of the label aligns with the
    // top of the freshly-introduced vertical line (which itself is inset by
    // tinySpacing from the row top).
    final double topPad;
    if (isEyebrow) {
      topPad = theme.smallSpacing;
    } else if (isFirstAtDepth) {
      topPad = 0;
    } else {
      topPad = theme.tinySpacing;
    }
    final bottomPad = theme.tinySpacing;
    // Inset from the Stack bottom up to the bottom of the value content (i.e.,
    // skipping the row's bottom padding and the divider, if any). Used as the
    // `bottom` for guide-line segments that end in this row.
    final endingLineBottom = bottomPad + (drawDivider ? 1.0 : 0.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Vertical guide-line segments — one per ancestor level. Newly
        // introduced segments are inset slightly from the row top so the
        // line "starts" a tiny bit below where it appears. Continuation
        // segments stay flush at top: 0 so the line connects across rows.
        // A segment ending in this row (no subsequent row has depth > i)
        // stops at the value bottom so the line doesn't trail past the
        // last attribute.
        for (var i = 0; i < item.depth; i++)
          Positioned(
            left: i * theme.defaultSpacing,
            top: i >= item.previousDepth ? theme.tinySpacing : 0,
            bottom: i >= nextDepth ? endingLineBottom : 0,
            width: 1,
            child: Container(color: theme.neutralExtraLight),
          ),
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
              child: Padding(
                padding: EdgeInsets.only(left: indentLeft),
                child: _RowContent(node: node),
              ),
            ),
            if (drawDivider)
              Padding(
                padding: EdgeInsets.only(left: indentLeft),
                child: Container(height: 1, color: theme.neutralExtraLight),
              ),
          ],
        ),
      ],
    );
  }

  static bool _rowDrawsBorder(_Node node) {
    // Eyebrows (group/item headings) don't draw their own border — only leaves
    // and primarrays (and empty-group fallbacks rendered as labelled rows).
    if (node is _RowNode) return true;
    if (node is _PrimArrayNode) return true;
    if (node is _GroupNode) return node.children.isEmpty;
    return false;
  }

  static bool _isEyebrow(_Node node) {
    if (node is _GroupNode) return node.children.isNotEmpty;
    if (node is _ItemNode) return true;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row content — dispatches to the right inner widget based on node kind.
// ─────────────────────────────────────────────────────────────────────────────

class _RowContent extends StatelessWidget {
  final _Node node;
  const _RowContent({required this.node});

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      _RowNode n => _LeafContent(node: n),
      _PrimArrayNode n => _PrimArrayContent(node: n),
      _GroupNode n => _EyebrowContent(node: n),
      _ItemNode n => _ItemEyebrowContent(node: n),
    };
  }
}

// Shared label / value text styles.
TextStyle _labelStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: theme.neutralExtraDark,
);

TextStyle _valueStyle(IrmaThemeData theme, Color color) => TextStyle(
  fontFamily: theme.primaryFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: color,
);

String _formatBool(BuildContext context, bool? value) {
  if (value == null) return "";
  return FlutterI18n.translate(
    context,
    value ? "credential.boolean_yes" : "credential.boolean_no",
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaf content — label on top, value below (no padding/border, container
// handles those).
// ─────────────────────────────────────────────────────────────────────────────

class _LeafContent extends StatelessWidget {
  final _RowNode node;
  const _LeafContent({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final attribute = node.attribute;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 0,
      children: [
        Text(
          attribute.effectiveDisplayName.translate(lang),
          style: _labelStyle(theme),
        ),
        _buildValue(context, theme, lang),
      ],
    );
  }

  Color _valueColor(schemaless.AttributeValue? val, IrmaThemeData theme) {
    if (!node.hasCompareTo) return theme.dark;
    return val?.string == node.compareToValue?.string
        ? theme.success
        : theme.error;
  }

  Widget _buildValue(BuildContext context, IrmaThemeData theme, String lang) {
    final val = node.attribute.value;
    if (val == null) return const SizedBox.shrink();
    return switch (val.type) {
      schemaless.AttributeType.string => Text(
        val.string ?? "",
        style: _valueStyle(theme, _valueColor(val, theme)),
      ),
      schemaless.AttributeType.boolean => Text(
        _formatBool(context, val.boolValue),
        style: _valueStyle(theme, _valueColor(val, theme)),
      ),
      schemaless.AttributeType.integer => Text(
        val.intValue?.toString() ?? "",
        style: _valueStyle(theme, _valueColor(val, theme)),
      ),
      schemaless.AttributeType.image || schemaless.AttributeType.base64Image =>
        _tappableImage(context, theme, lang),
    };
  }

  Widget _tappableImage(
    BuildContext context,
    IrmaThemeData theme,
    String lang,
  ) {
    final attribute = node.attribute;
    final val = attribute.value;
    final raw = val?.imagePath ?? val?.base64Image ?? "";
    final image = Image.memory(
      const Base64Decoder().convert(raw),
      fit: BoxFit.fitWidth,
    );
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: IrmaAppBar(
                titleString: attribute.effectiveDisplayName.translate(
                  lang,
                  fallbackLang: "",
                ),
              ),
              body: SingleChildScrollView(child: Center(child: image)),
            ),
          ),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 66, maxHeight: 100),
        child: image,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Array of primitives — stacked list with • bullets.
// ─────────────────────────────────────────────────────────────────────────────

class _PrimArrayContent extends StatelessWidget {
  final _PrimArrayNode node;
  const _PrimArrayContent({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 0,
      children: [
        Text(node.label.translate(lang), style: _labelStyle(theme)),
        for (final v in node.values) _bulletRow(context, theme, v),
      ],
    );
  }

  Widget _bulletRow(
    BuildContext context,
    IrmaThemeData theme,
    schemaless.AttributeValue v,
  ) {
    final valueStyle = _valueStyle(theme, theme.dark).copyWith(height: 1.2);
    final lineHeight = (valueStyle.fontSize ?? 16) * 1.2;
    return Padding(
      padding: EdgeInsets.only(top: theme.tinySpacing / 2),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: 12,
            height: lineHeight,
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.neutral,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(width: theme.tinySpacing),
          Expanded(child: Text(_formatValue(context, v), style: valueStyle)),
        ],
      ),
    );
  }

  String _formatValue(BuildContext context, schemaless.AttributeValue v) {
    return switch (v.type) {
      schemaless.AttributeType.string => v.string ?? "",
      schemaless.AttributeType.integer => v.intValue?.toString() ?? "",
      schemaless.AttributeType.boolean => _formatBool(context, v.boolValue),
      schemaless.AttributeType.image ||
      schemaless.AttributeType.base64Image => v.string ?? "",
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eyebrow content — uppercase group/item heading.
// ─────────────────────────────────────────────────────────────────────────────

class _EyebrowContent extends StatelessWidget {
  final _GroupNode node;
  const _EyebrowContent({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    // Empty groups (header without descendants) fall through here when they
    // were rendered as labelled rows by the flatten step. Render as a plain
    // bodyMedium-like label.
    if (node.children.isEmpty) {
      return Text(node.label?.translate(lang) ?? "", style: _labelStyle(theme));
    }
    return Text(
      node.label!.translate(lang).toUpperCase(),
      style: _eyebrowStyle(theme),
    );
  }
}

class _ItemEyebrowContent extends StatelessWidget {
  final _ItemNode node;
  const _ItemEyebrowContent({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final parentLabel =
        node.parentLabel?.translate(lang).toUpperCase() ?? "ITEM";
    final text = node.totalItems > 1
        ? "$parentLabel ${node.itemIndex}/${node.totalItems}"
        : parentLabel;
    return Text(text, style: _eyebrowStyle(theme));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eyebrow text style — small uppercase Open Sans label.
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _eyebrowStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: theme.neutralDark,
  letterSpacing: 0.96, // 0.08em × 12px
);
