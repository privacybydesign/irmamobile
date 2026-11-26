import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../attribute_groups/attribute_group.dart";
import "../attribute_groups/attribute_group_registry.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Tree model
// ─────────────────────────────────────────────────────────────────────────────

sealed class AttributeNode {
  const AttributeNode();
}

class GroupNode extends AttributeNode {
  final String? label;
  final List<dynamic> path;
  final List<AttributeNode> children;
  GroupNode({this.label, required this.path, required this.children});
}

class ItemNode extends AttributeNode {
  final String? parentLabel;
  final int itemIndex;
  final List<dynamic> path;
  final List<AttributeNode> children;
  ItemNode({
    this.parentLabel,
    required this.itemIndex,
    required this.path,
    required this.children,
  });
}

class RowNode extends AttributeNode {
  final Attribute attribute;
  final AttributeValue? compareToValue;
  final bool hasCompareTo;
  final bool mismatch;
  final bool match;
  // Set on the row a search found the card by.
  final FoundField? found;
  RowNode({
    required this.attribute,
    required this.hasCompareTo,
    this.compareToValue,
    this.mismatch = false,
    this.match = false,
    this.found,
  });
}

class AgeEntry {
  final int age;
  final bool over;
  const AgeEntry({required this.age, required this.over});
}

/// All `overNN` attributes of one group, folded into a single row.
class AgeNode extends AttributeNode {
  final List<AgeEntry> ages;
  AgeNode({required this.ages});
}

class PrimArrayNode extends AttributeNode {
  final String label;
  final List<dynamic> path;
  final List<AttributeValue> values;
  PrimArrayNode({
    required this.label,
    required this.path,
    required this.values,
  });
}

class AttributeGroupNode extends AttributeNode {
  final AttributeGroup group;
  AttributeGroupNode(this.group);
}

bool isImageAttribute(Attribute a) =>
    a.value?.type == AttributeType.image ||
    a.value?.type == AttributeType.base64Image;

// ─────────────────────────────────────────────────────────────────────────────
// Tree builder
// ─────────────────────────────────────────────────────────────────────────────

/// Label for an array or object the issuer gave no header: its own key made
/// readable, as [Attribute.effectiveDisplayName] does for a leaf.
/// Null when the path has no key, which leaves array items labelled "ITEM".
String? _keyLabel(List<dynamic> arrayPath) {
  final key = arrayPath.lastWhereOrNull((s) => s is String) as String?;
  return key == null ? null : readableClaimKey(key);
}

class _StackFrame {
  final List<dynamic> path;
  final List<AttributeNode> childrenArr;
  _StackFrame({required this.path, required this.childrenArr});
}

class _PrimCollector {
  final String label;
  final List<dynamic> path;
  final List<AttributeValue> values;
  final List<AttributeNode> parent;
  _PrimCollector({
    required this.label,
    required this.path,
    required this.values,
    required this.parent,
  });
}

typedef FoundField = ({String claimKey, GlobalKey? key, String query});

GroupNode _buildTree(
  List<Attribute> attrs, {
  List<Attribute>? compareTo,
  Set<String> mismatched = const {},
  Set<String> matched = const {},
  FoundField? found,
  bool namespaced = false,
}) {
  final headers = <String, Attribute>{};
  for (final e in attrs) {
    if (e.value == null) headers[claimPathKey(e.claimPath)] = e;
  }

  // The first value at each claim path of [compareTo].
  final compareValues = <String, AttributeValue?>{};
  for (final c in compareTo ?? const <Attribute>[]) {
    compareValues.putIfAbsent(claimPathKey(c.claimPath), () => c.value);
  }

  final root = GroupNode(path: const [], children: []);
  final stack = <_StackFrame>[
    _StackFrame(path: const [], childrenArr: root.children),
  ];
  final primCollectors = <String, _PrimCollector>{};

  void flushPrim(String key) {
    final c = primCollectors[key];
    if (c == null) return;
    c.parent.add(PrimArrayNode(label: c.label, path: c.path, values: c.values));
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
  final skipFirstKey =
      namespaced ||
      (firstKey is String &&
          attrs.every(
            (a) => a.claimPath.length > 1 && a.claimPath[0] == firstKey,
          ));

  bool isOpen(List<dynamic> path) => stack.any((f) => listEquals(f.path, path));

  // The issuer's name for the object or array at [path], else its own key.
  String? labelFor(List<dynamic> path) =>
      headers[claimPathKey(path)]?.effectiveDisplayName ?? _keyLabel(path);

  // Opens a group for an object or array the issuer gave no header, titled
  // with its key, so its fields or items stay together under it instead of
  // spilling into the parent's level. An array's items are then also counted
  // per array rather than together with every other unnamed array's.
  void ensureGroupFrame(List<dynamic> path) {
    if (isOpen(path)) return;
    popToPrefix(path);
    final group = GroupNode(label: labelFor(path), path: path, children: []);
    stack.last.childrenArr.add(group);
    stack.add(_StackFrame(path: path, childrenArr: group.children));
  }

  // Opens the levels [p] passes through: an item for every array element on
  // it, and a group for every object below the shared first key.
  void ensureFrames(List<dynamic> p) {
    for (var i = skipFirstKey ? 1 : 0; i < p.length; i++) {
      if (p[i] is! int) {
        // An object: a key followed by another key. A key followed by an
        // index is an array, whose group is opened with its first item.
        if (i + 1 < p.length && p[i + 1] is String) {
          ensureGroupFrame(p.sublist(0, i + 1));
        }
        continue;
      }
      final itemPath = p.sublist(0, i + 1);
      if (isOpen(itemPath)) continue;

      final arrayHeaderPath = p.sublist(0, i);
      ensureGroupFrame(arrayHeaderPath);
      popToPrefix(arrayHeaderPath);
      final arrayFrame = stack.last;
      final itemIndex = arrayFrame.childrenArr.whereType<ItemNode>().length + 1;
      final item = ItemNode(
        parentLabel: labelFor(arrayHeaderPath),
        itemIndex: itemIndex,
        path: itemPath,
        children: [],
      );
      arrayFrame.childrenArr.add(item);
      stack.add(_StackFrame(path: itemPath, childrenArr: item.children));
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
      final group = GroupNode(
        label: e.effectiveDisplayName,
        path: p,
        children: [],
      );
      parentFrame.childrenArr.add(group);
      stack.add(_StackFrame(path: p, childrenArr: group.children));
      continue;
    }

    // Leaf attribute.
    final parentArrPath = p.length > 1
        ? p.sublist(0, p.length - 1)
        : const <dynamic>[];
    final parentKey = claimPathKey(parentArrPath);
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
    final key = claimPathKey(p);
    frame.childrenArr.add(
      RowNode(
        attribute: e,
        hasCompareTo: compareTo != null,
        compareToValue: compareValues[key],
        mismatch: mismatched.contains(key),
        match: matched.contains(key),
        found: found?.claimKey == key ? found : null,
      ),
    );
  }

  flushAllPrims();
  _valuesFirst(root);
  return root;
}

/// Orders every level as simple values, then sections (nested objects and
/// lists), then images, keeping the order within each of the three. A value
/// would otherwise land between two sections, where it reads as part of the
/// one above it.
void _valuesFirst(AttributeNode node) {
  final children = nodeChildren(node);
  if (children == null) return;

  int rank(AttributeNode c) => switch (c) {
    RowNode n when isImageAttribute(n.attribute) => 2,
    RowNode() || PrimArrayNode() => 0,
    // A header without descendants is drawn as a labelled row.
    GroupNode n when n.children.isEmpty => 0,
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

/// The children of a group or an item; null for a node that has none.
List<AttributeNode>? nodeChildren(AttributeNode node) => switch (node) {
  GroupNode n => n.children,
  ItemNode n => n.children,
  _ => null,
};

// ─────────────────────────────────────────────────────────────────────────────
// Ages — `overNN` attributes fold into one row per group.
// ─────────────────────────────────────────────────────────────────────────────

final _ageClaim = RegExp(r"^over(\d+)$");

AgeEntry? _ageEntry(Attribute attribute) {
  final claim = attribute.claimPath.lastOrNull;
  if (claim is! String) return null;
  final age = _ageClaim.firstMatch(claim)?.group(1);
  if (age == null) return null;

  final value = attribute.value;
  final over = switch (value?.type) {
    AttributeType.boolean => value?.boolValue,
    AttributeType.string => switch (value?.string?.toLowerCase()) {
      "yes" || "true" => true,
      "no" || "false" => false,
      _ => null,
    },
    _ => null,
  };
  if (over == null) return null;

  return AgeEntry(age: int.parse(age), over: over);
}

void _collapseAges(List<AttributeNode> children) {
  final ages = <AgeEntry>[];
  int? firstIndex;
  final rest = <AttributeNode>[];
  for (final child in children) {
    final entry = child is RowNode ? _ageEntry(child.attribute) : null;
    if (entry == null) {
      rest.add(child);
      continue;
    }
    ages.add(entry);
    firstIndex ??= rest.length;
  }

  if (firstIndex != null) {
    ages.sort((a, b) => a.age.compareTo(b.age));
    rest.insert(firstIndex, AgeNode(ages: ages));
    children
      ..clear()
      ..addAll(rest);
  }

  for (final child in children) {
    if (nodeChildren(child) case final grandchildren?) {
      _collapseAges(grandchildren);
    }
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

Object? _topSegment(AttributeNode node) => switch (node) {
  RowNode n => n.attribute.claimPath.firstOrNull,
  GroupNode n => n.path.firstOrNull,
  ItemNode n => n.path.firstOrNull,
  PrimArrayNode n => n.path.firstOrNull,
  AttributeGroupNode _ => null,
  // Ages are collapsed after the groups are inserted, so none exist yet.
  AgeNode _ => null,
};

/// Inserts [groups] into the top-level [children]. Groups resolving to the
/// same slot keep their registry order; only an `end` group goes below the
/// images.
void _insertGroups(
  List<AttributeNode> children,
  List<_ClaimedGroup> groups,
  List<Attribute> original,
) {
  if (groups.isEmpty) return;
  final n = children.length;
  var bottom = children.indexWhere(
    (c) => c is RowNode && isImageAttribute(c.attribute),
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

  final placed = <AttributeNode>[];
  for (var j = 0; j <= n; j++) {
    for (var k = 0; k < groups.length; k++) {
      if (slots[k] == j) placed.add(AttributeGroupNode(groups[k].group));
    }
    if (j < n) placed.add(children[j]);
  }
  children
    ..clear()
    ..addAll(placed);
}

// ─────────────────────────────────────────────────────────────────────────────
// Flat row — one value, list of plain values, ages or attribute group, with
// its padding. The divider below it is drawn by the list (see `_NestedList`).
// ─────────────────────────────────────────────────────────────────────────────

bool rowDrawsBorder(AttributeNode node) => switch (node) {
  RowNode() || PrimArrayNode() || AttributeGroupNode() || AgeNode() => true,
  // A header without values is drawn as a labelled row.
  GroupNode n => n.children.isEmpty,
  ItemNode() => false,
};

// ── Shape of the tree ────────────────────────────────────────────────────────

/// Makes every array a [GroupNode] whose children are all items, and drops
/// headers that only repeat what is below them.
List<AttributeNode> _normalize(List<AttributeNode> nodes) {
  final out = <AttributeNode>[];
  var i = 0;
  while (i < nodes.length) {
    final n = nodes[i];
    if (n is ItemNode) {
      // Items of an array that has no header of its own.
      final run = <ItemNode>[];
      while (i < nodes.length && nodes[i] is ItemNode) {
        run.add(nodes[i] as ItemNode);
        i++;
      }
      final first = run.first;
      out.add(
        GroupNode(
          label: first.parentLabel,
          path: first.path.sublist(0, first.path.length - 1),
          children: [for (final item in run) _normalizeItem(item)],
        ),
      );
      continue;
    }
    i++;
    if (n is! GroupNode) {
      out.add(n);
      continue;
    }
    // A list of plain values under a header of the same name.
    if (n.children.length == 1 &&
        n.children.first is PrimArrayNode &&
        n.label != null &&
        (n.children.first as PrimArrayNode).label == n.label) {
      out.add(n.children.first);
      continue;
    }
    out.add(
      GroupNode(
        label: n.label,
        path: n.path,
        children: isListNode(n)
            ? [for (final c in n.children) _normalizeItem(c as ItemNode)]
            : _normalize(n.children),
      ),
    );
  }
  return out;
}

ItemNode _normalizeItem(ItemNode item) {
  var children = item.children;
  // A header at the item's own path wraps the item's values.
  if (children.length == 1 &&
      children.first is GroupNode &&
      listEquals((children.first as GroupNode).path, item.path)) {
    children = (children.first as GroupNode).children;
  }
  return ItemNode(
    parentLabel: item.parentLabel,
    itemIndex: item.itemIndex,
    path: item.path,
    children: _normalize(children),
  );
}

bool isListNode(AttributeNode n) =>
    n is GroupNode &&
    n.children.isNotEmpty &&
    n.children.every((c) => c is ItemNode);

bool isNestedNode(AttributeNode n) => n is GroupNode && n.children.isNotEmpty;

String groupLabel(GroupNode g) =>
    g.label ??
    g.path.lastWhere((s) => s is String, orElse: () => "").toString();

/// The item's place in the credential's list, counted from 1.
int itemNumber(ItemNode item) {
  final last = item.path.lastOrNull;
  return last is num ? last.toInt() + 1 : item.itemIndex;
}

/// The tree the attribute list draws for [attributes]: what the group
/// renderers for [credentialId] (or [renderers]) claim placed among the
/// rest, values before images on every level, the ages on one row when
/// [collapseAges], and every array as a group of items.
List<AttributeNode> buildAttributeTree(
  List<Attribute> attributes, {
  String? credentialId,
  List<AttributeGroupRenderer>? renderers,
  List<Attribute>? compareTo,
  Set<String> mismatched = const {},
  Set<String> matched = const {},
  FoundField? found,
  bool namespaced = false,
  bool collapseAges = false,
}) {
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

  // Images end up last on every level through _valuesFirst.
  final tree = _buildTree(
    remaining,
    compareTo: compareTo,
    namespaced: namespaced,
    mismatched: mismatched,
    matched: matched,
    found: found,
  );
  _insertGroups(tree.children, groups, attributes);
  // Comparing against another credential needs every attribute on its own row.
  if (collapseAges && compareTo == null) _collapseAges(tree.children);
  return _normalize(tree.children);
}
