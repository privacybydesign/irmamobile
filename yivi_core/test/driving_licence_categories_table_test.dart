import "dart:io";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/driving_licence/driving_licence_categories_renderer.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/driving_licence/driving_licence_categories_table.dart";

import "helpers/test_translation_loader.dart";

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

CompareValue<T> _v<T>(T value) => CompareValue(value, AttributeComparison.none);

void main() {
  final view = DrivingLicenceCategoriesView(
    rows: [
      CategoryRow(
        code: "B",
        held: _v<bool?>(true),
        issued: _v("2015-03-01"),
        expires: _v("2030-03-01"),
      ),
      CategoryRow(
        code: "BE",
        held: _v<bool?>(true),
        issued: _v("2016-04-01"),
        expires: _v("2030-03-01"),
      ),
      CategoryRow(code: "C", held: _v<bool?>(false)),
      // A disclosure of only the expiry date.
      CategoryRow(code: "T", expires: _v("2029-01-01")),
    ],
  );

  testWidgets("lays categories out as a Category / Issued / Expires table", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(DrivingLicenceCategoriesTable(view: view)));
    await tester.pumpAndSettle();

    expect(find.text("CATEGORY"), findsOneWidget);
    expect(find.text("ISSUED"), findsOneWidget);
    expect(find.text("EXPIRES"), findsOneWidget);

    expect(find.text("2015-03-01"), findsOneWidget);
    // Issued sits left of expires on the B row.
    expect(
      tester.getTopLeft(find.text("2015-03-01")).dx,
      lessThan(tester.getTopLeft(find.text("2030-03-01").first).dx),
    );

    expect(find.text("2029-01-01"), findsOneWidget);
    // Not held: dashes, like the licence card. The T row's issue date was not
    // given, so it stays blank rather than showing a dash.
    expect(find.text("-"), findsNWidgets(2));
  });

  testWidgets("prefixes rows with vehicle pictograms, trailers for E", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(DrivingLicenceCategoriesTable(view: view)));
    await tester.pumpAndSettle();

    final pictograms = [
      for (final svg in tester.widgetList<SvgPicture>(find.byType(SvgPicture)))
        (svg.bytesLoader as SvgAssetLoader).assetName.split("/").last,
    ];
    // B, BE (+ trailer), C, T — in row order.
    expect(pictograms, [
      "car.svg",
      "car.svg",
      "trailer.svg",
      "truck.svg",
      "tractor.svg",
    ]);

    // Pictograms are right-aligned against their code: a lone car and a
    // car + trailer both end the same distance before the code.
    final svgsInRows = find.byType(SvgPicture);
    final gapB =
        tester.getTopLeft(find.text("B")).dx -
        tester.getTopRight(svgsInRows.at(0)).dx;
    final gapBE =
        tester.getTopLeft(find.text("BE")).dx -
        tester.getTopRight(svgsInRows.at(2)).dx;
    expect(gapB, greaterThanOrEqualTo(8));
    expect(gapB, lessThan(12));
    expect(gapBE, gapB);

    // The trailer is towed: behind (right of) the left-facing car.
    final svgs = find.byType(SvgPicture);
    expect(
      tester.getTopLeft(svgs.at(2)).dx,
      greaterThan(tester.getTopLeft(svgs.at(1)).dx),
    );
  });

  testWidgets("Dutch headers match the licence card", (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(view: view),
        locale: const Locale("nl", "NL"),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("CATEGORIE"), findsOneWidget);
    expect(find.text("AFGEGEVEN"), findsOneWidget);
    expect(find.text("VERLOOPT"), findsOneWidget);
  });

  testWidgets("a licence holding nothing still lists every category", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(
          view: DrivingLicenceCategoriesView(
            rows: [
              for (final code in DrivingLicenceCategoriesRenderer.codes)
                CategoryRow(code: code, held: _v<bool?>(false)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("-"), findsNWidgets(32));
  });

  testWidgets("fits a narrow phone card without overflowing", (tester) async {
    final wide = DrivingLicenceCategoriesView(
      rows: [
        CategoryRow(
          code: "D1E",
          held: _v<bool?>(true),
          issued: _v("2015-03-01"),
          expires: _v("2030-03-01"),
        ),
      ],
    );
    // Roughly the content width of a credential card on a 320pt-wide phone.
    await tester.pumpWidget(
      _wrap(
        Center(
          child: SizedBox(
            width: 260,
            child: DrivingLicenceCategoriesTable(view: wide),
          ),
        ),
        locale: const Locale("nl", "NL"),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test("every pictogram exists as an asset", () {
    for (final code in DrivingLicenceCategoriesRenderer.codes) {
      final (asset, _) = vehicleIcons(code);
      expect(File("assets/vehicles/$asset.svg").existsSync(), isTrue);
    }
    expect(File("assets/vehicles/trailer.svg").existsSync(), isTrue);
  });

  test("E categories tow a trailer, except CE which is articulated", () {
    for (final code in DrivingLicenceCategoriesRenderer.codes) {
      final (asset, trailer) = vehicleIcons(code);
      if (code == "CE") {
        expect((asset, trailer), ("articulated", false));
      } else {
        expect(trailer, code.endsWith("E"), reason: code);
      }
    }
  });

  test("each row's pictogram matches the licence card", () {
    expect(
      {
        for (final code in DrivingLicenceCategoriesRenderer.codes)
          code: vehicleIcons(code).$1,
      },
      {
        "AM": "moped",
        "A1": "motorcycle_light",
        "A2": "motorcycle_medium",
        "A": "motorcycle",
        "B1": "van",
        "B": "car",
        "C1": "truck_small",
        "C": "truck",
        "D1": "minibus",
        "D": "bus",
        "BE": "car",
        "C1E": "truck_small",
        "CE": "articulated",
        "D1E": "minibus",
        "DE": "bus",
        "T": "tractor",
      },
    );
  });
}
