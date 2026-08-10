import "dart:async";
import "dart:typed_data";

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
import "package:yivi_core/src/providers/regula_face_service_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

/// Passport issuer whose session start is held open by [gate], so a test can
/// tear the NFC screen down before the failure arrives.
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

/// Passport issuer that announces face verification, so the flow reaches the
/// intro screen and the liveness session.
class _AnnouncingPassportIssuer implements PassportIssuer {
  @override
  Future<StartValidationResult> startSessionAtPassportIssuer() async =>
      StartValidationResult(
        nonceAndSessionId: NonceAndSessionId(
          nonce: "d4e5f6a7d4e5f6a7",
          sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
        ),
        faceVerification: const FaceVerificationConfig(
          faceApiUrl: "https://face.example",
        ),
      );

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

/// Liveness service whose session is held open by [gate], standing in for the
/// native Regula UI that is in front while this screen may be torn down.
class _GatedFaceService implements RegulaFaceService {
  _GatedFaceService(this.gate);

  final Completer<RegulaLivenessResult> gate;

  @override
  Future<void> initialize() async {}

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) =>
      gate.future;
}

/// Base for the readers below: everything the screen needs except the readout
/// result, which each subclass decides.
abstract class _TestPassportReader extends DocumentReader<PassportData> {
  _TestPassportReader()
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
  Future<void> cancel() async {}

  @override
  void reset() {}
}

/// Reader that never produces a document, so the flow fails at the issuer
/// before the chip is read.
class _PendingPassportReader extends _TestPassportReader {
  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async => null;
}

/// Reader that completes the readout, so the flow continues into the intro
/// screen and the liveness session.
class _SucceedingPassportReader extends _TestPassportReader {
  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async =>
      (_fakePassportData(), RawDocumentData(dataGroups: const {}, efSod: ""));
}

class _FakeNfcProvider extends NfcProvider {}

/// A DG1 blob the real parser accepts, so no field of [PassportData] has to be
/// faked. Same fixture the app's integration helpers use.
PassportData _fakePassportData() {
  const dg1Hex =
      "615D5F1F5A503C4E4C44584938353933354638363939393939393939303C3C3C3C3C"
      "3C3732303831343846313130383236384E4C443C3C3C3C3C3C3C3C3C3C3C3856414E"
      "3C4445523C535445454E3C3C4D415249414E4E453C4C4F55495345";
  final mrz = PassportParser().parseDG1(dg1Hex.parseHex())!.mrz;
  return PassportData(
    mrz: mrz,
    photoImageData: Uint8List(0),
    photoImageType: .jpeg2000,
    photoImageWidth: 0,
    photoImageHeight: 0,
  );
}

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
/// away mid-flow and inspect the resulting stack.
Future<GoRouter> _pumpNfcScreen(
  WidgetTester tester,
  PassportIssuer issuer, {
  DocumentReader<PassportData>? reader,
  RegulaFaceService? faceService,
}) async {
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
        passportReaderProvider.overrideWith2(
          (_) => reader ?? _PendingPassportReader(),
        ),
        passportIssuerProvider.overrideWithValue(issuer),
        regulaFaceServiceProvider.overrideWithValue(faceService),
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

/// How many routes the router is currently showing. A `push` leaves the route
/// it came from on the stack; a `pushReplacement` does not.
int _stackDepth(GoRouter router) =>
    router.routerDelegate.currentConfiguration.matches.length;

/// Advances a fixed number of frames.
///
/// Once the intro screen pops, the "preparing" loader underneath is visible
/// again and its `CircularProgressIndicator` ticks forever, so `pumpAndSettle`
/// times out from that point on. (Before the pop it settles fine: an opaque
/// route on top mutes the tickers of the route it covers.)
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets("a liveness failure after the screen is gone reaches the error "
      "screen, replacing the route it came from", (tester) async {
    final gate = Completer<RegulaLivenessResult>();
    final router = await _pumpNfcScreen(
      tester,
      _AnnouncingPassportIssuer(),
      reader: _SucceedingPassportReader(),
      faceService: _GatedFaceService(gate),
    );

    // Read the document, which lands on the face verification intro.
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();
    expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);

    // Continue into the liveness session, which blocks on the gate.
    await tester.tap(
      find.descendant(
        of: find.byType(FaceVerificationIntroScreen),
        matching: find.byKey(const Key("bottom_bar_primary")),
      ),
    );
    await _pumpFrames(tester);
    expect(find.byType(FaceVerificationIntroScreen), findsNothing);

    // The native liveness UI tears this screen down on some devices; leaving
    // the route disposes its State the same way.
    router.go("/elsewhere");
    await _pumpFrames(tester);
    expect(find.byType(NfcReadingScreen), findsNothing);
    final depthBefore = _stackDepth(router);

    gate.completeError(Exception("liveness session blew up"));
    await _pumpFrames(tester);

    expect(find.textContaining("liveness session blew up"), findsOneWidget);
    // Replaced rather than stacked on top, so dismissing the error cannot
    // return the user to the readout page they already finished — the same
    // choice _startIssuance makes for this flow.
    expect(_stackDepth(router), depthBefore);
  });

  testWidgets("a failure before the liveness session is not pushed onto "
      "wherever the user went instead", (tester) async {
    final gate = Completer<StartValidationResult>();
    final router = await _pumpNfcScreen(tester, _GatedPassportIssuer(gate));

    // Start the flow; it blocks on the issuer's start-validation call, which
    // runs before any liveness UI exists.
    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    // Here the user leaves the route themselves — nothing has torn the screen
    // down for them.
    router.go("/elsewhere");
    await tester.pumpAndSettle();
    expect(find.byType(NfcReadingScreen), findsNothing);

    gate.completeError(Exception("issuer unreachable"));
    await tester.pumpAndSettle();

    // The failure belongs to a flow the user abandoned, so it stays dropped
    // instead of throwing a full-screen error over where they navigated to.
    expect(find.text("elsewhere"), findsOneWidget);
    expect(find.textContaining("issuer unreachable"), findsNothing);
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
