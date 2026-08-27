import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/irma_icon_indicator.dart";
import "package:yivi_core/src/widgets/requestor_header.dart";

/// The rung-to-banner matrix is proven here rather than in an integration test
/// because `medium` is unreachable from the app's test infrastructure: irmago
/// ships no third-party trust anchor and Yivi publishes no trust list, so no
/// live party can occupy the middle rung. irmago's own sessiontest suite stays
/// the oracle for whether a party really is medium or high.

TrustedParty _party(TrustLevel? level) => TrustedParty(
  id: "party-id",
  name: "Acme",
  url: null,
  parent: null,
  trustLevel: level,
);

Widget _testWidget({TrustedParty? requestor, SessionType? sessionType}) =>
    IrmaTheme(
      builder: (_) => MaterialApp(
        localizationsDelegates: [
          FlutterI18nDelegate(
            translationLoader: FileTranslationLoader(
              basePath: "assets/locales",
              forcedLocale: const Locale("en", "US"),
            ),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: RequestorHeader(requestor: requestor, sessionType: sessionType),
        ),
      ),
    );

String _headerText(WidgetTester tester) => tester
    .widget<RichText>(find.byKey(const Key("requestor_header_main_text")))
    .text
    .toPlainText();

void main() {
  group("requestorHeaderState", () {
    const releasing = [SessionType.disclosure, SessionType.signature];

    test("a verifier is vouched for only at high", () {
      for (final type in releasing) {
        expect(
          requestorHeaderState(_party(TrustLevel.high), type),
          HeaderState.vouched,
          reason: "$type at high",
        );
        expect(
          requestorHeaderState(_party(TrustLevel.medium), type),
          HeaderState.warning,
          reason: "$type at medium: an external CA is not Yivi",
        );
        expect(
          requestorHeaderState(_party(TrustLevel.low), type),
          HeaderState.warning,
          reason: "$type at low",
        );
      }
    });

    test("an issuer is vouched for at medium as well as high", () {
      expect(
        requestorHeaderState(_party(TrustLevel.high), SessionType.issuance),
        HeaderState.vouched,
      );
      expect(
        requestorHeaderState(_party(TrustLevel.medium), SessionType.issuance),
        HeaderState.vouched,
      );
      expect(
        requestorHeaderState(_party(TrustLevel.low), SessionType.issuance),
        HeaderState.warning,
      );
    });

    test("an unevaluated party is levelless, never low", () {
      for (final type in [...releasing, SessionType.issuance]) {
        expect(
          requestorHeaderState(_party(null), type),
          HeaderState.levelless,
          reason: "$type with no rung",
        );
      }
    });

    test("no session type asks for no verdict", () {
      for (final level in [
        TrustLevel.low,
        TrustLevel.medium,
        TrustLevel.high,
      ]) {
        expect(
          requestorHeaderState(_party(level), null),
          HeaderState.levelless,
          reason: "$level with no session type",
        );
      }
    });

    test("an absent party is levelless", () {
      expect(
        requestorHeaderState(null, SessionType.disclosure),
        HeaderState.levelless,
      );
      expect(requestorHeaderState(null, null), HeaderState.levelless);
    });
  });

  group("RequestorHeader rendering", () {
    testWidgets("a high verifier gets the vouched indicator and Yivi copy", (
      tester,
    ) async {
      await tester.pumpWidget(
        _testWidget(
          requestor: _party(TrustLevel.high),
          sessionType: SessionType.disclosure,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<IrmaStatusIndicator>(find.byType(IrmaStatusIndicator))
            .success,
        isTrue,
      );
      expect(
        _headerText(tester),
        "Acme is asking for your data. This is a known party that has "
        "registered itself with Yivi.",
      );
    });

    testWidgets("a medium verifier is warned about", (tester) async {
      await tester.pumpWidget(
        _testWidget(
          requestor: _party(TrustLevel.medium),
          sessionType: SessionType.disclosure,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<IrmaStatusIndicator>(find.byType(IrmaStatusIndicator))
            .success,
        isFalse,
      );
      expect(
        _headerText(tester),
        "Acme is asking for your data. Warning: this party is not known by Yivi.",
      );
    });

    testWidgets(
      "a medium issuer is vouched for, without claiming Yivi vouches",
      (tester) async {
        await tester.pumpWidget(
          _testWidget(
            requestor: _party(TrustLevel.medium),
            sessionType: SessionType.issuance,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<IrmaStatusIndicator>(find.byType(IrmaStatusIndicator))
              .success,
          isTrue,
        );
        final text = _headerText(tester);
        expect(
          text,
          "Acme wants to add data to your wallet. This party's identity has "
          "been confirmed.",
        );
        // The vouched issuance copy spans medium and high, so it must not claim
        // registration with Yivi — at medium that would be false.
        expect(text, isNot(contains("Yivi")));
      },
    );

    testWidgets("a low issuer is warned about", (tester) async {
      await tester.pumpWidget(
        _testWidget(
          requestor: _party(TrustLevel.low),
          sessionType: SessionType.issuance,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<IrmaStatusIndicator>(find.byType(IrmaStatusIndicator))
            .success,
        isFalse,
      );
      expect(
        _headerText(tester),
        "Acme wants to add data to your wallet. Warning: this party is not "
        "known by Yivi.",
      );
    });

    testWidgets("a levelless header shows no indicator and no verdict copy", (
      tester,
    ) async {
      await tester.pumpWidget(
        _testWidget(requestor: _party(null), sessionType: SessionType.issuance),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IrmaStatusIndicator), findsNothing);
      expect(find.byKey(const Key("requestor_header_main_text")), findsNothing);
      expect(find.text("Acme"), findsOneWidget);
    });
  });

  group("stringToTrustLevel", () {
    test("maps the three rungs", () {
      expect(stringToTrustLevel("low"), TrustLevel.low);
      expect(stringToTrustLevel("medium"), TrustLevel.medium);
      expect(stringToTrustLevel("high"), TrustLevel.high);
    });

    test("treats irmago's unevaluated zero value as no rung", () {
      expect(stringToTrustLevel(""), isNull);
    });

    test("throws on a rung this build does not know", () {
      // Deliberate hard failure: a new rung on the wire means irmago and the
      // app are out of lockstep, and the session must not render as if the
      // party had been judged.
      expect(() => stringToTrustLevel("very_high"), throwsException);
    });
  });
}
