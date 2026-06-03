import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

class _TestWidget extends StatelessWidget {
  final List<TrustedParty> issuers;

  const _TestWidget(this.issuers);

  @override
  Widget build(BuildContext context) => IrmaTheme(
    builder: (_) => MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: "assets/locales",
            forcedLocale: const Locale("en", "US"),
          ),
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: IssuersHeader(issuers: issuers)),
    ),
  );
}

TrustedParty _issuer({required String id, required bool verified}) =>
    TrustedParty(
      id: id,
      name: TranslatedValue.fromString("Issuer $id"),
      url: null,
      parent: null,
      verified: verified,
    );

void main() {
  testWidgets("single verified issuer renders RequestorHeader", (tester) async {
    await tester.pumpWidget(
      _TestWidget([_issuer(id: "a", verified: true)]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RequestorHeader), findsOneWidget);
    expect(find.byType(MultiIssuerBanner), findsNothing);
    final mainText =
        tester.widget<RichText>(
          find.byKey(const Key("requestor_header_main_text")),
        ).text.toPlainText();
    expect(
      mainText,
      "Issuer a wants to add data to your wallet. This is a known party that has registered itself with Yivi.",
    );
  });

  testWidgets("single unverified issuer renders RequestorHeader", (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestWidget([_issuer(id: "a", verified: false)]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RequestorHeader), findsOneWidget);
    expect(find.byType(MultiIssuerBanner), findsNothing);
    final mainText =
        tester.widget<RichText>(
          find.byKey(const Key("requestor_header_main_text")),
        ).text.toPlainText();
    expect(
      mainText,
      "Issuer a wants to add data to your wallet. Warning: this party is not known by Yivi.",
    );
  });

  testWidgets("multiple credentials with same issuer id collapse to one header", (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestWidget([
        _issuer(id: "a", verified: true),
        _issuer(id: "a", verified: true),
        _issuer(id: "a", verified: true),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RequestorHeader), findsOneWidget);
    expect(find.byType(MultiIssuerBanner), findsNothing);
  });

  testWidgets("multiple distinct issuers, all verified → MultiIssuerBanner verified", (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestWidget([
        _issuer(id: "a", verified: true),
        _issuer(id: "b", verified: true),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MultiIssuerBanner), findsOneWidget);
    expect(find.byType(RequestorHeader), findsNothing);
    final mainText =
        tester.widget<RichText>(
          find.byKey(const Key("multi_issuer_banner_main_text")),
        ).text.toPlainText();
    expect(
      mainText,
      "Multiple parties want to add data to your wallet. All of them are known by Yivi.",
    );
  });

  testWidgets("multiple distinct issuers, any unverified → MultiIssuerBanner unverified", (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestWidget([
        _issuer(id: "a", verified: true),
        _issuer(id: "b", verified: false),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MultiIssuerBanner), findsOneWidget);
    expect(find.byType(RequestorHeader), findsNothing);
    final mainText =
        tester.widget<RichText>(
          find.byKey(const Key("multi_issuer_banner_main_text")),
        ).text.toPlainText();
    expect(
      mainText,
      "Multiple parties want to add data to your wallet. Warning: not all of them are known by Yivi.",
    );
  });

  testWidgets("multiple distinct issuers, all unverified → MultiIssuerBanner unverified", (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestWidget([
        _issuer(id: "a", verified: false),
        _issuer(id: "b", verified: false),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MultiIssuerBanner), findsOneWidget);
    expect(find.byType(RequestorHeader), findsNothing);
    final mainText =
        tester.widget<RichText>(
          find.byKey(const Key("multi_issuer_banner_main_text")),
        ).text.toPlainText();
    expect(
      mainText,
      "Multiple parties want to add data to your wallet. Warning: not all of them are known by Yivi.",
    );
  });

  test("empty issuers list throws assertion", () {
    expect(() => IssuersHeader(issuers: const []), throwsAssertionError);
  });
}
