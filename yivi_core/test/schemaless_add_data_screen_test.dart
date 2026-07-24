import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/providers/nfc_availability_provider.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";
import "package:yivi_core/src/screens/add_data/schemaless_add_data_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/schemaless_yivi_credential_type_card.dart";

CredentialStoreItem _item(String credentialId, String name) =>
    CredentialStoreItem(
      credential: CredentialDescriptor(
        credentialId: credentialId,
        name: name,
        issuer: TrustedParty(
          id: "issuer",
          name: "Issuer",
          url: null,
          parent: null,
          verified: true,
        ),
        category: "Personal",
        attributes: [],
        issueURL: null,
      ),
      faq: Faq(
        intro: "intro",
        purpose: "purpose",
        content: "content",
        howTo: "howto",
      ),
    );

// Store always contains an NFC-requiring credential (passport) and one that
// does not need NFC (email), in a single category.
final _store = [
  CredentialStoreCategory(
    category: "Personal",
    items: [
      _item("pbdf.pbdf.passport", "Passport"),
      _item("pbdf.sidn-pbdf.email", "Email"),
    ],
  ),
];

/// Builds the add-data screen with the credential store stubbed out and the
/// NFC-availability result controlled by [nfcAvailable] (pass `null` to keep
/// the check pending → AsyncLoading, i.e. the "still loading" case).
Widget _testWidget({required bool? nfcAvailable}) {
  return ProviderScope(
    overrides: [
      groupedCredentialStoreProvider.overrideWith(
        (ref) => Stream.value(_store),
      ),
      nfcAvailableProvider.overrideWith(
        (ref) => nfcAvailable == null
            // Never completes → the provider stays in the loading state.
            ? Completer<bool>().future
            : Future.value(nfcAvailable),
      ),
    ],
    child: IrmaTheme(
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
        home: SchemalessAddDataScreen(),
      ),
    ),
  );
}

SchemalessYiviCredentialTypeCard _card(WidgetTester tester, String credId) =>
    tester.widget<SchemalessYiviCredentialTypeCard>(
      find.byWidgetPredicate(
        (w) =>
            w is SchemalessYiviCredentialTypeCard && w.credentialId == credId,
      ),
    );

void main() {
  testWidgets(
    "NFC-requiring credential is greyed out (disabled, with a11y hint) when the device has no NFC",
    (tester) async {
      await tester.pumpWidget(_testWidget(nfcAvailable: false));
      await tester.pumpAndSettle();

      final passport = _card(tester, "pbdf.pbdf.passport");
      expect(passport.disabled, isTrue);
      // The unavailable reason is conveyed to assistive tech, not by dimming
      // alone, so the disabled state has a screen-reader hint.
      expect(passport.disabledHint, isNotNull);
      expect(passport.disabledHint, isNotEmpty);

      // A credential that doesn't need NFC stays enabled on the same device.
      final email = _card(tester, "pbdf.sidn-pbdf.email");
      expect(email.disabled, isFalse);
      expect(email.disabledHint, isNull);
    },
  );

  testWidgets(
    "tapping a greyed-out NFC credential shows the NFC-unsupported dialog instead of navigating",
    (tester) async {
      await tester.pumpWidget(_testWidget(nfcAvailable: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key("irma_dialog")), findsNothing);

      await tester.tap(find.byKey(const Key("pbdf.pbdf.passport_tile")));
      await tester.pumpAndSettle();

      // The dialog opened (no navigation away from the add-data screen).
      expect(find.byKey(const Key("irma_dialog")), findsOneWidget);
      expect(find.text("NFC not supported"), findsOneWidget);
      expect(find.byType(SchemalessAddDataScreen), findsOneWidget);
    },
  );

  testWidgets(
    "NFC-requiring credential stays enabled when the device supports NFC",
    (tester) async {
      await tester.pumpWidget(_testWidget(nfcAvailable: true));
      await tester.pumpAndSettle();

      final passport = _card(tester, "pbdf.pbdf.passport");
      expect(passport.disabled, isFalse);
      expect(passport.disabledHint, isNull);
    },
  );

  testWidgets(
    "NFC-requiring credential stays enabled while the NFC check is still loading",
    (tester) async {
      await tester.pumpWidget(_testWidget(nfcAvailable: null));
      // Can't settle: the credential store resolves but the NFC future stays
      // pending on purpose. Pump enough to let the store stream emit.
      await tester.pump();
      await tester.pump();

      final passport = _card(tester, "pbdf.pbdf.passport");
      expect(passport.disabled, isFalse);
    },
  );
}
