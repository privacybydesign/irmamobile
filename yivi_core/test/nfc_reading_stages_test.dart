import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/nfc_availability_provider.dart";
import "package:yivi_core/src/providers/nfc_settings_provider.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/nfc_stage_view.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/nfc_settings.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "support/pump_translated.dart";

final _mrz = ScannedPassportMrz(
  documentNumber: "AB1234567",
  countryCode: "NLD",
  dateOfBirth: DateTime(1990, 1, 1),
  dateOfExpiry: DateTime(2030, 12, 31),
);

final _idCardMrz = ScannedIdCardMrz(
  documentNumber: "AB1234567",
  countryCode: "NLD",
  dateOfBirth: DateTime(1990, 1, 1),
  dateOfExpiry: DateTime(2030, 12, 31),
);

/// A reader whose state the test drives, and whose read never finishes.
class _ScriptedReader extends DocumentReader<PassportData> {
  _ScriptedReader()
    : super(
        nfc: NfcProvider(),
        documentParser: PassportParser(),
        config: DocumentReaderConfig(readIfAvailable: {DataGroups.dg1}),
        dataGroupReader: DataGroupReader(
          NfcProvider(),
          "".parseHex(),
          paceAccessKey: DBAKey("", DateTime(1990), DateTime(2030)),
        ),
      );

  int readCount = 0;
  IosNfcMessageMapper? iosMessages;

  void emit(DocumentReaderState next) => state = next;

  @override
  DocumentReaderState build() => DocumentReaderPending();

  @override
  Future<void> checkNfcAvailability() async {}

  @override
  Future<void> cancel() async {}

  @override
  void reset() => state = DocumentReaderPending();

  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) {
    readCount += 1;
    iosMessages = iosNfcMessages;
    return Completer<(PassportData, RawDocumentData)?>().future;
  }
}

/// A reader that reads the passport as soon as it is started.
class _SucceedingReader extends _ScriptedReader {
  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async {
    readCount += 1;
    state = DocumentReaderSuccess();
    return (_passportData(), RawDocumentData(dataGroups: const {}, efSod: ""));
  }
}

/// A DG1 blob the real parser accepts, the fixture the integration helpers use.
PassportData _passportData() {
  const dg1Hex =
      "615D5F1F5A503C4E4C44584938353933354638363939393939393939303C3C3C3C3C"
      "3C3732303831343846313130383236384E4C443C3C3C3C3C3C3C3C3C3C3C3856414E"
      "3C4445523C535445454E3C3C4D415249414E4E453C4C4F55495345";
  return PassportData(
    mrz: PassportParser().parseDG1(dg1Hex.parseHex())!.mrz,
    photoImageData: Uint8List(0),
    photoImageType: .jpeg2000,
    photoImageWidth: 0,
    photoImageHeight: 0,
  );
}

class _StubIssuer implements PassportIssuer {
  @override
  Future<StartValidationResult> startSessionAtPassportIssuer() async =>
      StartValidationResult(
        nonceAndSessionId: NonceAndSessionId(
          nonce: "d4e5f6a7d4e5f6a7",
          sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Counts the issuance sessions it is asked to start. Each then fails, which
/// ends the flow on the screen's error state.
class _RecordingIssuer extends _StubIssuer {
  int issuances = 0;

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) async {
    issuances += 1;
    throw Exception("issuance stops here in this test");
  }
}

class _RecordingSettingsOpener implements NfcSettingsOpener {
  int opened = 0;

  @override
  Future<void> open() async => opened += 1;
}

NfcReadingTranslationKeys _translationKeys() {
  const key = "passport.nfc";
  return NfcReadingTranslationKeys(
    cancelDialogTitle: "$key.cancel_dialog.title",
    cancelDialogExplanation: "$key.cancel_dialog.explanation",
    cancelDialogDecline: "$key.cancel_dialog.decline",
    cancelDialogConfirm: "$key.cancel_dialog.confirm",
    error: "$key.error",
    errorGeneric: "$key.error_generic",
    title: "$key.title",
    cancelledByUser: "$key.cancelled_by_user",
    cancelled: "$key.cancelled",
    cancelling: "$key.cancelling",
    timeoutWaitingForTag: "$key.timeout_waiting_for_tag",
    tagLostTryAgain: "$key.tag_lost_try_again",
    failedToInitiateSession: "$key.failed_initiate_session",
  );
}

const _androidOnly = TargetPlatformVariant({TargetPlatform.android});
const _iosOnly = TargetPlatformVariant({TargetPlatform.iOS});

void main() {
  late _ScriptedReader reader;
  late _RecordingSettingsOpener settingsOpener;
  var nfcStatus = NfcStatus.enabled;
  Object? nfcStatusError;

  setUp(() {
    reader = _ScriptedReader();
    settingsOpener = _RecordingSettingsOpener();
    nfcStatus = NfcStatus.enabled;
    nfcStatusError = null;

    // The read runs inside PrivacyScreen.suspendDuring.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("privacy_screen"),
          (call) async => true,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel("privacy_screen"),
            null,
          ),
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ScannedMrz? mrz,
    PassportIssuer? issuer,
    Size surface = const Size(390, 844),
  }) async {
    tester.view
      ..physicalSize = surface
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: [
          passportReaderProvider.overrideWith2((mrz) => reader),
          idCardReaderProvider.overrideWith2((mrz) => reader),
          passportIssuerProvider.overrideWithValue(issuer ?? _StubIssuer()),
          nfcStatusReaderProvider.overrideWithValue(() async {
            final error = nfcStatusError;
            if (error != null) throw error;
            return nfcStatus;
          }),
          nfcSettingsOpenerProvider.overrideWithValue(settingsOpener),
        ],
        // TestContext stops the scanning animation from looping on a timer.
        child: TestContext(
          child: IrmaTheme(
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
              home: NfcReadingScreen(
                mrz: mrz ?? _mrz,
                translationKeys: _translationKeys(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder primaryButton() => find.byKey(const Key("bottom_bar_primary"));
  Finder cancelButton() => find.byKey(const Key("bottom_bar_secondary"));

  group("before contact", () {
    testWidgets("Android starts listening at once and offers Cancel only", (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(reader.readCount, 1);
      expect(find.text("Place your phone on your passport"), findsOneWidget);
      expect(find.text("Your passport can stay closed."), findsOneWidget);
      expect(primaryButton(), findsNothing);
      expect(cancelButton(), findsOneWidget);
    }, variant: _androidOnly);

    testWidgets("iOS waits for one tap on Start, which opens the NFC sheet", (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(reader.readCount, 0);
      expect(find.text("Place your phone on your passport"), findsOneWidget);
      expect(find.text("Start"), findsOneWidget);
      expect(cancelButton(), findsNothing);

      await tester.tap(primaryButton());
      await tester.pumpAndSettle();
      expect(reader.readCount, 1);

      // The sheet is up: nothing left to start, so the button is Cancel.
      reader.emit(DocumentReaderConnecting());
      await tester.pumpAndSettle();
      expect(primaryButton(), findsNothing);
      expect(cancelButton(), findsOneWidget);
    }, variant: _iosOnly);

    testWidgets("the passport's picture says what it shows", (tester) async {
      await pumpScreen(tester);

      expect(
        find.bySemanticsLabel(
          "Animation: place the back of your phone on your closed passport",
        ),
        findsOneWidget,
      );
    }, variant: _androidOnly);

    testWidgets("a card's picture is left out of the semantics", (
      tester,
    ) async {
      await pumpScreen(tester, mrz: _idCardMrz);

      expect(find.bySemanticsLabel(RegExp("closed passport")), findsNothing);
    }, variant: _androidOnly);

    testWidgets("a card says to hold the phone against it, not that it can "
        "stay closed", (tester) async {
      await pumpScreen(tester, mrz: _idCardMrz);

      expect(find.text("Place your phone on your ID-card"), findsOneWidget);
      expect(
        find.text("Hold the back of your phone against the card."),
        findsOneWidget,
      );
      expect(find.text("Your passport can stay closed."), findsNothing);
    }, variant: _androidOnly);

    testWidgets("waiting for the tag is still before contact", (tester) async {
      await pumpScreen(tester);

      reader.emit(DocumentReaderConnecting());
      await tester.pumpAndSettle();

      expect(find.text("Place your phone on your passport"), findsOneWidget);
    }, variant: _androidOnly);
  });

  group("connected", () {
    testWidgets("shows a progress ring with a percentage", (tester) async {
      await pumpScreen(tester);

      reader.emit(DocumentReaderAuthenticating());
      await tester.pumpAndSettle();

      expect(find.text("Don't move"), findsOneWidget);
      expect(find.text("Your passport is being read."), findsOneWidget);
      expect(find.byType(NfcProgressRing), findsOneWidget);
      expect(find.text(_percent(DocumentReaderAuthenticating())), findsOne);
      expect(cancelButton(), findsOneWidget);

      // Within a data group the ring follows the bytes read.
      final reading = DocumentReaderReadingDataGroup(
        dataGroup: "DG2",
        progress: 0.4,
      );
      reader.emit(reading);
      await tester.pumpAndSettle();
      expect(find.text(_percent(reading)), findsOneWidget);
      final further = DocumentReaderReadingDataGroup(
        dataGroup: "DG2",
        progress: 0.8,
      );
      reader.emit(further);
      await tester.pumpAndSettle();
      expect(find.text(_percent(further)), findsOneWidget);
      expect(_percent(further), isNot(_percent(reading)));
    }, variant: _androidOnly);

    testWidgets("the ring announces its value to assistive technology", (
      tester,
    ) async {
      await pumpScreen(tester);

      reader.emit(DocumentReaderReadingSOD());
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(NfcProgressRing)),
        matchesSemantics(
          label: "Reading passport",
          value: _percent(DocumentReaderReadingSOD()),
        ),
      );
    }, variant: _androidOnly);
  });

  group("done", () {
    testWidgets("the check stays up until it has drawn, then the flow moves "
        "on", (tester) async {
      final issuer = _RecordingIssuer();
      reader = _SucceedingReader();
      await pumpScreen(tester, issuer: issuer);

      await tester.tap(primaryButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(NfcDoneCheck), findsOneWidget);
      expect(issuer.issuances, 0);

      await tester.pump(NfcDoneCheck.holdDuration);
      await tester.pump();

      expect(issuer.issuances, 1);
    }, variant: _iosOnly);

    testWidgets("the ring becomes a check, with no button left", (
      tester,
    ) async {
      await pumpScreen(tester);

      reader.emit(DocumentReaderSuccess());
      await tester.pumpAndSettle();

      expect(find.text("Your passport has been read"), findsOneWidget);
      expect(find.text("You can pick up your phone again."), findsOneWidget);
      expect(find.byType(NfcDoneCheck), findsOneWidget);
      expect(find.byType(NfcProgressRing), findsNothing);
      expect(cancelButton().hitTestable(), findsNothing);
    }, variant: _androidOnly);
  });

  testWidgets("the picture, the text and the bar stay where they are in every "
      "state", (tester) async {
    await pumpScreen(tester);

    Rect rectOf(Key key) => tester.getRect(find.byKey(key));
    Rect barRect() => tester.getRect(find.byType(NfcStageScaffold));
    Offset titlePosition(String text) => tester.getTopLeft(find.text(text));

    final picture = rectOf(const Key("nfc_stage_picture"));
    final text = rectOf(const Key("nfc_stage_text"));
    final screen = barRect();
    // The Cancel button's place in the bar, for the states that have one.
    final cancel = tester.getRect(cancelButton());

    reader.emit(DocumentReaderAuthenticating());
    await tester.pumpAndSettle();
    expect(rectOf(const Key("nfc_stage_picture")), picture);
    expect(rectOf(const Key("nfc_stage_text")), text);
    expect(tester.getRect(cancelButton()), cancel);
    expect(
      titlePosition("Don't move").dy,
      tester.getTopLeft(find.byKey(const Key("nfc_stage_text"))).dy,
    );

    reader.emit(DocumentReaderSuccess());
    await tester.pumpAndSettle();
    expect(rectOf(const Key("nfc_stage_picture")), picture);
    expect(rectOf(const Key("nfc_stage_text")), text);
    // Hidden, not removed: the bar still takes its place.
    expect(tester.getRect(cancelButton()), cancel);
    expect(barRect(), screen);
  }, variant: _androidOnly);

  testWidgets("in landscape the text and the picture sit side by side", (
    tester,
  ) async {
    await pumpScreen(tester, surface: const Size(844, 390));

    final picture = tester.getRect(find.byKey(const Key("nfc_stage_picture")));
    final text = tester.getRect(find.byKey(const Key("nfc_stage_text")));
    expect(text.right, lessThanOrEqualTo(picture.left));
    expect(find.text("Place your phone on your passport"), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: _androidOnly);

  group("NFC off", () {
    testWidgets("Android offers the NFC settings and Cancel", (tester) async {
      await pumpScreen(tester);

      reader.emit(DocumentReaderNfcUnavailable());
      await tester.pumpAndSettle();

      expect(find.text("Turn on NFC"), findsOneWidget);
      expect(
        find.text("Your phone uses it to read the chip in your passport."),
        findsOneWidget,
      );
      expect(find.text("Open NFC settings"), findsOneWidget);
      expect(cancelButton(), findsOneWidget);

      await tester.tap(primaryButton());
      await tester.pumpAndSettle();
      expect(settingsOpener.opened, 1);
    }, variant: _androidOnly);

    testWidgets("returning from the settings with NFC on carries on", (
      tester,
    ) async {
      await pumpScreen(tester);
      reader.emit(DocumentReaderNfcUnavailable());
      await tester.pumpAndSettle();
      final readsBefore = reader.readCount;

      nfcStatus = NfcStatus.enabled;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      // The read starts after the issuer call and a privacy screen call, which
      // finish on the real event loop.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(find.text("Turn on NFC"), findsNothing);
      expect(find.text("Place your phone on your passport"), findsOneWidget);
      expect(reader.readCount, readsBefore + 1);
    }, variant: _androidOnly);

    testWidgets("returning from the settings with NFC still off stays", (
      tester,
    ) async {
      await pumpScreen(tester);
      reader.emit(DocumentReaderNfcUnavailable());
      await tester.pumpAndSettle();

      nfcStatus = NfcStatus.disabled;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text("Turn on NFC"), findsOneWidget);
    }, variant: _androidOnly);

    testWidgets("returning from the settings with a failing status check "
        "stays", (tester) async {
      await pumpScreen(tester);
      reader.emit(DocumentReaderNfcUnavailable());
      await tester.pumpAndSettle();

      nfcStatusError = StateError("no NFC status");
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text("Turn on NFC"), findsOneWidget);
    }, variant: _androidOnly);
  });

  group("the message on the iOS NFC sheet", () {
    testWidgets("follows the stage, with the percentage while reading", (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(primaryButton());
      await tester.pumpAndSettle();
      final message = reader.iosMessages!;

      expect(
        message(DocumentReaderConnecting()),
        "Place your phone on your passport",
      );
      final authenticating = DocumentReaderAuthenticating();
      expect(
        message(authenticating),
        "Don't move · ${_percent(authenticating)}",
      );
      final reading = DocumentReaderReadingDataGroup(
        dataGroup: "DG2",
        progress: 0.4,
      );
      expect(message(reading), "Don't move · ${_percent(reading)}");
      expect(message(DocumentReaderSuccess()), "Your passport has been read");
    }, variant: _iosOnly);
  });

  testWidgets("a failed read keeps the existing error layout", (tester) async {
    await pumpScreen(tester);

    reader.emit(
      DocumentReaderFailed(
        error: DocumentReadingError.unknown,
        logs: "log",
        sensitiveLogs: "sensitive log",
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NfcStageScaffold), findsNothing);
    expect(primaryButton(), findsOneWidget);
    expect(cancelButton(), findsOneWidget);
  }, variant: _androidOnly);
}

/// The percentage the screen shows for [state], as vcmrtd weighs it.
String _percent(DocumentReaderState state) =>
    "${(progressForState(state) * 100).round()}%";
