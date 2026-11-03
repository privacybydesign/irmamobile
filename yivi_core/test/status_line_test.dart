import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/models/card_expiry_date.dart";
import "package:yivi_core/src/widgets/credential_card/models/credential_card_status.dart";
import "package:yivi_core/src/widgets/credential_card/models/status_line.dart";
import "package:yivi_core/src/widgets/credential_card/yivi_credential_card_footer.dart";

import "helpers/test_translation_loader.dart";

final _date = DateTime(2027, 7, 12);

List<StatusLineItem> _items({
  DateTime? date,
  int? count,
  ExpireState time = ExpireState.notExpired,
  ExpireState instances = ExpireState.notExpired,
}) => statusLineItems(
  expiryDate: date == null ? null : CardExpiryDate(date),
  instanceCount: count,
  timeState: time,
  instanceState: instances,
  formatDate: (d) => "${d.year}-${d.month}-${d.day}",
);

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
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group("statusLineItems", () {
    test("normal: valid until a date, shares left, both calm", () {
      final [validity, shares] = _items(date: _date, count: 24);
      expect(validity.translationKey, "credential.status_line.valid_until");
      expect(validity.params, {"date": "2027-7-12"});
      expect(validity.tone, StatusTone.calm);
      expect(shares.translationKey, "credential.status_line.shares_left");
      expect(shares.params, {"count": "24"});
      expect(shares.tone, StatusTone.calm);
    });

    test("no date: valid indefinitely", () {
      final [validity, _] = _items(count: 3);
      expect(
        validity.translationKey,
        "credential.status_line.valid_indefinitely",
      );
      expect(validity.tone, StatusTone.calm);
    });

    test("no count: unlimited sharing", () {
      final [_, shares] = _items(date: _date);
      expect(shares.translationKey, "credential.status_line.shares_unlimited");
      expect(shares.tone, StatusTone.calm);
    });

    test("expiring soon: a warning with the days left", () {
      final soon = DateTime.now().add(const Duration(days: 5, hours: 1));
      final [validity, _] = _items(
        date: soon,
        count: 24,
        time: ExpireState.almostExpired,
      );
      expect(validity.translationKey, "credential.status_line.expires_in");
      expect(validity.pluralCount, 5);
      expect(validity.tone, StatusTone.warning);
    });

    test("expired: an error with the date", () {
      final [validity, _] = _items(
        date: _date,
        count: 24,
        time: ExpireState.expired,
      );
      expect(validity.translationKey, "credential.status_line.expired_on");
      expect(validity.tone, StatusTone.error);
    });

    test("few shares left: a warning", () {
      final [_, shares] = _items(
        date: _date,
        count: 2,
        instances: ExpireState.almostExpired,
      );
      expect(shares.translationKey, "credential.status_line.shares_few");
      expect(shares.params, {"count": "2"});
      expect(shares.tone, StatusTone.warning);
    });

    test("no shares left: an error", () {
      final [_, shares] = _items(
        date: _date,
        count: 0,
        instances: ExpireState.expired,
      );
      expect(shares.translationKey, "credential.status_line.shares_none");
      expect(shares.tone, StatusTone.error);
    });
  });

  group("footer", () {
    Future<void> pump(
      WidgetTester tester, {
      DateTime? date,
      int? count,
      ExpireState time = ExpireState.notExpired,
      ExpireState instances = ExpireState.notExpired,
      Locale locale = const Locale("en", "US"),
    }) async {
      await tester.pumpWidget(
        _wrap(
          YiviCredentialCardFooter(
            expiryDate: date == null ? null : CardExpiryDate(date),
            instanceCount: count,
            timeBasedExpireState: time,
            instanceBasedExpireState: instances,
          ),
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
    }

    BoxDecoration? decoration(WidgetTester tester, String kind) =>
        tester
                .widget<Container>(find.byKey(Key("status_line_$kind")))
                .decoration
            as BoxDecoration?;

    testWidgets("normal: one calm centred line", (tester) async {
      await pump(tester, date: _date, count: 24);
      expect(find.text("Valid until July 12, 2027"), findsOneWidget);
      expect(find.text("24 shares left"), findsOneWidget);
      expect(decoration(tester, "validity"), isNull, reason: "no pill");
      expect(decoration(tester, "shares"), isNull);
      // Both items on one line, centred together.
      final validity = tester.getRect(
        find.byKey(const Key("status_line_validity")),
      );
      final shares = tester.getRect(
        find.byKey(const Key("status_line_shares")),
      );
      expect(validity.top, shares.top);
      final center = tester.getCenter(find.byType(YiviCredentialCardFooter));
      expect(
        ((validity.left + shares.right) / 2 - center.dx).abs(),
        lessThan(1),
      );
    });

    testWidgets("Dutch texts", (tester) async {
      await pump(
        tester,
        date: _date,
        count: 24,
        locale: const Locale("nl", "NL"),
      );
      expect(find.text("Geldig t/m 12 juli 2027"), findsOneWidget);
      expect(find.text("24× te delen"), findsOneWidget);
    });

    testWidgets("few shares left: an amber pill", (tester) async {
      final theme = IrmaThemeData();
      await pump(
        tester,
        date: _date,
        count: 2,
        instances: ExpireState.almostExpired,
      );
      expect(find.text("Only 2 shares left"), findsOneWidget);
      expect(decoration(tester, "shares")?.color, theme.warningSurface);
      expect(decoration(tester, "validity"), isNull);
    });

    testWidgets("expiring soon: an amber pill with the days", (tester) async {
      await pump(
        tester,
        date: DateTime.now().add(const Duration(days: 1, hours: 1)),
        count: 24,
        time: ExpireState.almostExpired,
      );
      expect(find.text("Expires in 1 day"), findsOneWidget);
      expect(decoration(tester, "validity"), isNotNull);
    });

    testWidgets("expired and no shares: red pills", (tester) async {
      final theme = IrmaThemeData();
      await pump(
        tester,
        date: _date,
        count: 0,
        time: ExpireState.expired,
        instances: ExpireState.expired,
      );
      expect(find.text("Expired on July 12, 2027"), findsOneWidget);
      expect(find.text("No shares left"), findsOneWidget);
      expect(decoration(tester, "validity")?.color, theme.errorSurface);
      expect(decoration(tester, "shares")?.color, theme.errorSurface);
    });

    testWidgets("unlimited and indefinite", (tester) async {
      await pump(tester);
      expect(find.text("Valid indefinitely"), findsOneWidget);
      expect(find.text("Unlimited sharing"), findsOneWidget);
    });
  });
}
