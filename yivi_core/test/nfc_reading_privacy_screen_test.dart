import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/theme/theme.dart";

final _mrz = ScannedPassportMrz(
  documentNumber: "AB1234567",
  countryCode: "NLD",
  dateOfBirth: DateTime(1990, 1, 1),
  dateOfExpiry: DateTime(2030, 12, 31),
);

/// A reader whose `readDocument` does nothing but record what the privacy
/// screen was asked to do while the (notional) iOS reader sheet was up.
class _RecordingReader extends DocumentReader<PassportData> {
  _RecordingReader(this._privacyScreenCalls)
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

  final List<String> _privacyScreenCalls;
  List<String> callsDuringRead = [];
  int readCount = 0;

  @override
  DocumentReaderState build() => DocumentReaderPending();

  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async {
    readCount += 1;
    callsDuringRead = List.of(_privacyScreenCalls);
    return null;
  }
}

class _StubIssuer implements PassportIssuer {
  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async =>
      NonceAndSessionId(
        nonce: "d4e5f6a7d4e5f6a7",
        sessionId: "4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b",
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NfcReadingTranslationKeys _translationKeys() {
  const key = "passport.nfc";
  return NfcReadingTranslationKeys(
    cancelDialogTitle: key,
    cancelDialogExplanation: key,
    cancelDialogDecline: key,
    cancelDialogConfirm: key,
    error: key,
    errorGeneric: key,
    title: key,
    nfcDisabled: key,
    nfcEnabled: key,
    introduction: key,
    startScanning: key,
    nfcDisabledExplanation: key,
    holdNearPhotoPage: key,
    tip1: key,
    tip2: key,
    tip3: key,
    successExplanation: key,
    cancelledByUser: key,
    cancelled: key,
    cancelling: key,
    connecting: key,
    readingCardSecurity: key,
    readingDocumentData: key,
    authenticating: key,
    performingSecurityVerification: key,
    timeoutWaitingForTag: key,
    tagLostTryAgain: key,
    failedToInitiateSession: key,
    success: key,
  );
}

Widget _testWidget(_RecordingReader reader) {
  return ProviderScope(
    overrides: [
      passportReaderProvider.overrideWith2((mrz) => reader),
      passportIssuerProvider.overrideWithValue(_StubIssuer()),
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
        home: NfcReadingScreen(mrz: _mrz, translationKeys: _translationKeys()),
      ),
    ),
  );
}

void main() {
  testWidgets("the NFC read runs with the privacy screen held back", (
    tester,
  ) async {
    final privacyScreenCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel("privacy_screen"), (
          call,
        ) async {
          privacyScreenCalls.add(call.method);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel("privacy_screen"),
            null,
          ),
    );

    final reader = _RecordingReader(privacyScreenCalls);
    await tester.pumpWidget(_testWidget(reader));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("bottom_bar_primary")));
    await tester.pumpAndSettle();

    expect(reader.readCount, 1);
    // The iOS reader sheet resigns the app active for the whole read; without
    // this the blur sits over the scanning animation and its progress text.
    expect(reader.callsDuringRead, ["suspendPrivacyScreen"]);
    expect(privacyScreenCalls, ["suspendPrivacyScreen", "resumePrivacyScreen"]);

    // The scanning animation loops on a Future.delayed; tear the tree down and
    // let the last delay elapse, or the test fails on a pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
