import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/face_verification_runner_provider.dart";
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
  Future<StartValidationResult> startSessionAtPassportIssuer({
    StartValidationRequest? request,
  }) => gate.future;

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
  Future<StartValidationResult> startSessionAtPassportIssuer({
    StartValidationRequest? request,
  }) async => StartValidationResult(
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

/// Announcing issuer whose issuance call fails with [message], so the flow
/// reaches the issuance error screen with face verification active.
class _FailingIssuanceIssuer extends _AnnouncingPassportIssuer {
  _FailingIssuanceIssuer(this.message);

  final String message;

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) async => throw Exception(message);
}

/// Liveness service that completes with a transaction id, so the flow gets past
/// the liveness step and on to issuance.
class _PassingFaceService implements RegulaFaceService {
  @override
  Future<void> initialize() async {}

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) async =>
      const RegulaLivenessResult(isLive: true, transactionId: "txn-1");
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

/// Issuer that records every session start and issuance, announces the
/// configured assignment, and fails issuance with the issuer's face rejection
/// so the flow lands on the retryable error screen.
class _RecordingIssuer implements PassportIssuer {
  _RecordingIssuer(this.announcement);

  final FaceVerificationConfig? announcement;
  final List<StartValidationRequest?> startRequests = [];
  final List<RawDocumentData> issued = [];

  @override
  Future<StartValidationResult> startSessionAtPassportIssuer({
    StartValidationRequest? request,
  }) async {
    startRequests.add(request);
    return StartValidationResult(
      nonceAndSessionId: NonceAndSessionId(
        nonce: "d4e5f6a7d4e5f6a7",
        sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
      ),
      faceVerification: announcement,
    );
  }

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) async {
    issued.add(documentDataResult);
    throw Exception("Store failed: 400 face verification failed");
  }

  @override
  Future<VerificationResponse> verifyPassport(RawDocumentData data) =>
      throw UnimplementedError();

  @override
  Future<VerificationResponse> verifyDrivingLicence(RawDocumentData data) =>
      throw UnimplementedError();
}

/// Runner standing in for either method: attaches [faceSessionId] and records
/// what the flow handed it.
class _FakeRunner implements FaceVerificationRunner {
  _FakeRunner(this.faceSessionId);

  final String faceSessionId;
  int runCount = 0;
  StartValidationResult? lastStart;
  DocumentType? lastDocumentType;

  @override
  Future<RawDocumentData> run(
    RawDocumentData data, {
    required StartValidationResult start,
    required PassportIssuer issuer,
    required DocumentType documentType,
    String? languageCode,
  }) async {
    runCount += 1;
    lastStart = start;
    lastDocumentType = documentType;
    return data.copyWith(faceSessionId: faceSessionId);
  }
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
  DocumentReaderState build() {
    // The screen stops watching the reader while the intro or the error
    // screen is in front, which would dispose it; the override hands back the
    // same instance, which riverpod refuses to re-associate. Pin it, as the
    // app's integration fakes do.
    ref.keepAlive();
    return DocumentReaderPending();
  }

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
///
/// [faceService] is injected as the Regula runner, the way the flavors do it,
/// so the flow reaches it through the same seam.
Future<GoRouter> _pumpNfcScreen(
  WidgetTester tester,
  PassportIssuer issuer, {
  DocumentReader<PassportData>? reader,
  RegulaFaceService? faceService,
  FaceVerificationRunners? runners,
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
        faceVerificationRunnersProvider.overrideWithValue(
          runners ??
              {
                if (faceService != null)
                  FaceVerificationMethod.regula: RegulaRunner(
                    (_) => faceService,
                  ),
              },
        ),
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
              ...GlobalMaterialLocalizations.delegates,
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

/// The error illustrations the tree is currently showing. Other routes carry
/// their own SVGs, so this keeps only the ones from the error asset folder.
Set<String> _errorIllustrations(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((svg) => svg.bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName)
    .where((name) => name.contains("error/"))
    .toSet();

/// Runs the face flow to the issuance error screen, with issuance failing with
/// [issuanceError], and returns the illustrations that error screen picked.
Future<Set<String>> _illustrationForIssuanceError(
  WidgetTester tester,
  String issuanceError,
) async {
  await _pumpNfcScreen(
    tester,
    _FailingIssuanceIssuer(issuanceError),
    reader: _SucceedingPassportReader(),
    faceService: _PassingFaceService(),
  );

  await tester.tap(find.byKey(const Key("bottom_bar_primary")));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(FaceVerificationIntroScreen),
      matching: find.byKey(const Key("bottom_bar_primary")),
    ),
  );
  await _pumpFrames(tester);

  return _errorIllustrations(tester);
}

void main() {
  // The read runs inside PrivacyScreen.suspendDuring. An unmocked method
  // channel replies with a null envelope, which MethodChannel turns into a
  // MissingPluginException, so without this the read fails before the flow
  // gets anywhere near a face verification or issuance error.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("privacy_screen"),
          (call) async => true,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel("privacy_screen"), null);
  });

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

  testWidgets("a rejected face match gets the failed-face illustration", (
    tester,
  ) async {
    final shown = await _illustrationForIssuanceError(
      tester,
      "Store failed: 400 face mismatch",
    );
    expect(shown, hasLength(1));
    expect(shown.single, contains("failed_face_verification.svg"));
  });

  testWidgets("another issuance failure that happens to contain 400 does not", (
    tester,
  ) async {
    // The detection keys off the issuer's `Store failed: 400`, not a bare
    // "400" anywhere in the message — an unrelated failure whose body carries
    // those digits must not be reported to the user as a face mismatch.
    final shown = await _illustrationForIssuanceError(
      tester,
      "Store failed: 500 internal error (request 400abc)",
    );
    expect(shown, hasLength(1));
    expect(shown.single, contains("general_error_illustration.svg"));
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

  group("method assignment", () {
    /// Reads the document and confirms the intro, which starts the runner.
    Future<void> runFaceStep(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await tester.pumpAndSettle();
      expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(FaceVerificationIntroScreen),
          matching: find.byKey(const Key("bottom_bar_primary")),
        ),
      );
      await _pumpFrames(tester);
    }

    testWidgets("declares the runners' methods and runs the assigned one", (
      tester,
    ) async {
      final regula = _FakeRunner("unused");
      final iris = _FakeRunner("fs_1");
      final issuer = _RecordingIssuer(
        const FaceVerificationConfig(method: FaceVerificationMethod.iris),
      );
      await _pumpNfcScreen(
        tester,
        issuer,
        reader: _SucceedingPassportReader(),
        runners: {
          FaceVerificationMethod.regula: regula,
          FaceVerificationMethod.iris: iris,
        },
      );

      await runFaceStep(tester);

      // The declaration is the runner map's keys, nothing more: no preference,
      // no retry fields on a first attempt.
      final request = issuer.startRequests.single!;
      expect(request.capabilities, [
        FaceVerificationMethod.regula,
        FaceVerificationMethod.iris,
      ]);
      expect(request.previousMethod, isNull);
      expect(request.attempt, isNull);
      expect(request.preferredMethod, isNull);

      // The issuer assigned Iris, so only the Iris runner ran, with the
      // session it can open its face session from.
      expect(iris.runCount, 1);
      expect(regula.runCount, 0);
      expect(
        iris.lastStart?.faceVerification?.method,
        FaceVerificationMethod.iris,
      );
      expect(iris.lastDocumentType, DocumentType.passport);

      // Issuance carries the runner's evidence plus the flow's own attempt
      // and duration fields.
      final issued = issuer.issued.single;
      expect(issued.faceSessionId, "fs_1");
      expect(issued.faceAttempt, 1);
      expect(issued.faceDurationMs, isNotNull);
    });

    testWidgets("a retry within the flow reports the previous method and the "
        "attempt number", (tester) async {
      final regula = _FakeRunner("fs_regula");
      final issuer = _RecordingIssuer(
        const FaceVerificationConfig(faceApiUrl: "https://face.example"),
      );
      await _pumpNfcScreen(
        tester,
        issuer,
        reader: _SucceedingPassportReader(),
        runners: {FaceVerificationMethod.regula: regula},
      );

      await runFaceStep(tester);
      // The issuer rejected the face verification: the error screen offers a
      // retry, which starts a new session in the same document flow.
      expect(find.byKey(const Key("bottom_bar_primary")), findsOneWidget);
      await runFaceStep(tester);

      expect(issuer.startRequests, hasLength(2));
      expect(
        issuer.startRequests[1]!.previousMethod,
        FaceVerificationMethod.regula,
      );
      expect(issuer.startRequests[1]!.attempt, 2);
      expect(issuer.issued, hasLength(2));
      expect(issuer.issued[0].faceAttempt, 1);
      expect(issuer.issued[1].faceAttempt, 2);
      expect(regula.runCount, 2);
    });

    testWidgets("an assignment this build cannot run stays on the error "
        "screen without reading the chip", (tester) async {
      final regula = _FakeRunner("unused");
      final issuer = _RecordingIssuer(
        const FaceVerificationConfig(method: FaceVerificationMethod.iris),
      );
      await _pumpNfcScreen(
        tester,
        issuer,
        reader: _SucceedingPassportReader(),
        runners: {FaceVerificationMethod.regula: regula},
      );

      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await tester.pumpAndSettle();

      expect(issuer.startRequests.single!.capabilities, [
        FaceVerificationMethod.regula,
      ]);
      expect(find.byType(FaceVerificationIntroScreen), findsNothing);
      expect(regula.runCount, 0);
      expect(issuer.issued, isEmpty);
      // In-screen error with retry, like any other failure while the screen
      // is up.
      expect(find.byType(NfcReadingScreen), findsOneWidget);
      expect(
        find.text("Could not read passport. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets("no announcement skips the step and declares capabilities "
        "anyway", (tester) async {
      final regula = _FakeRunner("unused");
      final issuer = _RecordingIssuer(null);
      await _pumpNfcScreen(
        tester,
        issuer,
        reader: _SucceedingPassportReader(),
        runners: {FaceVerificationMethod.regula: regula},
      );

      await tester.tap(find.byKey(const Key("bottom_bar_primary")));
      await tester.pumpAndSettle();

      expect(issuer.startRequests.single!.capabilities, [
        FaceVerificationMethod.regula,
      ]);
      expect(find.byType(FaceVerificationIntroScreen), findsNothing);
      expect(regula.runCount, 0);
      final issued = issuer.issued.single;
      expect(issued.faceSessionId, isNull);
      expect(issued.faceAttempt, isNull);
      expect(issued.faceDurationMs, isNull);
    });
  });
}
