import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_list/attribute_tree.dart";

Attribute _value(List<dynamic> path, String? name, String text) => Attribute(
  claimPath: path,
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: text),
);

Attribute _header(List<dynamic> path, String name) =>
    Attribute(claimPath: path, displayName: name);

Attribute _image(String id) => Attribute(
  claimPath: [id],
  displayName: id,
  value: AttributeValue(type: AttributeType.base64Image, base64Image: "AA=="),
);

/// The claim path of each top-level row, or the node's kind.
List<String> _shape(List<AttributeNode> nodes) => [
  for (final n in nodes)
    switch (n) {
      RowNode(:final attribute) => attribute.claimPath.join("."),
      GroupNode(:final path) => "group ${path.join(".")}",
      ItemNode(:final path) => "item ${path.join(".")}",
      AgeNode(:final ages) => "ages ${ages.map((a) => a.age).join(",")}",
      PrimArrayNode(:final path) => "values ${path.join(".")}",
      AttributeGroupNode() => "rendered group",
    },
];

class _Claims implements AttributeGroupRenderer {
  final Set<String> ids;
  _Claims(this.ids);

  @override
  AttributeGroup? claim(
    List<Attribute> available, {
    List<Attribute>? compareTo,
  }) {
    final claimed = available
        .where((a) => ids.contains(a.claimPath.first))
        .toList();
    if (claimed.isEmpty) return null;
    return AttributeGroup(
      claimed: claimed,
      placement: const AttributeGroupPlacement.top(),
      build: (_) => const SizedBox(),
    );
  }
}

void main() {
  test("flat values in their order, images last", () {
    final nodes = buildAttributeTree([
      _image("photo"),
      _value(["a"], "A", "1"),
      _value(["b"], "B", "2"),
    ]);
    expect(_shape(nodes), ["a", "b", "photo"]);
  });

  test("an object is a group; a list of objects a group of items", () {
    final nodes = buildAttributeTree([
      _value(["name"], "Name", "x"),
      _header(["address"], "Address"),
      _value(["address", "street"], "Street", "s"),
      _header(["degrees"], "Degrees"),
      _value(["degrees", 0, "title"], "Title", "BSc"),
      _value(["degrees", 1, "title"], "Title", "MSc"),
    ]);
    expect(_shape(nodes), ["name", "group address", "group degrees"]);
    final degrees = nodes[2] as GroupNode;
    expect(_shape(degrees.children), ["item degrees.0", "item degrees.1"]);
  });

  test("ages fold into one row only when asked, and never when compared", () {
    final ages = [
      _value(["over18"], "Over 18", "yes"),
      _value(["over65"], "Over 65", "no"),
    ];
    expect(_shape(buildAttributeTree(ages)), ["over18", "over65"]);
    expect(_shape(buildAttributeTree(ages, collapseAges: true)), [
      "ages 18,65",
    ]);
    expect(
      _shape(buildAttributeTree(ages, collapseAges: true, compareTo: ages)),
      ["over18", "over65"],
    );
  });

  test("what a renderer claims is one node, the rest stays rows", () {
    final nodes = buildAttributeTree(
      [
        _value(["a"], "A", "1"),
        _value(["b"], "B", "2"),
      ],
      renderers: [
        _Claims({"b"}),
      ],
    );
    expect(_shape(nodes), ["rendered group", "a"]);
  });

  test("an mdoc namespace is not a level", () {
    final nodes = buildAttributeTree([
      _value(["org.iso.18013.5.1", "given_name"], "Given name", "Erika"),
    ], namespaced: true);
    expect(_shape(nodes), ["org.iso.18013.5.1.given_name"]);
  });

  test("the found row carries the search; a compared row its verdict", () {
    final nodes = buildAttributeTree(
      [
        _value(["a"], "A", "1"),
        _value(["b"], "B", "2"),
      ],
      found: (claimKey: claimPathKey(["b"]), key: null, query: "2"),
      compareTo: [
        _value(["a"], "A", "9"),
      ],
      mismatched: {
        claimPathKey(["a"]),
      },
    );
    final a = nodes[0] as RowNode, b = nodes[1] as RowNode;
    expect(a.found, isNull);
    expect(a.mismatch, isTrue);
    expect(a.compareToValue?.string, "9");
    expect(b.found?.query, "2");
  });
}
