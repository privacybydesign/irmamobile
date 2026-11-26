import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/credential.dart";
import "package:yivi_core/src/widgets/credential_card/card_attribute_list.dart";

import "support/test_app.dart";

Widget _wrap(Widget child) =>
    testApp(Scaffold(body: SingleChildScrollView(child: child)));

/// A section header: an object or array with a display name.
Attribute _header(List<dynamic> path, String name) =>
    Attribute(claimPath: path, displayName: name);

Attribute _value(List<dynamic> path, String? name, String value) => Attribute(
  claimPath: path,
  displayName: name,
  value: AttributeValue(type: AttributeType.string, string: value),
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
List<Attribute> _university() => [
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
      await tester.pumpWidget(_wrap(CardAttributeList(_university())));
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
      await tester.pumpWidget(_wrap(CardAttributeList(_university())));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Faculties"));
      await tester.pumpAndSettle();
      expect(find.text("Faculty of Science, Faculty of Arts"), findsOneWidget);
      expect(find.text("History"), findsNothing);

      await tester.tap(find.text("Faculties"));
      await tester.pumpAndSettle();
      expect(find.text("History"), findsOneWidget);
    });

    testWidgets("an item folds on its own at its place", (tester) async {
      await tester.pumpWidget(_wrap(CardAttributeList(_university())));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text("2 of 2").first);
      await tester.tap(find.text("2 of 2").first);
      await tester.pumpAndSettle();
      expect(find.text("Faculty of Arts"), findsOneWidget);
      expect(find.text("Phonetics"), findsNothing);
      // The other item stays open.
      expect(find.text("Cryptography"), findsOneWidget);
    });

    testWidgets("an item box inside an open box folds at its header", (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(CardAttributeList(_university())));
      await tester.pumpAndSettle();

      // Faculty of Arts has two departments: "1 of 2" and "2 of 2" again.
      expect(find.text("2 of 2"), findsNWidgets(2));
      await tester.ensureVisible(find.text("2 of 2").last);
      await tester.tap(find.text("2 of 2").last);
      await tester.pumpAndSettle();
      expect(find.text("Linguistics"), findsOneWidget);
      expect(find.text("Phonetics"), findsNothing);
      expect(find.text("Medieval Europe"), findsOneWidget);
    });

    testWidgets("no value is a title: every value is a labelled row", (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(CardAttributeList(_university())));
      await tester.pumpAndSettle();

      expect(find.text("Faculty"), findsNWidgets(2));
      expect(find.text("Department"), findsNWidgets(3));
    });

    testWidgets("a top-level object is one card", (tester) async {
      await tester.pumpWidget(
        _wrap(
          CardAttributeList([
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
        _wrap(CardAttributeList(_university(), disclosure: true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Faculties"));
      await tester.tap(find.text("Faculty of Arts"));
      await tester.pumpAndSettle();
      expect(find.text("Phonetics"), findsOneWidget);
    });

    testWidgets("folds when asked to", (tester) async {
      await tester.pumpWidget(
        _wrap(
          CardAttributeList(_university(), disclosure: true, foldable: true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Faculties"));
      await tester.pumpAndSettle();
      expect(find.text("Faculty of Science, Faculty of Arts"), findsOneWidget);
    });

    testWidgets("a one-item list has no header, a longer one its places", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CardAttributeList([
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

      expect(find.text("1 of 1"), findsNothing);
      expect(find.text("1 of 2"), findsOneWidget);
      expect(find.text("2 of 2"), findsOneWidget);
      expect(find.text("Faculty of Arts"), findsNothing);
      expect(find.text("History"), findsOneWidget);
      expect(find.text("Linguistics"), findsOneWidget);
    });
  });
}
