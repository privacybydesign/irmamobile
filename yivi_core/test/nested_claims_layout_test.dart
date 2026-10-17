import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

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

/// A section header: an object or array with a display name.
schemaless.Attribute _header(List<dynamic> path, String name) =>
    schemaless.Attribute(claimPath: path, displayName: name);

schemaless.Attribute _value(List<dynamic> path, String? name, String value) =>
    schemaless.Attribute(
      claimPath: path,
      displayName: name,
      value: schemaless.AttributeValue(
        type: schemaless.AttributeType.string,
        string: value,
      ),
    );

const _faculties = [
  (
    "Faculty of Science",
    [
      ("Computer Science", ["Cryptography", "Distributed Systems"]),
    ],
  ),
  (
    "Faculty of Arts",
    [
      ("History", ["Medieval Europe", "Modern Asia"]),
      ("Linguistics", ["Phonetics", "Syntax"]),
    ],
  ),
];

/// The university credential of the design, flattened the way irmago sends
/// it: a header per named object or array, then its values.
List<schemaless.Attribute> _university() => [
  _value(["name"], "Name", "Radboud University"),
  _value(["founded"], "Founded", "1923"),
  _header(["faculties"], "Faculties"),
  for (final (f, (faculty, departments)) in _faculties.indexed) ...[
    _value(["faculties", f, "faculty_name"], "Faculty", faculty),
    _header(["faculties", f, "departments"], "Departments"),
    for (final (d, (department, courses)) in departments.indexed) ...[
      _value(
        ["faculties", f, "departments", d, "dept_name"],
        "Department",
        department,
      ),
      _header(["faculties", f, "departments", d, "courses"], "Courses"),
      for (final (c, course) in courses.indexed)
        _value(["faculties", f, "departments", d, "courses", c], null, course),
    ],
  ],
];

const _allCourses = [
  "Cryptography",
  "Distributed Systems",
  "Medieval Europe",
  "Modern Asia",
  "Phonetics",
  "Syntax",
];

void main() {
  group("a credential's own values", () {
    testWidgets("everything starts open: one card per item", (tester) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList(_university())),
      );
      await tester.pumpAndSettle();

      expect(find.text("Faculties"), findsOneWidget);
      expect(find.text("Faculty of Science"), findsOneWidget);
      expect(find.text("Faculty of Arts"), findsOneWidget);
      expect(find.text("History"), findsOneWidget);
      expect(find.text("Linguistics"), findsOneWidget);
      for (final course in _allCourses) {
        expect(find.text(course), findsOneWidget);
      }
    });

    testWidgets("the list folds to its item names", (tester) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList(_university())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Faculties"));
      await tester.pumpAndSettle();
      expect(find.text("Faculty of Science, Faculty of Arts"), findsOneWidget);
      expect(find.text("History"), findsNothing);

      await tester.tap(find.text("Faculties"));
      await tester.pumpAndSettle();
      expect(find.text("History"), findsOneWidget);
    });

    testWidgets("a card folds on its own to what it holds", (tester) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList(_university())),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Faculty of Arts"));
      await tester.pumpAndSettle();
      expect(find.text("History, Linguistics"), findsOneWidget);
      expect(find.text("Phonetics"), findsNothing);
      // The other card stays open.
      expect(find.text("Cryptography"), findsOneWidget);
    });

    testWidgets("a top-level object is one card", (tester) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _header(["address"], "Address"),
            _value(["address", "city"], "City", "Nijmegen"),
            _value(["address", "country"], "Country", "Netherlands"),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Nijmegen"), findsOneWidget);

      await tester.tap(find.text("Address"));
      await tester.pumpAndSettle();
      expect(find.text("Nijmegen, Netherlands"), findsOneWidget);
    });
  });

  group("a disclosure", () {
    testWidgets("nothing folds", (tester) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList(_university(), disclosure: true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Faculties"));
      await tester.tap(find.text("Faculty of Arts"));
      await tester.pumpAndSettle();
      expect(find.text("Phonetics"), findsOneWidget);
    });

    testWidgets("an item without its title is named by its place", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList([
            _header(["faculties"], "Faculties"),
            _header(["faculties", 1, "departments"], "Departments"),
            _value(
              ["faculties", 1, "departments", 0, "dept_name"],
              "Department",
              "History",
            ),
            _value(
              ["faculties", 1, "departments", 1, "dept_name"],
              "Department",
              "Linguistics",
            ),
          ], disclosure: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Faculties 2"), findsOneWidget);
      expect(find.text("Faculty of Arts"), findsNothing);
      expect(find.text("History"), findsOneWidget);
      expect(find.text("Linguistics"), findsOneWidget);
    });
  });
}
