import "dart:io";

import "package:flutter/rendering.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";
import "package:yivi_core/src/widgets/credential_card/card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

/// What the attribute list shows for a set of fixed credentials, written
/// down once: the texts in order, what a screen reader hears, and how many
/// boxes have a border (the dividers). Moving the list's code around must
/// not change any of it. Run with UPDATE_DUMPS=1 to write the files again
/// after a change that is meant to be seen.
void main() {
  Attribute value(List<dynamic> path, String? name, String text) => Attribute(
    claimPath: path,
    displayName: name,
    value: AttributeValue(type: AttributeType.string, string: text),
  );
  Attribute header(List<dynamic> path, String name) =>
      Attribute(claimPath: path, displayName: name);

  final flat = [
    value(["given_name"], "First names", "Willeke Liselotte"),
    value(["family_name"], "Surname", "de Bruijn"),
    value(["email"], "Email address", "w@example.org"),
  ];
  final nested = [
    value(["name"], "Name", "Radboud University"),
    header(["faculties"], "Faculties"),
    value(["faculties", 0, "faculty_name"], "Faculty", "Science"),
    header(["faculties", 0, "courses"], "Courses"),
    value(["faculties", 0, "courses", 0], null, "Cryptography"),
    value(["faculties", 0, "courses", 1], null, "Distributed Systems"),
    value(["faculties", 1, "faculty_name"], "Faculty", "Arts"),
    header(["faculties", 1, "courses"], "Courses"),
    value(["faculties", 1, "courses", 0], null, "Medieval Europe"),
    header(["address"], "Address"),
    value(["address", "street"], "Street", "Kerkstraat 1"),
    value(["address", "locality"], "City", "Nijmegen"),
    header(["nationalities"], "Nationalities"),
    value(["nationalities", 0], null, "NL"),
    value(["nationalities", 1], null, "BE"),
  ];
  final ages = [
    value(["over12"], "Over 12", "yes"),
    value(["over16"], "Over 16", "yes"),
    value(["over18"], "Over 18", "yes"),
    value(["over21"], "Over 21", "yes"),
    value(["over65"], "Over 65", "no"),
    value(["city"], "City", "Arnhem"),
  ];
  final mdoc = [
    value(["org.iso.18013.5.1", "given_name"], "Given name", "Erika"),
    value(["org.iso.18013.5.1", "family_name"], "Family name", "Mustermann"),
    value(["org.iso.18013.5.1", "issuing_country"], "Country", "DE"),
  ];

  final cases = <String, Widget>{
    "flat": CardAttributeList(flat, showDividers: true),
    "nested": CardAttributeList(nested, showDividers: true),
    "ages_collapsed": CardAttributeList(
      ages,
      ageDisplay: AgeDisplay.collapsed,
      showDividers: true,
    ),
    "ages_per_attribute": CardAttributeList(ages),
    "group_renderer": CardAttributeList(
      flat,
      renderers: [_NameRenderer()],
      showDividers: true,
    ),
    "mdoc_namespaced": CardAttributeList(
      mdoc,
      namespaced: true,
      showDividers: true,
    ),
    "found": CardAttributeList(
      nested,
      found: claimPathKey(["address", "locality"]),
      foundQuery: "nijm",
      foundKey: GlobalKey(),
    ),
    "compare_to": CardAttributeList(
      flat,
      compareTo: [
        value(["given_name"], "First names", "Willeke Liselotte"),
        value(["family_name"], "Surname", "Jansen"),
      ],
      mismatched: {
        claimPathKey(["family_name"]),
      },
      matched: {
        claimPathKey(["given_name"]),
      },
      matchedTag: "Exactly what they ask",
      mismatchedTag: "Asked: Jansen",
      disclosure: true,
    ),
  };

  for (final MapEntry(key: name, value: list) in cases.entries) {
    testWidgets("the $name list shows what it always did", (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(list));
      await tester.pumpAndSettle();
      final dump = _dump(tester);
      handle.dispose();
      final file = File("test/fixtures/attribute_list_dump/$name.txt");
      if (Platform.environment["UPDATE_DUMPS"] == "1" || !file.existsSync()) {
        file.writeAsStringSync(dump);
      }
      expect(dump, file.readAsStringSync());
    });
  }
}

/// Claims the two name fields and draws them as one line.
class _NameRenderer implements AttributeGroupRenderer {
  @override
  AttributeGroup? claim(
    List<Attribute> available, {
    List<Attribute>? compareTo,
  }) {
    final claimed = available
        .where((a) => {"given_name", "family_name"}.contains(a.claimPath.first))
        .toList();
    if (claimed.isEmpty) return null;
    return AttributeGroup(
      claimed: claimed,
      placement: const AttributeGroupPlacement.top(),
      build: (_) => Text(claimed.map((a) => a.value?.string ?? "").join(" ")),
    );
  }
}

Widget _wrap(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

String _dump(WidgetTester tester) {
  final root = find.byType(CardAttributeList);
  final out = StringBuffer();
  out.writeln("# texts");
  for (final e in collectAllElementsFrom(
    tester.element(root),
    skipOffstage: true,
  )) {
    final w = e.widget;
    if (w is RichText) {
      out.writeln(w.text.toPlainText());
    }
  }
  out.writeln("# semantics");
  void walk(SemanticsNode node) {
    final label = node.label.trim();
    if (label.isNotEmpty || node.value.isNotEmpty) {
      out.writeln(
        [label, if (node.value.isNotEmpty) "= ${node.value}"].join(" "),
      );
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(tester.getSemantics(root));
  var borders = 0, lines = 0;
  void count(RenderObject r) {
    if (r is RenderDecoratedBox) {
      final d = r.decoration;
      if (d is BoxDecoration && d.border != null) borders++;
      if (d is ShapeDecoration) borders++;
    }
    // A divider: a coloured box one point high.
    if (r is RenderBox &&
        r.runtimeType.toString() == "_RenderColoredBox" &&
        r.hasSize &&
        r.size.height == 1) {
      lines++;
    }
    r.visitChildren(count);
  }

  count(tester.renderObject(root));
  out.writeln("# bordered boxes: $borders");
  out.writeln("# lines: $lines");
  return out.toString();
}
