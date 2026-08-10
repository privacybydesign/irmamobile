import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

/// Passport issuer whose session start is held open by [gate], so a test can
/// tear the NFC screen down before the failure arrives — what the liveness UI
/// does on the devices this guards against.
class _GatedPassportIssuer implements PassportIssuer {
  _GatedPassportIssuer(this.gate);

  final Completer<StartValidationResult> gate;

  @override
  Future<StartValidationResult> startSessionAtPassportIssuer() => gate.future;

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) => throw UnimplementedError();

  @override
  Future<VerificationResponse> verifyPassport(RawDocumentData data) =>
      throw UnimplementedError();

  @override
  Future<VerificationResponse> verifyDrivingLicence(RawDocumentData data) =>
      throw UnimplementedError();
}

/// Document reader that only ever reports "pending", which is enough to render
/// the introduction screen with its start button. The flow under test fails at
/// the issuer before the chip is read.
class _PendingPassportReader extends DocumentReader<PassportData> {
  _PendingPassportReader()
    : super(
        nfc: _FakeNfcProvider(),
        documentParser: PassportParser(),
        config: DocumentReaderConfig(readIfAvailable: {DataGroups.dg1}),
        dataGroupReader: DataGroupReader(
          _FakeNfcProvider(),
          "".parseHex(),
          paceAccessKey: DBAKey("", DateTime.now(), DateTime.now()),
          bacAccessKey: DBAKey("", DateTime.now(), DateTime.now()),
        ),
      );

  @override
  DocumentReaderState build() => DocumentReaderPending();

  @override
  Future<void> checkNfcAvailability() async {}

  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async => null;

  @override
  Future<void> cancel() async {}

  @override
  void reset() {}
}

class _FakeNfcProvider extends NfcProvider {}

final _mrz = ScannedPassportMrz(
  documentNumber: "AB1234567",
  countryCode: "NLD",
  dateOfBirth: DateTime(1990, 1, 1),
  dateOfExpiry: DateTime(2030, 12, 31),
);

NfcReadingTranslationKeys _passportKeys() => NfcReadingTranslationKeys(
  cancelDialogTitle: "passport.nfc.cancel_dialog.title",
  cancelDialogExplanation: "passport.nfc.cancel_dialog.explanation",
  cancelDialogDecline: "passport.nfc.cancel_dialog.decline",
  cancelDialogConfirm: "passport.nfc.cancel_dialog.confirm",
  error: "passport.nfc.error",
  errorGeneric: "passport.nfc.error_generic",
  title: "passport.nfc.title",
  nfcDisabled: "passport.nfc.nfc_disabled",
  nfcEnabled: "passport.nfc.nfc_enabled",
  introduction: "passport.nfc.introduction",
  startScanning: "passport.nfc.start_scanning",
  nfcDisabledExplanation: "passport.nfc.nfc_disabled_explanation",
  holdNearPhotoPage: "passport.nfc.hold_near_photo_page",
  tip1: "passport.nfc.tip_1",
  tip2: "passport.nfc.tip_2",
  tip3: "passport.nfc.tip_3",
  successExplanation: "passport.nfc.success_explanation",
  cancelledByUser: "passport.nfc.cancelled_by_user",
  cancelled: "passport.nfc.cancelled",
  cancelling: "passport.nfc.cancelling",
  connecting: "passport.nfc.connecting",
  readingCardSecurity: "passport.nfc.reading_card_security",
  readingDocumentData: "passport.nfc.reading_passport_data",
  authenticating: "passport.nfc.authenticating",
  performingSecurityVerification:
      "passport.nfc.performing_security_verification",
  timeoutWaitingForTag: "passport.nfc.timeout_waiting_for_tag",
  tagLostTryAgain: "passport.nfc.tag_lost_try_again",
  failedToInitiateSession: "passport.nfc.failed_to_initiate_session",
  success: "passport.nfc.success",
);

/// Pumps the NFC reading screen on a router that also owns the `/error` route
/// the screen falls back to, and returns that router so a test can navigate
/// away mid-flow.
Future<GoRouter> _pumpNfcScreen(
  WidgetTester tester,
  PassportIssuer issuer,
) async {
  final router = GoRouter(
    initialLocation: "/nfc",
    routes: [
      GoRoute(
        path: "/nfc",
        builder: (_, _) =>
            NfcReadingScreen(mrz: _mrz, translationKeys: _passportKeys()),
      ),
      GoRoute(
        path: "/elsewhere",
        builder: (_, _) => const Scaffold(body: Text("elsewhere")),
      ),
      GoRoute(
        path: "/error",
        builder: (_, state) => Scaffold(body: Text("error: ${state.extra}")),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        passportReaderProvider.overrideWith2((_) => _PendingPassportReader()),
        passportIssuerProvider.overrideWithValue(issuer),
      ],
      // TestContext disables the scanning animation's repeating ticker so
      // pumpAndSettle does not hang.
      child: TestContext(
        child: IrmaTheme(
          builder: (_) => MaterialApp.router(
            routerConfig: router,
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
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets("a failure after the screen is gone lands on the error screen", (
    tester,
  ) async {
    final gate = Completer<StartValidationResult>();
    final router = await _pumpNfcScreen(tester, _GatedPassportIssuer(gate));

    // Start the flow; it blocks on the issuer's start-validation call.
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    // The liveness UI tears this screen down on some devices; navigating away
    // disposes its State the same way.
    router.go("/elsewhere");
    await tester.pumpAndSettle();
    expect(find.byType(NfcReadingScreen), findsNothing);

    gate.completeError(Exception("liveness session blew up"));
    await tester.pumpAndSettle();

    expect(find.textContaining("liveness session blew up"), findsOneWidget);
  });

  testWidgets("a failure while the screen is up stays in the screen", (
    tester,
  ) async {
    final gate = Completer<StartValidationResult>();
    await _pumpNfcScreen(tester, _GatedPassportIssuer(gate));

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    gate.completeError(Exception("issuer unreachable"));
    await tester.pumpAndSettle();

    // The in-screen error (with retry/cancel) is used while the screen is
    // still there, so no error route is pushed on top of it.
    expect(find.byType(NfcReadingScreen), findsOneWidget);
    expect(find.textContaining("error: "), findsNothing);
    expect(
      find.text("Could not read passport. Please try again."),
      findsOneWidget,
    );
  });
}
