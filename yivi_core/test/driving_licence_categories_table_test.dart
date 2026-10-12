import "dart:io";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/attribute_group.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/driving_licence/driving_licence_categories_renderer.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/driving_licence/driving_licence_categories_table.dart";

import "helpers/test_translation_loader.dart";

Widget _wrap(
  Widget child, {
  Locale locale = const Locale("en", "US"),
  bool disclosure = false,
}) => IrmaTheme(
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
    home: Scaffold(
      body: SingleChildScrollView(
        child: AttributeGroupScope(
          isFirst: false,
          isDisclosure: disclosure,
          child: child,
        ),
      ),
    ),
  ),
);

CompareValue<T> _v<T>(T value) => CompareValue(value, AttributeComparison.none);

/// As on the credential detail screen.
DrivingLicenceCategoriesView _full({required List<CategoryRow> rows}) =>
    DrivingLicenceCategoriesView(
      rows: rows,
      showsIssued: true,
      showsExpires: true,
    );

/// A disclosure: the held flags, plus whichever dates were requested.
DrivingLicenceCategoriesView _shared(
  List<CategoryRow> rows, {
  bool issued = false,
  bool expires = false,
}) => DrivingLicenceCategoriesView(
  rows: rows,
  showsIssued: issued,
  showsExpires: expires,
);

void main() {
  final view = _full(
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
      // Only the expiry date was given.
      CategoryRow(code: "T", expires: _v("2029-01-01")),
    ],
  );

  testWidgets("lays categories out as a Category / Issued / Expires table", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(DrivingLicenceCategoriesTable(view: view)));
    await tester.pumpAndSettle();

    // The detail / issuance layout: no status column, plain ISO dates.
    expect(find.text("CATEGORY"), findsOneWidget);
    expect(find.text("STATUS"), findsNothing);
    expect(find.text("ISSUED"), findsOneWidget);
    expect(find.text("EXPIRES"), findsOneWidget);

    expect(find.text("2015-03-01"), findsOneWidget);
    // Issued sits left of expires on the B row.
    expect(
      tester.getTopLeft(find.text("2015-03-01")).dx,
      lessThan(tester.getTopLeft(find.text("2030-03-01").first).dx),
    );

    expect(find.text("2029-01-01"), findsOneWidget);
  });

  testWidgets("collapsed shows held categories and a summary row", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(DrivingLicenceCategoriesTable(view: view)));
    await tester.pumpAndSettle();

    // Collapsed: B, BE and T (its expiry date makes it a held row), not C.
    expect(find.text("B"), findsOneWidget);
    expect(find.text("BE"), findsOneWidget);
    expect(find.text("T"), findsOneWidget);
    expect(find.text("C"), findsNothing);
    expect(find.text("-"), findsNothing);

    // The summary row says how many are hidden, below the table, spanning
    // its full width, with a chevron at the right.
    final summary = find.text("+ 1 category not held");
    expect(summary, findsOneWidget);
    expect(
      tester.widget<Text>(summary).style?.fontWeight,
      FontWeight.w400,
      reason: "not bold",
    );
    final linkColor = IrmaTheme.of(tester.element(summary)).link;
    expect(tester.widget<Text>(summary).style?.color, linkColor);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.expand_more)).color,
      linkColor,
    );
    final toggle = find.byKey(const Key("driving_licence_categories_toggle"));
    final tableBox = find.byType(Table);
    expect(
      tester.getTopLeft(toggle).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(tableBox).dy),
    );
    expect(
      tester.getSize(toggle).width,
      closeTo(tester.getSize(tableBox).width, 1),
    );
    expect(find.byIcon(Icons.expand_more), findsOneWidget);

    // The whole row is the tap target: tapping the chevron expands too.
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    // Expanded: the not-held C row with dashes, like the licence card. The T
    // row's issue date was not given, so it stays blank rather than a dash.
    expect(find.text("C"), findsOneWidget);
    expect(find.text("-"), findsNWidgets(2));
    expect(find.text("Show less"), findsOneWidget);

    await tester.tap(find.text("Show less"));
    await tester.pumpAndSettle();
    expect(find.text("C"), findsNothing);
    expect(summary, findsOneWidget);
  });

  testWidgets("columns do not shift when expanding to longer codes", (
    tester,
  ) async {
    // Collapsed shows only "B"; expanding reveals the three-letter "C1E".
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(
          view: _full(
            rows: [
              CategoryRow(
                code: "B",
                held: _v<bool?>(true),
                issued: _v("2015-03-01"),
                expires: _v("2030-03-01"),
              ),
              CategoryRow(code: "C1E", held: _v<bool?>(false)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text("2015-03-01")).dx;
    final headerBefore = tester.getTopLeft(find.text("ISSUED")).dx;

    await tester.tap(
      find.byKey(const Key("driving_licence_categories_toggle")),
    );
    await tester.pumpAndSettle();
    expect(find.text("C1E"), findsOneWidget);

    expect(tester.getTopLeft(find.text("2015-03-01")).dx, before);
    expect(tester.getTopLeft(find.text("ISSUED")).dx, headerBefore);
  });

  group("scrolling on expand / collapse", () {
    // B held, five more not held: expanding adds five rows.
    final sixRows = _full(
      rows: [
        for (final code in ["AM", "A1", "A2", "A", "B1", "B"])
          code == "B"
              ? CategoryRow(
                  code: code,
                  held: _v<bool?>(true),
                  issued: _v("2015-03-01"),
                  expires: _v("2030-03-01"),
                )
              : CategoryRow(code: code, held: _v<bool?>(false)),
      ],
    );
    final toggle = find.byKey(const Key("driving_licence_categories_toggle"));
    double offset(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    Future<void> toggleAndSettle(WidgetTester tester) async {
      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    }

    final title = find.text("Driving licence categories");

    Widget page({double above = 400, double below = 1000}) => _wrap(
      Column(
        children: [
          SizedBox(height: above),
          DrivingLicenceCategoriesTable(view: sixRows),
          SizedBox(height: below),
        ],
      ),
    );

    testWidgets("expanding puts the title at the top of the scroll view", (
      tester,
    ) async {
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(offset(tester), 0);

      await toggleAndSettle(tester);

      expect(find.text("AM"), findsOneWidget, reason: "expanded");
      // The scroll view starts at y = 0 on this test screen (no app bar).
      expect(tester.getTopLeft(title).dy, closeTo(0, 0.5));
    });

    testWidgets("collapsing puts the title at the top too", (tester) async {
      await tester.pumpWidget(page(above: 100));
      await tester.pumpAndSettle();
      await toggleAndSettle(tester); // expand

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      position.jumpTo(0);
      await tester.pumpAndSettle();

      await toggleAndSettle(tester); // collapse

      expect(find.text("AM"), findsNothing, reason: "collapsed");
      expect(tester.getTopLeft(title).dy, closeTo(0, 0.5));
    });

    testWidgets("scrolls as far as it can when the content ends", (
      tester,
    ) async {
      // Short page: not enough content below to bring the title to the top.
      await tester.pumpWidget(page(above: 300, below: 0));
      await tester.pumpAndSettle();

      await toggleAndSettle(tester);

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.pixels, position.maxScrollExtent);
      expect(tester.getTopLeft(title).dy, greaterThan(0));
    });
  });

  testWidgets("three-letter codes stay on one line", (tester) async {
    await tester.pumpWidget(
      _wrap(
        // An inherited style that makes text wider than the bare value style,
        // as the app's theme can.
        DefaultTextStyle.merge(
          style: const TextStyle(letterSpacing: 2),
          child: DrivingLicenceCategoriesTable(
            view: _full(
              rows: [
                CategoryRow(
                  code: "B",
                  held: _v<bool?>(true),
                  issued: _v("2015-03-01"),
                  expires: _v("2030-03-01"),
                ),
                CategoryRow(
                  code: "D1E",
                  held: _v<bool?>(true),
                  issued: _v("2016-04-01"),
                  expires: _v("2030-03-01"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.text("D1E")).height,
      tester.getSize(find.text("B")).height,
      reason: "no wrap onto a second line",
    );
    // And it doesn't run into the next column.
    expect(
      tester.getTopRight(find.text("D1E")).dx,
      lessThanOrEqualTo(tester.getTopLeft(find.text("2016-04-01")).dx),
    );
  });

  testWidgets("summary row counts every hidden category", (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(
          view: _full(
            rows: [
              for (final code in DrivingLicenceCategoriesRenderer.codes)
                CategoryRow(
                  code: code,
                  held: _v<bool?>(code == "B"),
                  issued: code == "B" ? _v("2015-03-01") : null,
                  expires: code == "B" ? _v("2030-03-01") : null,
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("+ 15 categories not held"), findsOneWidget);
  });

  testWidgets("a divider with space above sets the section apart", (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(DrivingLicenceCategoriesTable(view: view)));
    await tester.pumpAndSettle();

    final table = find.byKey(
      const Key("attribute_group_driving_licence_categories"),
    );
    final divider = find.byKey(const Key("driving_licence_categories_divider"));
    expect(tester.getSize(divider).height, 1);
    // Space above the divider, and the divider above the title.
    expect(tester.getTopLeft(divider).dy - tester.getTopLeft(table).dy, 8);
    expect(
      tester.getTopLeft(divider).dy,
      lessThan(tester.getTopLeft(find.text("Driving licence categories")).dy),
    );
  });

  group("status column", () {
    final b = CategoryRow(code: "B", held: _v<bool?>(true));
    final d = CategoryRow(code: "D", held: _v<bool?>(false));

    testWidgets("shows ownership from the held flag", (tester) async {
      await tester.pumpWidget(
        _wrap(
          DrivingLicenceCategoriesTable(view: _shared([b, d])),
          disclosure: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Held"), findsOneWidget);
      expect(find.text("Not held"), findsOneWidget);
    });

    testWidgets("Dutch: In bezit / Niet in bezit", (tester) async {
      await tester.pumpWidget(
        _wrap(
          DrivingLicenceCategoriesTable(view: _shared([b, d])),
          locale: const Locale("nl", "NL"),
          disclosure: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("In bezit"), findsOneWidget);
      expect(find.text("Niet in bezit"), findsOneWidget);
    });
  });

  group("disclosure", () {
    final toggle = find.byKey(const Key("driving_licence_categories_toggle"));

    testWidgets("flags only: every shared category, no dates, no toggle", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DrivingLicenceCategoriesTable(
            view: _shared([
              CategoryRow(code: "B", held: _v<bool?>(true)),
              CategoryRow(code: "D", held: _v<bool?>(false)),
            ]),
          ),
          disclosure: true,
        ),
      );
      await tester.pumpAndSettle();

      // Both shared categories, the not-held D included, without a tap.
      expect(find.text("B"), findsOneWidget);
      expect(find.text("D"), findsOneWidget);
      expect(toggle, findsNothing);
      // No dates were shared, so no date columns.
      expect(find.text("FROM"), findsNothing);
      expect(find.text("UNTIL"), findsNothing);
      expect(find.text("-"), findsNothing);
    });

    testWidgets("flags + expiry: only the expiry column, no status", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          DrivingLicenceCategoriesTable(
            view: _shared([
              CategoryRow(
                code: "B",
                held: _v<bool?>(true),
                expires: _v("2030-03-01"),
              ),
              CategoryRow(code: "D", held: _v<bool?>(false)),
            ], expires: true),
          ),
          disclosure: true,
        ),
      );
      await tester.pumpAndSettle();

      // The requested date column, as on the detail screen; it shows who
      // holds what, so no status column.
      expect(find.text("ISSUED"), findsNothing);
      expect(find.text("EXPIRES"), findsOneWidget);
      expect(find.text("STATUS"), findsNothing);
      expect(find.text("2030-03-01"), findsOneWidget);
      expect(find.text("-"), findsOneWidget, reason: "D has no expiry date");
      expect(toggle, findsNothing);
    });
  });

  testWidgets("Dutch summary row", (tester) async {
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(view: view),
        locale: const Locale("nl", "NL"),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("+ 1 categorie niet in bezit"), findsOneWidget);
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
    // B, BE (+ trailer), T — in row order; C is collapsed away.
    expect(pictograms, ["car.svg", "car.svg", "trailer.svg", "tractor.svg"]);

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
    expect(find.text("STATUS"), findsNothing);
  });

  testWidgets("detail screen without dates for unheld categories", (
    tester,
  ) async {
    // As irmago sends a held credential: empty optional attributes (the dates
    // of categories not held) are left out entirely.
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(
          view: DrivingLicenceCategoriesView(
            rows: [
              CategoryRow(
                code: "B",
                held: _v<bool?>(true),
                issued: _v("2015-03-01"),
                expires: _v("2030-03-01"),
              ),
              CategoryRow(code: "C", held: _v<bool?>(false)),
            ],
            showsIssued: true,
            showsExpires: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("ISSUED"), findsOneWidget);
    expect(find.text("STATUS"), findsNothing);
    expect(find.text("2015-03-01"), findsOneWidget);
    expect(
      find.byKey(const Key("driving_licence_categories_toggle")),
      findsOneWidget,
      reason: "collapsible on the detail screen",
    );
  });

  testWidgets("disclosure with both dates: the detail columns, not collapsed", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(
          view: _shared(view.rows, issued: true, expires: true),
        ),
        locale: const Locale("nl", "NL"),
        disclosure: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("CATEGORIE"), findsOneWidget);
    expect(find.text("AFGEGEVEN"), findsOneWidget);
    expect(find.text("VERLOOPT"), findsOneWidget);
    expect(find.text("STATUS"), findsNothing);
    expect(find.text("2015-03-01"), findsOneWidget);
    // Every shared category, the not-held C with dashes, without a toggle.
    expect(find.text("C"), findsOneWidget);
    expect(
      find.byKey(const Key("driving_licence_categories_toggle")),
      findsNothing,
    );
  });

  testWidgets("a licence holding nothing still lists every category", (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        DrivingLicenceCategoriesTable(
          view: _full(
            rows: [
              for (final code in DrivingLicenceCategoriesRenderer.codes)
                CategoryRow(code: code, held: _v<bool?>(false)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Nothing held: nothing to collapse to, so every row and no toggle.
    expect(find.text("-"), findsNWidgets(32));
    expect(
      find.byKey(const Key("driving_licence_categories_toggle")),
      findsNothing,
    );
  });

  testWidgets("fits a narrow phone card without overflowing", (tester) async {
    final wide = _full(
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
