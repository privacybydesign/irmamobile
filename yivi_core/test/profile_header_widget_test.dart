import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_image.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

// A valid 1x1 PNG.
const _png =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC";

Widget _wrap(Widget child, {Locale locale = const Locale("en", "US")}) =>
    IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: TestTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: locale,
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

schemaless.Attribute _str(String id, String value) => schemaless.Attribute(
  claimPath: [id],
  displayName: "label-$id",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: value,
  ),
);

schemaless.Attribute _photo() => schemaless.Attribute(
  claimPath: ["photo"],
  displayName: "Photo",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.base64Image,
    base64Image: _png,
  ),
);

schemaless.Attribute _flag(String code) => schemaless.Attribute(
  claimPath: ["category$code"],
  displayName: "Category $code",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.boolean,
    boolValue: true,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  List<schemaless.Attribute> attrs,
  String credentialId, {
  Locale locale = const Locale("en", "US"),
}) async {
  await tester.pumpWidget(
    _wrap(
      YiviCredentialCardAttributeList(attrs, credentialId: credentialId),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

final _header = find.byKey(const Key("attribute_group_profile_header"));
final _divider = find.byKey(const Key("profile_header_divider"));

void main() {
  const passport = "pbdf-staging.pbdf.passport";

  testWidgets("passport: header at the top, photo inside it", (tester) async {
    await _pump(tester, [
      _str("documentNumber", "X1234567"),
      _str("firstName", "Anna"),
      _str("lastName", "de Vries"),
      _str("dateOfBirth", "1996-12-17"),
      _str("nationality", "NLD"),
      _str("gender", "F"),
      _photo(),
    ], passport);

    expect(_header, findsOneWidget);
    expect(find.text("Anna de Vries"), findsOneWidget);
    expect(
      find.byKey(const Key("profile_header_date_of_birth")),
      findsOneWidget,
    );
    // The photo is part of the header, not an image row at the bottom.
    expect(find.byType(TappableAttributeImage), findsOneWidget);
    expect(
      find.descendant(
        of: _header,
        matching: find.byType(TappableAttributeImage),
      ),
      findsOneWidget,
    );
    // Header above the remaining rows, with a divider between.
    expect(
      tester.getTopLeft(_header).dy,
      lessThan(tester.getTopLeft(find.text("label-documentNumber")).dy),
    );
    expect(_divider, findsOneWidget);
    // Claimed attributes are not repeated as rows.
    expect(find.text("label-firstName"), findsNothing);
    expect(find.text("label-nationality"), findsNothing);
  });

  testWidgets("the photo has rounded corners", (tester) async {
    await _pump(tester, [_str("lastName", "de Vries"), _photo()], passport);
    final clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(TappableAttributeImage),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, BorderRadius.circular(8));
  });

  testWidgets("details as icon + value, labelled for screen readers", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, [
      _str("firstName", "Anna"),
      _str("lastName", "de Vries"),
      _str("dateOfBirth", "1996-12-17"),
      _str("nationality", "NLD"),
      _str("gender", "F"),
    ], passport);

    for (final (key, icon) in [
      ("date_of_birth", Icons.cake_outlined),
      ("nationality", Icons.flag_outlined),
      ("gender", Icons.person_outline),
    ]) {
      expect(
        find.descendant(
          of: find.byKey(Key("profile_header_$key")),
          matching: find.byIcon(icon),
        ),
        findsOneWidget,
        reason: key,
      );
    }
    expect(find.text("1996-12-17"), findsOneWidget);
    // No visible labels; the icon says what it is.
    expect(find.text("DATE OF BIRTH"), findsNothing);
    expect(find.textContaining("Date of birth"), findsNothing);
    // Screen readers hear the label with the value.
    expect(find.bySemanticsLabel("Date of birth 1996-12-17"), findsOneWidget);
    // Side by side when there is room.
    expect(
      tester.getTopLeft(find.byKey(const Key("profile_header_nationality"))).dy,
      tester
          .getTopLeft(find.byKey(const Key("profile_header_date_of_birth")))
          .dy,
    );
    semantics.dispose();
  });

  testWidgets("no photo: no image area at all", (tester) async {
    await _pump(tester, [
      _str("firstName", "Anna"),
      _str("lastName", "de Vries"),
    ], passport);

    expect(_header, findsOneWidget);
    expect(find.byType(TappableAttributeImage), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets("absent details have no line", (tester) async {
    await _pump(tester, [_str("lastName", "de Vries")], passport);

    expect(find.text("de Vries"), findsOneWidget);
    for (final label in [
      "date_of_birth",
      "place_of_birth",
      "nationality",
      "gender",
    ]) {
      expect(find.byKey(Key("profile_header_$label")), findsNothing);
    }
  });

  testWidgets("header alone (e.g. a disclosure of the name): no divider", (
    tester,
  ) async {
    await _pump(tester, [
      _str("firstName", "Anna"),
      _str("lastName", "de Vries"),
    ], passport);
    expect(_divider, findsNothing);
  });

  testWidgets("below the threshold: ordinary rows", (tester) async {
    await _pump(tester, [_str("dateOfBirth", "1996-12-17")], passport);
    expect(_header, findsNothing);
    expect(find.text("label-dateOfBirth"), findsOneWidget);
  });

  testWidgets("driving licence: header first, categories last", (tester) async {
    await _pump(tester, [
      _str("firstName", "Anna"),
      _str("lastName", "de Vries"),
      _str("documentNumber", "D1"),
      _flag("B"),
    ], "pbdf-staging.pbdf.drivinglicence");

    final categories = find.byKey(
      const Key("attribute_group_driving_licence_categories"),
    );
    expect(_header, findsOneWidget);
    expect(categories, findsOneWidget);
    expect(
      tester.getTopLeft(_header).dy,
      lessThan(tester.getTopLeft(find.text("label-documentNumber")).dy),
    );
    expect(
      tester.getTopLeft(find.text("label-documentNumber")).dy,
      lessThan(tester.getTopLeft(categories).dy),
    );
  });

  testWidgets("municipality: Dutch labels and nationality", (tester) async {
    await _pump(
      tester,
      [
        _str("firstnames", "Anna"),
        _str("prefix", "de"),
        _str("surname", "Vries"),
        _str("initials", "A."),
        schemaless.Attribute(
          claimPath: ["nationality"],
          displayName: "label-nationality",
          value: schemaless.AttributeValue(
            type: schemaless.AttributeType.boolean,
            boolValue: true,
          ),
        ),
      ],
      "irma-demo.gemeente.personalData",
      locale: const Locale("nl", "NL"),
    );

    expect(find.text("Anna de Vries"), findsOneWidget);
    expect(
      find.textContaining("Nederlands", findRichText: true),
      findsOneWidget,
    );
    // Initials stay an ordinary row.
    expect(find.text("label-initials"), findsOneWidget);
  });
}
