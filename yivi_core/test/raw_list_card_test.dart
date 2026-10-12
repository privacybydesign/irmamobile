import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yivi_core/src/data/irma_preferences.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart"
    as schemaless;
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_groups/sections/card_sections.dart";
import "package:yivi_core/src/widgets/credential_card/irma_credential_card_options_bottom_sheet.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_attribute_list.dart";

import "helpers/test_translation_loader.dart";

schemaless.Attribute _str(String id, String value) => schemaless.Attribute(
  claimPath: [id],
  displayName: "label-$id",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.string,
    string: value,
  ),
);

schemaless.Attribute _bool(String id, bool value) => schemaless.Attribute(
  claimPath: [id],
  displayName: "label-$id",
  value: schemaless.AttributeValue(
    type: schemaless.AttributeType.boolean,
    boolValue: value,
  ),
);

const _dl = "pbdf-staging.pbdf.drivinglicence";

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("preference", () {
    Future<IrmaPreferences> freshPrefs() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await IrmaPreferences.fromInstance(
        mostRecentTermsUrlNl: "",
        mostRecentTermsUrlEn: "",
      );
      await prefs.clearAll();
      return prefs;
    }

    test("starts empty", () async {
      final prefs = await freshPrefs();
      expect(await prefs.getRawListCardTypes().first, isEmpty);
    });

    test("remembers per credential type and switches back", () async {
      final prefs = await freshPrefs();
      await prefs.setRawListCard(_dl, true);
      await prefs.setRawListCard("pbdf.pbdf.idcard", true);
      await prefs.setRawListCard(_dl, true);
      expect(await prefs.getRawListCardTypes().first, [
        _dl,
        "pbdf.pbdf.idcard",
      ]);

      await prefs.setRawListCard(_dl, false);
      expect(await prefs.getRawListCardTypes().first, ["pbdf.pbdf.idcard"]);
    });
  });

  group("attribute list", () {
    final attributes = [
      _str("firstName", "Anna"),
      _str("lastName", "de Vries"),
      _str("documentNumber", "1234567890"),
      _bool("over18", true),
      _bool("categoryB", true),
      _str("categoryBDateOfExpiry", "2030-03-01"),
      _str("categoryCDateOfExpiry", ""),
    ];

    testWidgets("raw list: every attribute as a plain row, no sections", (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardAttributeList(
            attributes,
            credentialId: _dl,
            rawList: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CardSections), findsNothing);
      expect(find.text("PERSON"), findsNothing);
      for (final a in attributes) {
        expect(find.text(a.effectiveDisplayName), findsOneWidget);
      }
      expect(find.text("Anna"), findsOneWidget);
      expect(find.text("2030-03-01"), findsOneWidget);
    });

    testWidgets("default: the card layout", (tester) async {
      await tester.pumpWidget(
        _wrap(YiviCredentialCardAttributeList(attributes, credentialId: _dl)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CardSections), findsOneWidget);
      expect(find.text("PERSON"), findsOneWidget);
    });
  });

  group("options sheet", () {
    testWidgets("offers the list when showing the card", (tester) async {
      var toggled = 0;
      await tester.pumpWidget(
        _wrap(
          IrmaCredentialCardOptionsBottomSheet(
            onDelete: () {},
            onReobtain: null,
            onToggleRawList: () => toggled++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Show as list"), findsOneWidget);
      expect(find.text("Delete data"), findsOneWidget);

      await tester.tap(find.byKey(const Key("card_option_toggle_raw_list")));
      expect(toggled, 1);
    });

    testWidgets("offers the card when showing the list", (tester) async {
      await tester.pumpWidget(
        _wrap(
          IrmaCredentialCardOptionsBottomSheet(
            onDelete: null,
            onReobtain: null,
            onToggleRawList: () {},
            rawList: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Show as card"), findsOneWidget);
    });

    testWidgets("no toggle for cards without a layout", (tester) async {
      await tester.pumpWidget(
        _wrap(
          IrmaCredentialCardOptionsBottomSheet(
            onDelete: () {},
            onReobtain: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key("card_option_toggle_raw_list")),
        findsNothing,
      );
      expect(find.text("Reobtain"), findsOneWidget);
    });
  });
}
