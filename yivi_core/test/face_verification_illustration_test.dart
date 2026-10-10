import "package:flutter/services.dart";
import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_i18n/loaders/file_translation_loader.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_riverpod/misc.dart" show Override;
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/extensions.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/data/feature_flags.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/feature_flag_provider.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/providers/regula_face_service_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/face_verification_animation.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/util/test_detection.dart";

import "support/pump_translated.dart";

enum _Flag { on, off }

const _phone = Key("face_verification_phone");
const _selfieCard = Key("face_verification_selfie_card");

class _FakePassportData extends Fake implements PassportData {}

/// Reader that finishes the read at once, so the flow moves on to the intro.
class _SucceedingReader extends DocumentReader<PassportData> {
  _SucceedingReader()
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

  @override
  DocumentReaderState build() => DocumentReaderPending();

  @override
  Future<void> checkNfcAvailability() async {}

  @override
  Future<void> cancel() async {}

  @override
  void reset() {}

  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) async =>
      (_FakePassportData(), RawDocumentData(dataGroups: const {}, efSod: ""));
}

/// Announces face verification, so the flow reaches the intro screen.
class _AnnouncingIssuer implements PassportIssuer {
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Liveness session that never ends: the test only looks at the intro.
class _IdleFaceService implements RegulaFaceService {
  @override
  Future<void> initialize() async {}

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) =>
      Future<RegulaLivenessResult>.delayed(const Duration(days: 1));
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

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      // TestContext stops the animations from looping on a timer.
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
            home: home,
          ),
        ),
      ),
    );

void main() {
  group("the animation", () {
    testWidgets("shows the selfie on an upright phone by default", (
      tester,
    ) async {
      await pumpTranslated(tester, _app(const FaceVerificationAnimation()));

      expect(find.byKey(_phone), findsOneWidget);
      expect(find.byKey(_selfieCard), findsNothing);
    });

    testWidgets("neutral shows the selfie on a plain card, with no phone", (
      tester,
    ) async {
      await pumpTranslated(
        tester,
        _app(
          const FaceVerificationAnimation(
            illustration: FaceVerificationIllustration.neutral,
          ),
        ),
      );

      expect(find.byKey(_selfieCard), findsOneWidget);
      expect(find.byKey(_phone), findsNothing);
    });
  });

  group("the intro after reading a document", () {
    setUp(() {
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

    Future<void> pumpUntilIntro(
      WidgetTester tester, {
      required _Flag flag,
    }) async {
      final reader = _SucceedingReader();
      await pumpTranslated(
        tester,
        _app(
          NfcReadingScreen(
            mrz: ScannedPassportMrz(
              documentNumber: "AB1234567",
              countryCode: "NLD",
              dateOfBirth: DateTime(1990, 1, 1),
              dateOfExpiry: DateTime(2030, 12, 31),
            ),
            translationKeys: _translationKeys(),
          ),
          overrides: [
            passportReaderProvider.overrideWith2((mrz) => reader),
            passportIssuerProvider.overrideWithValue(_AnnouncingIssuer()),
            regulaFaceServiceProvider.overrideWithValue(_IdleFaceService()),
            featureFlagProvider(
              FeatureFlag.documentFlowV2,
            ).overrideWith((ref) => Stream.value(flag == .on)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Flag off waits for the Start tap; on, Android starts at once and iOS
      // needs the tap too, so tap it where it is there.
      final start = find.byKey(const Key("bottom_bar_primary"));
      if (start.evaluate().isNotEmpty) await tester.tap(start);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets("flag on: the selfie is on a plain card", (tester) async {
      await pumpUntilIntro(tester, flag: .on);

      expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
      expect(find.byKey(_selfieCard), findsOneWidget);
      expect(find.byKey(_phone), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.android}));

    testWidgets("flag off: the selfie stays on the upright phone", (
      tester,
    ) async {
      await pumpUntilIntro(tester, flag: .off);

      expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
      expect(find.byKey(_phone), findsOneWidget);
      expect(find.byKey(_selfieCard), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.android}));
  });
}
