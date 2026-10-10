import "dart:async";

import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
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
    nfcDisabled: "$key.nfc_disabled",
    nfcEnabled: "$key.nfc_enabled",
    introduction: "$key.introduction",
    startScanning: "$key.start_scanning",
    nfcDisabledExplanation: "$key.nfc_disabled_explanation",
    holdNearPhotoPage: "$key.hold_near_photo_page",
    tip1: "$key.tip_1",
    tip2: "$key.tip_2",
    tip3: "$key.tip_3",
    successExplanation: "$key.success_explanation",
    cancelledByUser: "$key.cancelled_by_user",
    cancelled: "$key.cancelled",
    cancelling: "$key.cancelling",
    connecting: "$key.connecting",
    readingCardSecurity: "$key.reading_card_security",
    readingDocumentData: "$key.reading_passport_data",
    authenticating: "$key.authenticating",
    performingSecurityVerification: "$key.performing_security_verification",
    timeoutWaitingForTag: "$key.timeout_waiting_for_tag",
    tagLostTryAgain: "$key.tag_lost_try_again",
    failedToInitiateSession: "$key.failed_initiate_session",
    success: "$key.success",
  );
}

enum _Flag { on, off }

const _androidOnly = TargetPlatformVariant({TargetPlatform.android});
const _iosOnly = TargetPlatformVariant({TargetPlatform.iOS});

void main() {
  late _ScriptedReader reader;
  late _RecordingSettingsOpener settingsOpener;
  var nfcStatus = NfcStatus.enabled;

  setUp(() {
    reader = _ScriptedReader();
    settingsOpener = _RecordingSettingsOpener();
    nfcStatus = NfcStatus.enabled;

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
    _Flag flag = .on,
    ScannedMrz? mrz,
  }) async {
    await pumpTranslated(
      tester,
      ProviderScope(
        overrides: [
          passportReaderProvider.overrideWith2((mrz) => reader),
          idCardReaderProvider.overrideWith2((mrz) => reader),
          passportIssuerProvider.overrideWithValue(_StubIssuer()),
          featureFlagProvider(
            FeatureFlag.documentFlowV2,
          ).overrideWith((ref) => Stream.value(flag == .on)),
          nfcStatusReaderProvider.overrideWithValue(() async => nfcStatus),
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

  testWidgets("flag off: the screen is the introduction with a Start button", (
    tester,
  ) async {
    await pumpScreen(tester, flag: .off);

    expect(find.byType(NfcStageScaffold), findsNothing);
    expect(find.text("Start scanning"), findsOneWidget);
    expect(reader.readCount, 0);
  }, variant: _androidOnly);

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
      expect(find.text("30%"), findsOneWidget);
      expect(cancelButton(), findsOneWidget);

      reader.emit(
        DocumentReaderReadingDataGroup(dataGroup: "DG2", progress: 0.4),
      );
      await tester.pumpAndSettle();
      expect(find.text("60%"), findsOneWidget);
    }, variant: _androidOnly);

    testWidgets("the ring announces its value to assistive technology", (
      tester,
    ) async {
      await pumpScreen(tester);

      reader.emit(DocumentReaderReadingSOD());
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(NfcProgressRing)),
        matchesSemantics(value: "80%"),
      );
    }, variant: _androidOnly);
  });

  group("done", () {
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
      tester.getTopLeft(find.byKey(const Key("nfc_stage_text"))).dy +
          IrmaTheme.of(
            tester.element(find.byType(NfcStageScaffold)),
          ).defaultSpacing,
    );

    reader.emit(DocumentReaderSuccess());
    await tester.pumpAndSettle();
    expect(rectOf(const Key("nfc_stage_picture")), picture);
    expect(rectOf(const Key("nfc_stage_text")), text);
    // Hidden, not removed: the bar still takes its place.
    expect(tester.getRect(cancelButton()), cancel);
    expect(barRect(), screen);
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
      expect(message(DocumentReaderAuthenticating()), "Don't move · 30%");
      expect(
        message(
          DocumentReaderReadingDataGroup(dataGroup: "DG2", progress: 0.4),
        ),
        "Don't move · 60%",
      );
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
