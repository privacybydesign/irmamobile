import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../theme/theme.dart";
import "../irma_app_bar.dart";
import "../translated_text.dart";
import "attribute_groups/attribute_group.dart";
import "attribute_groups/attribute_group_registry.dart";
import "attribute_groups/attribute_value_formatting.dart";
import "models/credential_card_layout.dart";

/// How `overNN` age attributes are listed.
enum AgeDisplay {
  /// One row per attribute, like any other.
  perAttribute,

  /// One row with the highest age that is true and the lowest that is false,
  /// and a link that expands it into one chip per age.
  collapsed,
}

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
  final AgeDisplay ageDisplay;
  final CredentialCardLayout layout;
  // Claim paths (see [claimPathKey]) whose value does not match what is
  // needed: they are shown in the error colour.
  final Set<String> mismatched;
  // Claim paths whose value is exactly what is asked for: shown in the
  // success colour.
  final Set<String> matched;

  const YiviCredentialCardAttributeList(
    this.attributes, {
    this.compareTo,
    this.showDividers = false,
    this.credentialId,
    this.renderers,
    this.disclosure = false,
    this.ageDisplay = AgeDisplay.perAttribute,
    this.layout = CredentialCardLayout.standard,
    this.mismatched = const {},
    this.matched = const {},
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
      mismatched: mismatched,
      matched: matched,
    );
    _insertGroups(tree.children, groups, attributes);
    // Comparing against another credential needs every attribute on its own row.
    if (ageDisplay == AgeDisplay.collapsed && compareTo == null) {
      _collapseAges(tree.children);
    }
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
            layout: layout,
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
  final bool mismatch;
  final bool match;
  _RowNode({
    required this.attribute,
    required this.hasCompareTo,
    this.compareToValue,
    this.mismatch = false,
    this.match = false,
  });
}

class _AgeEntry {
  final int age;
  final bool over;
  const _AgeEntry({required this.age, required this.over});
}

/// All `overNN` attributes of one group, folded into a single row.
class _AgeNode extends _Node {
  final List<_AgeEntry> ages;
  _AgeNode({required this.ages});
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
  Set<String> mismatched = const {},
  Set<String> matched = const {},
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
    final hasDisplayName = e.displayName?.isNotEmpty ?? false;

    if (tail is int && !hasDisplayName) {
      // Primitive in array — collect under the parent header's label.
      final headerEntry = headers[parentKey];
      final label = headerEntry?.effectiveDisplayName ?? e.effectiveDisplayName;

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

    ensureItemFrames(p);
    popToPrefix(parentArrPath);
    final frame = stack.last;
    frame.childrenArr.add(
      _RowNode(
        attribute: e,
        hasCompareTo: compareTo != null,
        compareToValue: lookupCompare(p),
        mismatch: mismatched.contains(_pathKey(p)),
        match: matched.contains(_pathKey(p)),
      ),
    );
  }

  flushAllPrims();
  _stampItemTotals(root);
  return root;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ages — `overNN` attributes fold into one row per group.
// ─────────────────────────────────────────────────────────────────────────────

final _ageClaim = RegExp(r"^over(\d+)$");

_AgeEntry? _ageEntry(schemaless.Attribute attribute) {
  final claim = attribute.claimPath.lastOrNull;
  if (claim is! String) return null;
  final age = _ageClaim.firstMatch(claim)?.group(1);
  if (age == null) return null;

  final value = attribute.value;
  final over = switch (value?.type) {
    schemaless.AttributeType.boolean => value?.boolValue,
    schemaless.AttributeType.string => switch (value?.string?.toLowerCase()) {
      "yes" || "true" => true,
      "no" || "false" => false,
      _ => null,
    },
    _ => null,
  };
  if (over == null) return null;

  return _AgeEntry(age: int.parse(age), over: over);
}

void _collapseAges(List<_Node> children) {
  final ages = <_AgeEntry>[];
  int? firstIndex;
  final rest = <_Node>[];
  for (final child in children) {
    final entry = child is _RowNode ? _ageEntry(child.attribute) : null;
    if (entry == null) {
      rest.add(child);
      continue;
    }
    ages.add(entry);
    firstIndex ??= rest.length;
  }

  if (firstIndex != null) {
    ages.sort((a, b) => a.age.compareTo(b.age));
    rest.insert(firstIndex, _AgeNode(ages: ages));
    children
      ..clear()
      ..addAll(rest);
  }

  for (final child in children) {
    if (child is _GroupNode) _collapseAges(child.children);
    if (child is _ItemNode) _collapseAges(child.children);
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
  // Ages are collapsed after the groups are inserted, so none exist yet.
  _AgeNode _ => null,
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

      if (c is _RowNode ||
          c is _PrimArrayNode ||
          c is _AttributeGroupNode ||
          c is _AgeNode) {
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
  final CredentialCardLayout layout;
  const _RenderItemView({
    required this.item,
    required this.nextDepth,
    required this.showDivider,
    required this.disclosure,
    required this.layout,
  });

  // Space above and below a row in the document layout.
  static const _documentRowPadding = 6.0;

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
    double topPad;
    if (isEyebrow) {
      topPad = theme.smallSpacing;
    } else if (isFirstAtDepth) {
      topPad = 0;
    } else {
      topPad = theme.tinySpacing;
    }
    var bottomPad = theme.tinySpacing;
    if (layout == .document && !isEyebrow && !isFirstAtDepth) {
      topPad = _documentRowPadding;
      bottomPad = _documentRowPadding;
    }
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
            child: Container(color: AttributeColors.of(context).divider),
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
                  layout: layout,
                ),
              ),
            ),
            if (drawDivider)
              Padding(
                padding: EdgeInsets.only(left: indentLeft),
                child: Container(
                  height: 1,
                  color: AttributeColors.of(context).divider,
                ),
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
    if (node is _AgeNode) return true;
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
  final CredentialCardLayout layout;
  const _RowContent({
    required this.node,
    required this.isFirst,
    required this.disclosure,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return switch (node) {
      _RowNode n => _LeafContent(node: n, layout: layout),
      _AgeNode n => _AgeContent(node: n, layout: layout),
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
  final CredentialCardLayout layout;
  const _LeafContent({required this.node, required this.layout});

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final attribute = node.attribute;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 0,
      children: [
        Text(
          attribute.effectiveDisplayName,
          style: attributeLabelStyle(context, layout: layout),
        ),
        _buildValue(context, theme),
      ],
    );
  }

  Color _valueColor(
    BuildContext context,
    schemaless.AttributeValue? val,
    IrmaThemeData theme,
  ) {
    if (node.mismatch) return theme.error;
    if (node.match) return theme.success;
    if (!node.hasCompareTo) return AttributeColors.of(context).value;
    return val?.string == node.compareToValue?.string
        ? theme.success
        : theme.error;
  }

  Widget _buildValue(BuildContext context, IrmaThemeData theme) {
    final val = node.attribute.value;
    if (val == null) return const SizedBox.shrink();
    return switch (val.type) {
      schemaless.AttributeType.string => Text(
        val.string ?? "",
        style: attributeValueStyle(
          context,
          _valueColor(context, val, theme),
          layout: layout,
        ),
      ),
      schemaless.AttributeType.boolean => Text(
        formatAttributeBool(context, val.boolValue),
        style: attributeValueStyle(
          context,
          _valueColor(context, val, theme),
          layout: layout,
        ),
      ),
      schemaless.AttributeType.integer => Text(
        val.intValue?.toString() ?? "",
        style: attributeValueStyle(
          context,
          _valueColor(context, val, theme),
          layout: layout,
        ),
      ),
      schemaless.AttributeType.image ||
      schemaless.AttributeType.base64Image => _tappableImage(context, theme),
    };
  }

  Widget _tappableImage(BuildContext context, IrmaThemeData theme) {
    final attribute = node.attribute;
    final bytes = decodeAttributeImage(attribute.value);
    if (bytes == null) return const SizedBox.shrink();
    final image = Image.memory(
      bytes,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              extendBodyBehindAppBar: true,
              appBar: IrmaAppBar(titleString: attribute.effectiveDisplayName),
              body: SingleChildScrollView(
                child: SafeArea(child: Center(child: image)),
              ),
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
// Age — the highest age that is true and the lowest that is false, with one
// chip per age under it once expanded.
// ─────────────────────────────────────────────────────────────────────────────

class _AgeContent extends StatefulWidget {
  final _AgeNode node;
  final CredentialCardLayout layout;
  const _AgeContent({required this.node, required this.layout});

  @override
  State<_AgeContent> createState() => _AgeContentState();
}

class _AgeContentState extends State<_AgeContent> {
  bool _expanded = false;

  String _summary(BuildContext context) {
    final ages = widget.node.ages;
    final over = ages.where((a) => a.over).map((a) => a.age).lastOrNull;
    final notOver = ages.where((a) => !a.over).map((a) => a.age).firstOrNull;

    final (key, params) = switch ((over, notOver)) {
      (final over?, final notOver?) => (
        "credential.age.over_and_not_over",
        {"over": "$over", "notOver": "$notOver"},
      ),
      (final over?, null) => ("credential.age.over", {"age": "$over"}),
      (null, final notOver?) => (
        "credential.age.not_over",
        {"age": "$notOver"},
      ),
      (null, null) => ("", <String, String>{}),
    };
    return FlutterI18n.translate(context, key, translationParams: params);
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final layout = widget.layout;
    // Nothing to expand into when there is only one age.
    final canExpand = widget.node.ages.length > 1;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        TranslatedText(
          "credential.age.label",
          style: attributeLabelStyle(context, layout: layout),
        ),
        Text(
          _summary(context),
          style: attributeValueStyle(context, theme.dark, layout: layout),
        ),
        if (_expanded) ...[
          Padding(
            padding: .only(top: _AgeChip.gap),
            child: TranslatedText(
              "credential.age.over_label",
              style: attributeLabelStyle(context, layout: layout),
            ),
          ),
          Padding(
            padding: .only(top: _AgeChip.gap / 3, bottom: _AgeChip.gap),
            child: Wrap(
              spacing: _AgeChip.gap,
              runSpacing: _AgeChip.gap,
              children: [
                for (final entry in widget.node.ages) _AgeChip(entry: entry),
              ],
            ),
          ),
        ],
        if (canExpand)
          _AgeToggle(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}

/// A pill that says whether the holder is over [_AgeEntry.age]. The mark and the
/// colour repeat what the spoken label says.
class _AgeChip extends StatelessWidget {
  final _AgeEntry entry;
  const _AgeChip({required this.entry});

  static const double gap = 6;
  static const double _height = 30;

  // Colours of the pills on board F_AgeConfirm, which no theme token has.
  static const _overText = Color(0xFF00602A);
  static const _notOverSurface = Color(0xFFF2F0EE);

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    // The board's neutralDark is 4.14:1 on _notOverSurface, below the 4.5:1 of
    // WCAG 1.4.3.
    final textColor = entry.over ? _overText : theme.neutralExtraDark;
    return Semantics(
      excludeSemantics: true,
      label: FlutterI18n.translate(
        context,
        entry.over ? "credential.age.chip_yes" : "credential.age.chip_no",
        translationParams: {"age": "${entry.age}"},
      ),
      child: Container(
        height: _height,
        padding: .symmetric(
          horizontal: theme.smallSpacing + theme.tinySpacing / 2,
        ),
        decoration: BoxDecoration(
          color: entry.over ? theme.successSurface : _notOverSurface,
          borderRadius: .circular(_height / 2),
        ),
        // Centers in the fixed height without stretching to the row's width.
        child: Center(
          widthFactor: 1,
          child: Text(
            "${entry.over ? "✓" : "–"} ${entry.age}",
            style: attributeLabelStyle(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      ),
    );
  }
}

/// Shows or hides the chips under the age.
class _AgeToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  const _AgeToggle({required this.expanded, required this.onTap});

  static const double _minHeight = 44;

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    return Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Row(
            mainAxisSize: .min,
            spacing: theme.tinySpacing,
            children: [
              TranslatedText(
                expanded
                    ? "credential.age.hide_all"
                    : "credential.age.show_all",
                style: attributeLabelStyle(
                  context,
                ).copyWith(fontWeight: FontWeight.w600, color: theme.link),
              ),
              ExcludeSemantics(
                child: RotatedBox(
                  quarterTurns: expanded ? 2 : 0,
                  child: SizedBox.square(
                    dimension: 16,
                    child: CustomPaint(
                      painter: _ChevronPainter(color: theme.link),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final Color color;
  _ChevronPainter({required this.color});

  static const _grid = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid);
    canvas.drawPath(
      Path()
        ..moveTo(6, 9)
        ..lineTo(12, 15)
        ..lineTo(18, 9),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
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
        Text(node.label, style: attributeLabelStyle(context)),
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
      context,
      AttributeColors.of(context).value,
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
                  color: AttributeColors.of(context).muted,
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
      schemaless.AttributeType.boolean => formatAttributeBool(
        context,
        v.boolValue,
      ),
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
    // Empty groups (header without descendants) fall through here when they
    // were rendered as labelled rows by the flatten step. Render as a plain
    // bodyMedium-like label.
    if (node.children.isEmpty) {
      return Text(node.label ?? "", style: attributeLabelStyle(context));
    }
    return Text(
      (node.label ?? "").toUpperCase(),
      style: attributeEyebrowStyle(context),
    );
  }
}

class _ItemEyebrowContent extends StatelessWidget {
  final _ItemNode node;
  const _ItemEyebrowContent({required this.node});

  @override
  Widget build(BuildContext context) {
    final parentLabel = node.parentLabel?.toUpperCase() ?? "ITEM";
    final text = node.totalItems > 1
        ? "$parentLabel ${node.itemIndex}/${node.totalItems}"
        : parentLabel;
    return Text(text, style: attributeEyebrowStyle(context));
  }
}
