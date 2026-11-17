part of "../yivi_credential_card_attribute_list.dart";

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
  final List<dynamic> path;
  final List<_Node> children;
  _ItemNode({
    this.parentLabel,
    required this.itemIndex,
    required this.path,
    required this.children,
  });
}

class _RowNode extends _Node {
  final Attribute attribute;
  final AttributeValue? compareToValue;
  final bool hasCompareTo;
  final bool mismatch;
  final bool match;
  // Set on the row a search found the card by.
  final _Found? found;
  _RowNode({
    required this.attribute,
    required this.hasCompareTo,
    this.compareToValue,
    this.mismatch = false,
    this.match = false,
    this.found,
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
  final List<AttributeValue> values;
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

bool _isImage(Attribute a) =>
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
  final List<_Node> childrenArr;
  _StackFrame({required this.path, required this.childrenArr});
}

class _PrimCollector {
  final String label;
  final List<dynamic> path;
  final List<AttributeValue> values;
  final List<_Node> parent;
  _PrimCollector({
    required this.label,
    required this.path,
    required this.values,
    required this.parent,
  });
}

typedef _Found = ({String claimKey, GlobalKey? key, String query});

_GroupNode _buildTree(
  List<Attribute> attrs, {
  List<Attribute>? compareTo,
  Set<String> mismatched = const {},
  Set<String> matched = const {},
  _Found? found,
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

  final root = _GroupNode(path: const [], children: []);
  final stack = <_StackFrame>[
    _StackFrame(path: const [], childrenArr: root.children),
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
    final group = _GroupNode(label: labelFor(path), path: path, children: []);
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
      final itemIndex =
          arrayFrame.childrenArr.whereType<_ItemNode>().length + 1;
      final item = _ItemNode(
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
      final group = _GroupNode(
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
      _RowNode(
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
void _valuesFirst(_Node node) {
  final children = _childrenOf(node);
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

/// The children of a group or an item; null for a node that has none.
List<_Node>? _childrenOf(_Node node) => switch (node) {
  _GroupNode n => n.children,
  _ItemNode n => n.children,
  _ => null,
};

// ─────────────────────────────────────────────────────────────────────────────
// Ages — `overNN` attributes fold into one row per group.
// ─────────────────────────────────────────────────────────────────────────────

final _ageClaim = RegExp(r"^over(\d+)$");

_AgeEntry? _ageEntry(Attribute attribute) {
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
    if (_childrenOf(child) case final grandchildren?) {
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
  List<Attribute> original,
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
// Flat row — one value, list of plain values, ages or attribute group, with
// its padding. The divider below it is drawn by the list (see `_NestedList`).
// ─────────────────────────────────────────────────────────────────────────────

bool _rowDrawsBorder(_Node node) => switch (node) {
  _RowNode() || _PrimArrayNode() || _AttributeGroupNode() || _AgeNode() => true,
  // A header without values is drawn as a labelled row.
  _GroupNode n => n.children.isEmpty,
  _ItemNode() => false,
};

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
    out.add(
      _GroupNode(
        label: n.label,
        path: n.path,
        children: _isList(n)
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
      first.attribute.value?.type == AttributeType.string) {
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
    text: context.tr("credential.nested.item", {
      "label": listLabel,
      "number": "${_itemNumber(item)}",
    }),
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
    default:
      for (final c in _childrenOf(n) ?? const <_Node>[]) {
        yield* _values(context, c);
      }
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
