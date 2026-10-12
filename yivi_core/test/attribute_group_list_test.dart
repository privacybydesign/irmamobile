import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

// A valid 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";

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

schemaless.Attribute _attr(String id) => schemaless.Attribute(
  claimPath: [id],
  displayName: "label-$id",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: "value-$id",
  ),
);

schemaless.Attribute _photo() => schemaless.Attribute(
  claimPath: ["photo"],
  displayName: "label-photo",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.base64Image,
    base64Image: _png,
  ),
);

/// Claims the attributes with the given ids and draws them as one Text.
class _FakeRenderer implements AttributeGroupRenderer {
  final String name;
  final Set<String> ids;
  final AttributeGroupPlacement placement;
  final List<List<String>> seen;

  _FakeRenderer(this.name, this.ids, this.placement, {List<List<String>>? seen})
    : seen = seen ?? [];

  @override
  AttributeGroup? claim(
    List<schemaless.Attribute> available, {
    List<schemaless.Attribute>? compareTo,
  }) {
    seen.add([for (final a in available) a.claimPath.first as String]);
    final claimed = available
        .where((a) => ids.contains(a.claimPath.first))
        .toList();
    if (claimed.isEmpty) return null;
    return AttributeGroup(
      claimed: claimed,
      placement: placement,
      build: (_) => Text("group-$name"),
    );
  }
}

/// The on-screen order (top to bottom) of the given texts.
List<String> _order(WidgetTester tester, List<String> texts) {
  final present = texts.where((t) => find.text(t).evaluate().isNotEmpty);
  return present.toList()..sort(
    (a, b) => tester
        .getTopLeft(find.text(a))
        .dy
        .compareTo(tester.getTopLeft(find.text(b)).dy),
  );
}

Future<void> _pump(
  WidgetTester tester,
  List<schemaless.Attribute> attrs,
  List<AttributeGroupRenderer> renderers,
) async {
  await _pumpWithTranslations(
    tester,
    YiviCredentialCardAttributeList(attrs, renderers: renderers),
  );
}

Future<void> _pumpWithTranslations(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_wrap(child));
  await tester.pumpAndSettle();
}

void main() {
  final abc = [_attr("a"), _attr("b"), _attr("c"), _attr("d")];
  const rows = ["label-a", "label-c", "label-d", "group-g"];

  testWidgets("claimed attributes are drawn by the group, not as rows", (
    tester,
  ) async {
    await _pump(tester, abc, [
      _FakeRenderer("g", {"b"}, const AttributeGroupPlacement.bottom()),
    ]);
    expect(find.text("label-b"), findsNothing);
    expect(find.text("group-g"), findsOneWidget);
  });

  testWidgets("top placement", (tester) async {
    await _pump(tester, abc, [
      _FakeRenderer("g", {"b"}, const AttributeGroupPlacement.top()),
    ]);
    expect(_order(tester, rows), ["group-g", "label-a", "label-c", "label-d"]);
  });

  testWidgets("bottom placement stays above images", (tester) async {
    await _pump(
      tester,
      [_photo(), ...abc],
      [
        _FakeRenderer("g", {"b"}, const AttributeGroupPlacement.bottom()),
      ],
    );
    expect(_order(tester, [...rows, "label-photo"]), [
      "label-a",
      "label-c",
      "label-d",
      "group-g",
      "label-photo",
    ]);
  });

  testWidgets("after placement", (tester) async {
    await _pump(tester, abc, [
      _FakeRenderer("g", {"b"}, const AttributeGroupPlacement.after("c")),
    ]);
    expect(_order(tester, rows), ["label-a", "label-c", "group-g", "label-d"]);
  });

  testWidgets("after with absent anchor falls back to first claimed position", (
    tester,
  ) async {
    await _pump(tester, abc, [
      _FakeRenderer("g", {"b"}, const AttributeGroupPlacement.after("zzz")),
    ]);
    expect(_order(tester, rows), ["label-a", "group-g", "label-c", "label-d"]);
  });

  testWidgets("after an image anchor is clamped above the images", (
    tester,
  ) async {
    await _pump(
      tester,
      [_photo(), ...abc],
      [
        _FakeRenderer("g", {"b"}, const AttributeGroupPlacement.after("photo")),
      ],
    );
    expect(_order(tester, [...rows, "label-photo"]).last, "label-photo");
  });

  testWidgets("groups in the same slot keep registry order", (tester) async {
    await _pump(tester, abc, [
      _FakeRenderer("1", {"b"}, const AttributeGroupPlacement.after("a")),
      _FakeRenderer("2", {"d"}, const AttributeGroupPlacement.after("a")),
    ]);
    expect(_order(tester, ["label-a", "label-c", "group-1", "group-2"]), [
      "label-a",
      "group-1",
      "group-2",
      "label-c",
    ]);
  });

  testWidgets("a later renderer does not see earlier claims", (tester) async {
    final seen = <List<String>>[];
    await _pump(tester, abc, [
      _FakeRenderer("1", {"b"}, const AttributeGroupPlacement.top()),
      _FakeRenderer(
        "2",
        {"b", "c"},
        const AttributeGroupPlacement.bottom(),
        seen: seen,
      ),
    ]);
    expect(seen.single, ["a", "c", "d"]);
    expect(find.text("group-1"), findsOneWidget);
    expect(find.text("group-2"), findsOneWidget);
    expect(find.text("label-c"), findsNothing);
  });

  testWidgets("no renderers: unchanged rows", (tester) async {
    await _pump(tester, abc, const []);
    expect(_order(tester, ["label-a", "label-b", "label-c", "label-d"]), [
      "label-a",
      "label-b",
      "label-c",
      "label-d",
    ]);
  });

  testWidgets("driving licence categories render via the registry", (
    tester,
  ) async {
    schemaless.Attribute flag(String code, bool held) => schemaless.Attribute(
      claimPath: ["category$code"],
      displayName: "Category $code",
      value: schemaless.AttributeValue(
        type: schemaless.AttributeType.boolean,
        boolValue: held,
      ),
    );
    await _pumpWithTranslations(
      tester,
      YiviCredentialCardAttributeList([
        _attr("dateOfExpiry"),
        _attr("over18"),
        flag("B", true),
        flag("C", false),
      ], credentialId: "pbdf-staging.pbdf.drivinglicence"),
    );

    final table = find.byKey(
      const Key("attribute_group_driving_licence_categories"),
    );
    expect(table, findsOneWidget);
    expect(find.text("Category B"), findsNothing);
    expect(find.text("B"), findsOneWidget);
    expect(
      tester.getTopLeft(find.text("label-dateOfExpiry")).dy,
      lessThan(tester.getTopLeft(table).dy),
    );
    expect(
      tester.getTopLeft(table).dy,
      lessThan(tester.getTopLeft(find.text("label-over18")).dy),
    );
  });
}
