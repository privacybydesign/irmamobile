import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/screens/activity/activity_detail_screen.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_card.dart";
import "package:yivi_core/src/screens/activity/widgets/activity_detail_disclosure.dart";
import "package:yivi_core/src/screens/session/widgets/disclosure_choices_overview.dart";
import "package:yivi_core/src/screens/session/widgets/issuance_permission.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card.dart";

import "disclosure_session/disclosure_helpers.dart";
import "helpers/helpers.dart";
import "irma_binding.dart";
import "util.dart";

const _credentialId = "irma-demo.pbdf.drivinglicence";

/// In licence-card order, as the table lists them.
const _codes = [
  "AM",
  "A1",
  "A2",
  "A",
  "B1",
  "B",
  "C1",
  "C",
  "D1",
  "D",
  "BE",
  "C1E",
  "CE",
  "D1E",
  "DE",
  "T",
];

/// One category as the issuer sends it: a Yes/No flag and two dates, each
/// empty ("") when there is nothing to say.
typedef _Category = ({String held, String issued, String expires});

const _notHeld = (held: "No", issued: "", expires: "");
const _noData = (held: "", issued: "", expires: "");

/// A licence with AM, B and BE; every other category not held.
const _defaultCategories = <String, _Category>{
  "AM": (held: "Yes", issued: "2015-03-02", expires: "2030-03-02"),
  "B": (held: "Yes", issued: "2016-05-20", expires: "2031-05-20"),
  "BE": (held: "Yes", issued: "2019-06-10", expires: "2031-05-20"),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("driving_licence_card", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("issuance shows the categories table", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);

      await startIssuanceSession(
        irmaBinding,
        groupAttributes(_attributes(_defaultCategories)),
      );
      await tester.waitFor(find.byType(IssuancePermission));

      // The ordinary attributes are still rows; the categories are not.
      final card = find.byType(YiviCredentialCard);
      expect(
        find.descendant(of: card, matching: find.text("Document number")),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text("Category B")),
        findsNothing,
      );

      // Like the detail screen: collapsed to the categories held.
      _expectHeaders(["CATEGORY", "ISSUED", "EXPIRES"]);
      _expectCodes(["AM", "B", "BE"]);
      expect(find.text("2016-05-20"), findsOneWidget);
      expect(_toggle, findsOneWidget);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitUntilDisappeared(find.byType(IssuancePermission));
    });

    testWidgets("detail screen collapses and expands the not held categories", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueDrivingLicence(tester, irmaBinding);
      await _openDetails(tester);

      _expectHeaders(["CATEGORY", "ISSUED", "EXPIRES"]);
      _expectCodes(["AM", "B", "BE"]);
      for (final date in [
        "2015-03-02",
        "2030-03-02",
        "2016-05-20",
        "2019-06-10",
      ]) {
        expect(_inTable(find.text(date)), findsOneWidget);
      }
      expect(_inTable(find.text("2031-05-20")), findsNWidgets(2));
      expect(_inTable(find.text("-")), findsNothing);
      expect(_inTable(find.text("+ 13 categories not held")), findsOneWidget);

      await _tapToggle(tester);
      _expectCodes(_codes);
      // Both dates of the 13 categories not held.
      expect(_inTable(find.text("-")), findsNWidgets(26));
      expect(_inTable(find.text("Show less")), findsOneWidget);

      await _tapToggle(tester);
      _expectCodes(["AM", "B", "BE"]);
      expect(_inTable(find.text("+ 13 categories not held")), findsOneWidget);
    });

    testWidgets("detail screen does not collapse when no category is held", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueDrivingLicence(tester, irmaBinding, categories: {});
      await _openDetails(tester);

      _expectCodes(_codes);
      expect(_inTable(find.text("-")), findsNWidgets(32));
      expect(_toggle, findsNothing);
    });

    testWidgets("detail screen does not collapse when every category is held", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueDrivingLicence(
        tester,
        irmaBinding,
        categories: {
          for (final code in _codes)
            code: (held: "Yes", issued: "2015-03-02", expires: "2030-03-02"),
        },
      );
      await _openDetails(tester);

      _expectCodes(_codes);
      expect(_inTable(find.text("-")), findsNothing);
      expect(_toggle, findsNothing);
    });

    testWidgets("detail screen without category data", (tester) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueDrivingLicence(
        tester,
        irmaBinding,
        categories: {},
        others: _noData,
      );
      await _openDetails(tester);

      expect(_inTable(find.text("No category information")), findsOneWidget);
      expect(_inTable(find.byType(Table)), findsNothing);
      expect(_toggle, findsNothing);
    });

    testWidgets("disclosing only a held flag shows a status column", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueDrivingLicence(tester, irmaBinding);

      await _startDisclosure(tester, irmaBinding, ["categoryB"]);

      _expectHeaders(["CATEGORY", "STATUS"]);
      _expectCodes(["B"]);
      expect(_inTable(find.text("Held")), findsOneWidget);
      // Nothing above the table on this card, so no divider of its own.
      expect(
        find.byKey(const Key("driving_licence_categories_divider")),
        findsNothing,
      );

      await _shareAndFinish(tester);
    });

    testWidgets("disclosing an expiry date shows only that date column", (
      tester,
    ) async {
      await pumpAndUnlockApp(tester, irmaBinding.repository);
      await _issueDrivingLicence(tester, irmaBinding);

      await _startDisclosure(tester, irmaBinding, [
        "categoryB",
        "categoryBDateOfExpiry",
      ]);

      _expectHeaders(["CATEGORY", "EXPIRES"]);
      _expectCodes(["B"]);
      expect(_inTable(find.text("2031-05-20")), findsOneWidget);
      expect(_inTable(find.text("2016-05-20")), findsNothing);

      await _shareAndFinish(tester);
    });

    testWidgets(
      "disclosure and its activity log entry show exactly the shared categories",
      (tester) async {
        await pumpAndUnlockApp(tester, irmaBinding.repository);
        await _issueDrivingLicence(tester, irmaBinding);

        await _startDisclosure(tester, irmaBinding, [
          "documentNumber",
          "categoryAM",
          "categoryB",
          "categoryC",
        ]);

        await _expectSharedCategories(tester);
        await _shareAndFinish(tester);

        await tester.tap(find.byKey(const Key("nav_button_activity")));
        await tester.pump(const Duration(seconds: 1));
        await tester.tapAndSettle(find.byType(ActivityCard).first);
        expect(find.byType(ActivityDetailsScreen), findsOneWidget);
        expect(find.byType(ActivityDetailDisclosure), findsOneWidget);

        await _expectSharedCategories(tester);
      },
    );
  });
}

/// The shared AM, B and C of the last test, wherever the card is shown.
Future<void> _expectSharedCategories(WidgetTester tester) async {
  final card = find.byType(YiviCredentialCard);
  expect(
    find.descendant(of: card, matching: find.text("Document number")),
    findsOneWidget,
  );
  expect(
    find.descendant(of: card, matching: find.text("12345678")),
    findsOneWidget,
  );
  // Below the document number row, so set apart from it.
  expect(
    find.byKey(const Key("driving_licence_categories_divider")),
    findsOneWidget,
  );

  await tester.ensureVisible(_table);
  await tester.pumpAndSettle();
  _expectHeaders(["CATEGORY", "STATUS"]);
  // A disclosure never collapses: C is listed although it is not held.
  _expectCodes(["AM", "B", "C"]);
  expect(_inTable(find.text("Held")), findsNWidgets(2));
  expect(_inTable(find.text("Not held")), findsOneWidget);
  expect(_toggle, findsNothing);
}

final _table = find.byKey(
  const Key("attribute_group_driving_licence_categories"),
);
final _toggle = find.byKey(const Key("driving_licence_categories_toggle"));

Finder _inTable(Finder matching) =>
    find.descendant(of: _table, matching: matching);

void _expectHeaders(List<String> headers) {
  for (final header in ["CATEGORY", "STATUS", "ISSUED", "EXPIRES"]) {
    expect(
      _inTable(find.text(header)),
      headers.contains(header) ? findsOneWidget : findsNothing,
      reason: "header $header",
    );
  }
}

/// The table lists exactly [codes], in this order.
void _expectCodes(List<String> codes) {
  final shown = _inTable(find.byType(Text))
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .where(_codes.contains)
      .toList();
  expect(shown, codes);
}

Future<void> _tapToggle(WidgetTester tester) async {
  await tester.ensureVisible(_toggle);
  await tester.pumpAndSettle();
  await tester.tapAndSettle(_toggle);
}

Map<String, String> _attributes(
  Map<String, _Category> categories, {
  _Category others = _notHeld,
}) => {
  "$_credentialId.documentNumber": "12345678",
  "$_credentialId.firstName": "Willeke Liselotte",
  "$_credentialId.lastName": "De Bruijn",
  "$_credentialId.issuingAuthority": "Gemeente Arnhem",
  "$_credentialId.issuingMemberState": "NL",
  "$_credentialId.dateOfBirth": "1965-04-10",
  "$_credentialId.placeOfBirth": "Arnhem",
  "$_credentialId.yearOfBirth": "1965",
  "$_credentialId.dateOfExpiry": "2031-05-20",
  "$_credentialId.over12": "Yes",
  "$_credentialId.over16": "Yes",
  "$_credentialId.over18": "Yes",
  "$_credentialId.over21": "Yes",
  "$_credentialId.over65": "No",
  "$_credentialId.activeAuthentication": "Yes",
  for (final code in _codes) ...{
    "$_credentialId.category$code": (categories[code] ?? others).held,
    "$_credentialId.category${code}DateOfIssue":
        (categories[code] ?? others).issued,
    "$_credentialId.category${code}DateOfExpiry":
        (categories[code] ?? others).expires,
  },
};

/// Issues the demo driving licence with [categories]; the categories not in
/// it get [others].
Future<void> _issueDrivingLicence(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding, {
  Map<String, _Category> categories = _defaultCategories,
  _Category others = _notHeld,
}) async {
  final attributes = _attributes(categories, others: others);
  await issueCredentials(
    tester,
    irmaBinding,
    attributes,
    attributesInGroups: {
      for (final id in attributes.keys)
        if (id.startsWith("$_credentialId.category")) id,
    },
  );
}

Future<void> _openDetails(WidgetTester tester) async {
  await tester.tapAndSettle(find.byKey(const Key("ok_button")));
  await tester.tapAndSettle(find.byKey(const Key("nav_button_data")));
  await navigateToCredentialDetailsPage(tester, _credentialId);
  await tester.ensureVisible(_table);
  await tester.pumpAndSettle();
}

/// Starts a session asking for [attributes] of the driving licence and opens
/// its overview.
Future<void> _startDisclosure(
  WidgetTester tester,
  IntegrationTestIrmaBinding irmaBinding,
  List<String> attributes,
) async {
  await tester.tapAndSettle(find.byKey(const Key("ok_button")));
  final requested = attributes.map((a) => '"$_credentialId.$a"').join(", ");
  await irmaBinding.repository.startTestSession('''
    {
      "@context": "https://irma.app/ld/request/disclosure/v2",
      "disclose": [[[ $requested ]]]
    }
  ''');
  await evaluateIntroduction(tester);
  expect(find.byType(DisclosureChoicesOverview), findsOneWidget);
  await tester.ensureVisible(_table);
  await tester.pumpAndSettle();
}

Future<void> _shareAndFinish(WidgetTester tester) async {
  await tester.tapAndSettle(find.text("Share data"));
  await evaluateShareDialog(tester);
  await evaluateFeedback(tester);
}
