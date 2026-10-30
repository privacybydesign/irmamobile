import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/theme.dart";
import "../base64_image.dart";
import "../irma_app_bar.dart";
import "attribute_groups/attribute_group.dart";
import "attribute_groups/attribute_group_registry.dart";
import "attribute_groups/attribute_value_formatting.dart";

class YiviCredentialCardAttributeList extends StatelessWidget {
  final List<schemaless.Attribute> attributes;
  final List<schemaless.Attribute>? compareTo;
  // When true, each leaf/primarray row draws a 1px horizontal divider at
  // its bottom (suppressed on the last row of any parent group).
  final bool showDividers;
  // Credential type id; selects the attribute group renderers.
  final String? credentialId;
  // Overrides the registry lookup for [credentialId] (tests).
  final List<AttributeGroupRenderer>? renderers;
  // The attributes are being shared (a disclosure), not the whole credential.
  final bool disclosure;
  // The claim paths start with an mso_mdoc namespace: who defined the data
  // element, not a part of the credential, so it never gets a level.
  final bool namespaced;

  const YiviCredentialCardAttributeList(
    this.attributes, {
    this.compareTo,
    this.showDividers = false,
    this.credentialId,
    this.renderers,
    this.disclosure = false,
    this.namespaced = false,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <_ClaimedGroup>[];
    var remaining = attributes;
    for (final renderer
        in renderers ?? attributeGroupRenderers[credentialId] ?? const []) {
      final group = renderer.claim(remaining, compareTo: compareTo);
      if (group == null) continue;
      final claimedKeys = {
        for (final a in group.claimed) claimPathKey(a.claimPath),
      };
      assert(() {
        final offered = {for (final a in remaining) claimPathKey(a.claimPath)};
        return offered.containsAll(claimedKeys);
      }(), "${renderer.runtimeType} claimed an attribute it was not offered");
      final firstIndex = attributes.indexWhere(
        (a) => claimedKeys.contains(claimPathKey(a.claimPath)),
      );
      groups.add(
        _ClaimedGroup(group, firstIndex < 0 ? attributes.length : firstIndex),
      );
      remaining = remaining
          .where((a) => !claimedKeys.contains(claimPathKey(a.claimPath)))
          .toList();
    }

    // Images last, everything else in the order given. Not List.sort: it is
    // not stable, and past 32 elements it reorders the attributes it sees as
    // equal.
    final sorted = [
      ...remaining.where((a) => !_isImage(a)),
      ...remaining.where(_isImage),
    ];

    final tree = _buildTree(
      sorted,
      compareTo: compareTo,
      namespaced: namespaced,
    );
    _insertGroups(tree.children, groups, attributes);
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
            disclosure: disclosure,
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
  final String? label;
  final List<dynamic> path;
  final List<_Node> children;
  _GroupNode({this.label, required this.path, required this.children});
}

class _ItemNode extends _Node {
  final String? parentLabel;
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
  final String label;
  final List<dynamic> path;
  final List<schemaless.AttributeValue> values;
  _PrimArrayNode({
    required this.label,
    required this.path,
    required this.values,
  });
}

class _AttributeGroupNode extends _Node {
  final AttributeGroup group;
  _AttributeGroupNode(this.group);
}

bool _isImage(schemaless.Attribute a) =>
    a.value?.type == schemaless.AttributeType.image ||
    a.value?.type == schemaless.AttributeType.base64Image;

// ─────────────────────────────────────────────────────────────────────────────
// Tree builder
// ─────────────────────────────────────────────────────────────────────────────

String _pathKey(List<dynamic> p) => claimPathKey(p);

/// Label for an array or object the issuer gave no header: its own key made
/// readable, as [schemaless.Attribute.effectiveDisplayName] does for a leaf.
/// Null when the path has no key, which leaves array items labelled "ITEM".
String? _keyLabel(List<dynamic> arrayPath) {
  final key = arrayPath.lastWhereOrNull((s) => s is String) as String?;
  return key == null ? null : schemaless.readableClaimKey(key);
}

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
  final String label;
  final List<dynamic> path;
  final List<schemaless.AttributeValue> values;
  final List<_Node> parent;
  _PrimCollector({
    required this.label,
    required this.path,
    required this.values,
    required this.parent,
  });
}

_GroupNode _buildTree(
  List<schemaless.Attribute> attrs, {
  List<schemaless.Attribute>? compareTo,
  bool namespaced = false,
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
    c.parent.add(
      _PrimArrayNode(label: c.label, path: c.path, values: c.values),
    );
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

  // The first key gets no level of its own when it is an mdoc namespace,
  // however many the card shows, or when every attribute shares it, like a
  // VCDM credential's `credentialSubject`: that key is the credential itself
  // rather than a part of it.
  final firstKey = attrs.firstOrNull?.claimPath.firstOrNull;
  final rootLength =
      namespaced ||
          firstKey is String &&
              attrs.every(
                (a) => a.claimPath.length > 1 && a.claimPath[0] == firstKey,
              )
      ? 1
      : 0;

  bool isOpen(List<dynamic> path) => stack.any((f) => listEquals(f.path, path));

  // Opens a group for an object the issuer gave no header, titled with its
  // key, so its fields stay together under it instead of spilling into the
  // parent's level.
  void ensureObjectFrame(List<dynamic> objectPath) {
    if (isOpen(objectPath)) return;
    popToPrefix(objectPath);
    final group = _GroupNode(
      label:
          headers[_pathKey(objectPath)]?.effectiveDisplayName ??
          _keyLabel(objectPath),
      path: objectPath,
      children: [],
    );
    stack.last.childrenArr.add(group);
    stack.add(
      _StackFrame(path: objectPath, childrenArr: group.children, isItem: false),
    );
  }

  // Opens the levels [p] passes through: an item for every array element on
  // it, and a group for every object below the shared first key.
  void ensureFrames(List<dynamic> p) {
    for (var i = rootLength; i < p.length; i++) {
      if (p[i] is! int) {
        // An object: a key followed by another key. A key followed by an
        // index is an array, whose group is opened with its first item.
        if (i + 1 < p.length && p[i + 1] is String) {
          ensureObjectFrame(p.sublist(0, i + 1));
        }
        continue;
      }
      final itemPath = p.sublist(0, i + 1);
      if (isOpen(itemPath)) continue;

      final arrayHeaderPath = p.sublist(0, i);
      popToPrefix(arrayHeaderPath);
      // The array's label: the issuer's name for it, else its own key.
      final arrayLabel =
          headers[_pathKey(arrayHeaderPath)]?.effectiveDisplayName ??
          _keyLabel(arrayHeaderPath);
      // An array without a header has no group of its own yet. Open one, so
      // its items are counted per array rather than together with the items
      // of every other unnamed array under the same parent.
      if (!listEquals(stack.last.path, arrayHeaderPath)) {
        final group = _GroupNode(
          label: arrayLabel,
          path: arrayHeaderPath,
          children: [],
        );
        stack.last.childrenArr.add(group);
        stack.add(
          _StackFrame(
            path: arrayHeaderPath,
            childrenArr: group.children,
            isItem: false,
          ),
        );
      }
      final arrayFrame = stack.last;
      final itemIndex =
          arrayFrame.childrenArr.whereType<_ItemNode>().length + 1;
      final item = _ItemNode(
        parentLabel: arrayLabel,
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
      ensureFrames(p);
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
    final hasDisplayName = e.displayName?.isNotEmpty ?? false;

    if (tail is int && !hasDisplayName) {
      // Primitive in array — collect under the parent header's label.
      final headerEntry = headers[parentKey];
      final label = headerEntry?.effectiveDisplayName ?? e.effectiveDisplayName;

      // A list of values inside an array item (`alignment|0|type|0`) belongs
      // in that item, also when it is the item's first attribute.
      ensureFrames(parentArrPath);
      popToPrefix(parentArrPath);
      final frame = stack.last;

      primCollectors.putIfAbsent(
        parentKey,
        () => _PrimCollector(
          label: label,
          path: parentArrPath,
          values: [],
          parent: frame.childrenArr,
        ),
      );
      primCollectors[parentKey]!.values.add(e.value!);
      continue;
    }

    ensureFrames(p);
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
  _valuesFirst(root);
  return root;
}

/// Orders every level as simple values, then sections (nested objects and
/// lists), then images, keeping the order within each of the three. A value
/// would otherwise land between two sections, where it reads as part of the
/// one above it.
void _valuesFirst(_Node node) {
  final children = switch (node) {
    _GroupNode n => n.children,
    _ItemNode n => n.children,
    _ => null,
  };
  if (children == null) return;

  int rank(_Node c) => switch (c) {
    _RowNode n when _isImage(n.attribute) => 2,
    _RowNode() || _PrimArrayNode() => 0,
    // A header without descendants is drawn as a labelled row.
    _GroupNode n when n.children.isEmpty => 0,
    _ => 1,
  };
  final ordered = [
    for (final r in [0, 1, 2]) ...children.where((c) => rank(c) == r),
  ];
  children
    ..clear()
    ..addAll(ordered);
  for (final c in children) {
    _valuesFirst(c);
  }
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
// Attribute groups: slot each claimed group in among the top-level rows.
// ─────────────────────────────────────────────────────────────────────────────

class _ClaimedGroup {
  final AttributeGroup group;
  // Index of the group's first claimed attribute in the unsorted input; the
  // fallback position for an `after` whose anchor is absent.
  final int firstIndex;
  _ClaimedGroup(this.group, this.firstIndex);
}

Object? _topSegment(_Node node) => switch (node) {
  _RowNode n => n.attribute.claimPath.firstOrNull,
  _GroupNode n => n.path.firstOrNull,
  _ItemNode n => n.path.firstOrNull,
  _PrimArrayNode n => n.path.firstOrNull,
  _AttributeGroupNode _ => null,
};

/// Inserts [groups] into the top-level [children]. Groups resolving to the
/// same slot keep their registry order; only an `end` group goes below the
/// images.
void _insertGroups(
  List<_Node> children,
  List<_ClaimedGroup> groups,
  List<schemaless.Attribute> original,
) {
  if (groups.isEmpty) return;
  final n = children.length;
  var bottom = children.indexWhere(
    (c) => c is _RowNode && _isImage(c.attribute),
  );
  if (bottom < 0) bottom = n;
  final originalIndex = [
    for (final c in children)
      original.indexWhere((a) => a.claimPath.firstOrNull == _topSegment(c)),
  ];

  int fallback(int firstIndex) {
    final i = originalIndex.indexWhere((o) => o > firstIndex);
    return i < 0 ? n : i;
  }

  final slots = [
    for (final g in groups)
      switch (g.group.placement) {
        TopPlacement() => 0,
        BottomPlacement() => bottom,
        EndPlacement() => n,
        AfterPlacement(:final attributeId) => min(bottom, switch (children
            .indexWhere((c) => _topSegment(c) == attributeId)) {
          -1 => fallback(g.firstIndex),
          final i => i + 1,
        }),
      },
  ];

  final placed = <_Node>[];
  for (var j = 0; j <= n; j++) {
    for (var k = 0; k < groups.length; k++) {
      if (slots[k] == j) placed.add(_AttributeGroupNode(groups[k].group));
    }
    if (j < n) placed.add(children[j]);
  }
  children
    ..clear()
    ..addAll(placed);
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

      if (c is _RowNode || c is _PrimArrayNode || c is _AttributeGroupNode) {
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
  final bool disclosure;
  const _RenderItemView({
    required this.item,
    required this.nextDepth,
    required this.showDivider,
    required this.disclosure,
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
                child: _RowContent(
                  node: node,
                  isFirst: item.previousDepth < 0,
                  disclosure: disclosure,
                ),
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
    if (node is _AttributeGroupNode) return true;
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
  // The first row of the list: nothing is drawn above it.
  final bool isFirst;
  final bool disclosure;
  const _RowContent({
    required this.node,
    required this.isFirst,
    required this.disclosure,
  });

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      _RowNode n => _LeafContent(node: n),
      _PrimArrayNode n => _PrimArrayContent(node: n),
      _GroupNode n => _EyebrowContent(node: n),
      _ItemNode n => _ItemEyebrowContent(node: n),
      _AttributeGroupNode n => AttributeGroupScope(
        isFirst: isFirst,
        isDisclosure: disclosure,
        child: Builder(builder: n.group.build),
      ),
    };
  }
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
    final attribute = node.attribute;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 0,
      children: [
        Text(attribute.effectiveDisplayName, style: attributeLabelStyle(theme)),
        _buildValue(context, theme),
      ],
    );
  }

  Color _valueColor(schemaless.AttributeValue? val, IrmaThemeData theme) {
    if (!node.hasCompareTo) return theme.dark;
    return attributeValuesEqual(val, node.compareToValue)
        ? theme.success
        : theme.error;
  }

  Widget _buildValue(BuildContext context, IrmaThemeData theme) {
    final val = node.attribute.value;
    if (val == null) return const SizedBox.shrink();
    if (_isImage(node.attribute)) return _tappableImage(context, theme);
    return Text(
      formatAttributeValue(context, val),
      style: attributeValueStyle(theme, _valueColor(val, theme)),
    );
  }

  Widget _tappableImage(BuildContext context, IrmaThemeData theme) {
    final attribute = node.attribute;
    final value = attribute.value;
    final raw = value?.imagePath ?? value?.base64Image;
    // Issuers sometimes fill an empty image attribute with a placeholder such
    // as " "; Base64Image renders nothing for that rather than an error box.
    if (raw == null || raw.trim().isEmpty) return const SizedBox.shrink();
    final image = Base64Image(
      base64: raw,
      mimeType: value?.mimeType,
      fit: BoxFit.fitWidth,
    );
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: IrmaAppBar(titleString: attribute.effectiveDisplayName),
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

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 0,
      children: [
        Text(node.label, style: attributeLabelStyle(theme)),
        for (final v in node.values) _bulletRow(context, theme, v),
      ],
    );
  }

  Widget _bulletRow(
    BuildContext context,
    IrmaThemeData theme,
    schemaless.AttributeValue v,
  ) {
    final valueStyle = attributeValueStyle(
      theme,
      theme.dark,
    ).copyWith(height: 1.2);
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
          Expanded(
            child: Text(formatAttributeValue(context, v), style: valueStyle),
          ),
        ],
      ),
    );
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
    // Empty groups (header without descendants) fall through here when they
    // were rendered as labelled rows by the flatten step. Render as a plain
    // bodyMedium-like label.
    if (node.children.isEmpty) {
      return Text(node.label ?? "", style: attributeLabelStyle(theme));
    }
    return Text(
      (node.label ?? "").toUpperCase(),
      style: attributeEyebrowStyle(theme),
    );
  }
}

class _ItemEyebrowContent extends StatelessWidget {
  final _ItemNode node;
  const _ItemEyebrowContent({required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final parentLabel = node.parentLabel?.toUpperCase() ?? "ITEM";
    final text = node.totalItems > 1
        ? "$parentLabel ${node.itemIndex}/${node.totalItems}"
        : parentLabel;
    return Text(text, style: attributeEyebrowStyle(theme));
  }
}
