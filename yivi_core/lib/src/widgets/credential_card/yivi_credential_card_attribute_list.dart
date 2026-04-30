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

  const YiviCredentialCardAttributeList(this.attributes, {this.compareTo});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

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

    return Column(
      spacing: theme.smallSpacing,
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        for (final child in tree.children)
          _NodeView(node: child, depth: 0),
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
      final alreadyOpen =
          stack.any((f) => f.isItem && _pathKey(f.path) == itemKey);
      if (alreadyOpen) continue;

      final arrayHeaderPath = p.sublist(0, i);
      popToPrefix(arrayHeaderPath);
      final arrayFrame = stack.last;
      final itemIndex =
          arrayFrame.childrenArr.whereType<_ItemNode>().length + 1;
      final parentHeader = headers[_pathKey(arrayHeaderPath)];
      final item = _ItemNode(
        parentLabel: parentHeader?.displayName,
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
      final group =
          _GroupNode(label: e.displayName, path: p, children: []);
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
      final label = headerEntry?.displayName ?? e.displayName;

      popToPrefix(parentArrPath);
      final frame = stack.last;

      primCollectors.putIfAbsent(
        parentKey,
        () => _PrimCollector(
          label: label,
          values: [],
          parent: frame.childrenArr,
        ),
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
// Renderer
// ─────────────────────────────────────────────────────────────────────────────

class _NodeView extends StatelessWidget {
  final _Node node;
  final int depth;

  const _NodeView({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      _RowNode n => _LeafRow(node: n),
      _PrimArrayNode n => _PrimArrayRow(node: n),
      _GroupNode n => _GroupView(node: n, depth: depth),
      _ItemNode n => _ItemView(node: n, depth: depth),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaf row — always stacked (label on top, value below).
// ─────────────────────────────────────────────────────────────────────────────

class _LeafRow extends StatelessWidget {
  final _RowNode node;
  const _LeafRow({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final attribute = node.attribute;

    return Padding(
      padding: .symmetric(
        vertical: attribute.value == null ? 0 : theme.tinySpacing,
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(
            attribute.displayName.translate(lang),
            style: theme.themeData.textTheme.bodyMedium!.copyWith(fontSize: 14),
          ),
          _buildContent(context, theme, lang),
        ],
      ),
    );
  }

  Color _valueColor(schemaless.AttributeValue? val, IrmaThemeData theme) {
    if (!node.hasCompareTo) return theme.dark;
    return val?.string == node.compareToValue?.string
        ? theme.success
        : theme.error;
  }

  Widget _buildContent(
    BuildContext context,
    IrmaThemeData theme,
    String lang,
  ) {
    final attribute = node.attribute;
    final val = attribute.value;
    if (val == null) return const SizedBox.shrink();
    return switch (val.type) {
      schemaless.AttributeType.string => Text(
        val.string ?? "",
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: _valueColor(val, theme),
        ),
      ),
      schemaless.AttributeType.boolean => Text(
        val.boolValue == null ? "" : (val.boolValue! ? "Yes" : "No"),
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: _valueColor(val, theme),
        ),
      ),
      schemaless.AttributeType.integer => Text(
        val.intValue?.toString() ?? "",
        style: theme.themeData.textTheme.bodyLarge!.copyWith(
          color: _valueColor(val, theme),
        ),
      ),
      schemaless.AttributeType.image ||
      schemaless.AttributeType.base64Image =>
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
    return Padding(
      padding: EdgeInsets.only(top: theme.tinySpacing),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: IrmaAppBar(
                  titleString: attribute.displayName.translate(
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Array of primitives — stacked list with • bullets.
// ─────────────────────────────────────────────────────────────────────────────

class _PrimArrayRow extends StatelessWidget {
  final _PrimArrayNode node;
  const _PrimArrayRow({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Padding(
      padding: .symmetric(vertical: theme.tinySpacing),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(
            node.label.translate(lang),
            style: theme.themeData.textTheme.bodyMedium!.copyWith(fontSize: 14),
          ),
          for (final v in node.values) _bulletRow(theme, v),
        ],
      ),
    );
  }

  Widget _bulletRow(IrmaThemeData theme, schemaless.AttributeValue v) {
    return Padding(
      padding: EdgeInsets.only(top: theme.tinySpacing / 2),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          SizedBox(
            width: 12,
            child: Text(
              "•",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.neutral,
                fontSize: 16,
                height: 1.2,
                fontFamily: theme.secondaryFontFamily,
              ),
            ),
          ),
          SizedBox(width: theme.tinySpacing),
          Expanded(
            child: Text(
              _formatValue(v),
              style: theme.themeData.textTheme.bodyLarge!.copyWith(
                color: theme.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(schemaless.AttributeValue v) {
    return switch (v.type) {
      schemaless.AttributeType.string => v.string ?? "",
      schemaless.AttributeType.integer => v.intValue?.toString() ?? "",
      schemaless.AttributeType.boolean =>
        v.boolValue == null ? "" : (v.boolValue! ? "Yes" : "No"),
      schemaless.AttributeType.image ||
      schemaless.AttributeType.base64Image => v.string ?? "",
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Group — header-introduced container.
// ─────────────────────────────────────────────────────────────────────────────

class _GroupView extends StatelessWidget {
  final _GroupNode node;
  final int depth;

  const _GroupView({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final children = node.children;

    // Empty group (header without descendants in the data) → render as a
    // plain labelled row, matching today's flat behavior for valueless attrs.
    if (children.isEmpty) {
      return Padding(
        padding: EdgeInsets.zero,
        child: Text(
          node.label?.translate(lang) ?? "",
          style: theme.themeData.textTheme.bodyMedium!.copyWith(fontSize: 14),
        ),
      );
    }

    // Group whose only child is a primitive-array row with the same label →
    // collapse: render the prim-array row directly, no double label.
    if (children.length == 1 &&
        children.first is _PrimArrayNode &&
        node.label != null &&
        (children.first as _PrimArrayNode).label == node.label) {
      return _PrimArrayRow(node: children.first as _PrimArrayNode);
    }

    // Group whose children are all _ItemNodes → suppress the heading; each
    // item already carries the parent label in its eyebrow.
    final allItems = children.every((c) => c is _ItemNode);
    final showHeading = node.label != null && !allItems;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        if (showHeading)
          Padding(
            padding: EdgeInsets.only(
              top: depth == 0 ? 0 : theme.smallSpacing,
              bottom: theme.tinySpacing,
            ),
            child: Text(
              node.label!.translate(lang).toUpperCase(),
              style: _eyebrowStyle(theme),
            ),
          ),
        _IndentedChildren(children: children, depth: depth),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item — array-of-objects entry with "PARENT N/M" eyebrow.
// ─────────────────────────────────────────────────────────────────────────────

class _ItemView extends StatelessWidget {
  final _ItemNode node;
  final int depth;

  const _ItemView({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;
    final parentLabel =
        node.parentLabel?.translate(lang).toUpperCase() ?? "ITEM";
    final eyebrow = node.totalItems > 1
        ? "$parentLabel ${node.itemIndex}/${node.totalItems}"
        : "$parentLabel ${node.itemIndex}";

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: node.itemIndex == 1 ? theme.tinySpacing : theme.smallSpacing,
            bottom: theme.tinySpacing,
          ),
          child: Text(eyebrow, style: _eyebrowStyle(theme)),
        ),
        _IndentedChildren(children: node.children, depth: depth),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indented children container with 1px guide line.
// ─────────────────────────────────────────────────────────────────────────────

class _IndentedChildren extends StatelessWidget {
  final List<_Node> children;
  final int depth;

  const _IndentedChildren({required this.children, required this.depth});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return IntrinsicHeight(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: theme.tinySpacing,
            bottom: theme.tinySpacing,
            child: Container(width: 1, color: theme.neutralExtraLight),
          ),
          Padding(
            padding: EdgeInsets.only(left: theme.defaultSpacing),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                for (final c in children)
                  _NodeView(node: c, depth: depth + 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eyebrow text style — small uppercase Open Sans label.
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _eyebrowStyle(IrmaThemeData theme) => TextStyle(
  fontFamily: theme.secondaryFontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: theme.neutralDark,
  letterSpacing: 0.88, // 0.08em × 11px
);
