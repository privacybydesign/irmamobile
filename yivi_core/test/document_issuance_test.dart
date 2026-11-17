import "dart:async";

import "package:flutter_svg/svg.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/models/mrz.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/providers/regula_face_service_provider.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/widgets/face_frame_illustration.dart";

import "support/document_fakes.dart";
import "support/document_sheet_harness.dart";

/// An issuer that counts its calls and keeps what it was asked to issue.
class _RecordingIssuer extends AnnouncingPassportIssuer {
  _RecordingIssuer({this.announce = true, this.issueError});

  final bool announce;

  /// Thrown by the issuance call; without it the call never answers.
  final String? issueError;
  var starts = 0;
  var issues = 0;
  RawDocumentData? issued;

  @override
  Future<StartValidationResult> startSessionAtPassportIssuer() async {
    starts++;
    final result = await super.startSessionAtPassportIssuer();
    return announce
        ? result
        : StartValidationResult(nonceAndSessionId: result.nonceAndSessionId);
  }

  @override
  Future<IrmaSessionPointer> startIrmaIssuanceSession(
    RawDocumentData documentDataResult,
    DocumentType docType,
  ) {
    issues++;
    issued = documentDataResult;
    if (issueError case final message?) throw Exception(message);
    return Completer<IrmaSessionPointer>().future;
  }
}

/// A liveness session that passes and keeps the language it was given.
class _RecordingFaceService extends PassingFaceService {
  String? language;
  var captures = 0;

  @override
  Future<RegulaLivenessResult> captureLiveness({String? languageCode}) {
    captures++;
    language = languageCode;
    return super.captureLiveness(languageCode: languageCode);
  }
}

/// The error pictures showing.
Set<String> _errorPictures(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((svg) => svg.bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName)
    .where((name) => name.contains("error/"))
    .toSet();

/// On iOS the read waits for Start, so a test chooses when it begins.
const _ios = TargetPlatformVariant({TargetPlatform.iOS});
const _android = TargetPlatformVariant({TargetPlatform.android});

/// From the chip read to the issuance session, through the sheet.
void main() {
  DocumentSheetHarness.mockPrivacyScreen();
  final h = DocumentSheetHarness();

  /// Start on the chip (iOS) and let the read and the issuer answer.
  Future<void> startRead(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key("bottom_bar_primary")).last);
    await h.readChip(tester);
  }

  /// Start on the face check's intro.
  Future<void> startFace(WidgetTester tester) async {
    // Upright its button is in the sheet's bottom bar.
    await tester.tap(find.byKey(const Key("bottom_bar_primary")).last);
    await h.readChip(tester);
  }

  testWidgets("Start asks the issuer once and sets the face check's "
      "announcement from it, also to none", (tester) async {
    final issuer = _RecordingIssuer(announce: false);
    await h.pump(tester, issuer: issuer);
    h.container
        .read(faceVerificationConfigProvider.notifier)
        .set(const FaceVerificationConfig(faceApiUrl: "https://stale"));
    await h.toChipDirect(tester, testPassportMrz);
    await startRead(tester);
    expect(issuer.starts, 1);
    expect(h.container.read(faceVerificationConfigProvider), isNull);
    // No face check announced: no intro, straight to the issuer.
    expect(find.byType(FaceVerificationIntroScreen), findsNothing);
    expect(issuer.issues, 1);
    expect(issuer.issued!.livenessTransactionId, isNull);
  }, variant: _ios);

  testWidgets("a face service but no announcement: no face check", (
    tester,
  ) async {
    final issuer = _RecordingIssuer(announce: false);
    final face = _RecordingFaceService();
    await h.pump(tester, issuer: issuer, face: face);
    await h.toChipDirect(tester, testPassportMrz);
    await startRead(tester);
    expect(find.byType(FaceVerificationIntroScreen), findsNothing);
    expect(face.captures, 0);
    expect(issuer.issues, 1);
  }, variant: _ios);

  testWidgets("a face check: the intro with its still picture and one "
      "button; the transaction id and the language reach the issuer", (
    tester,
  ) async {
    final issuer = _RecordingIssuer();
    final face = _RecordingFaceService();
    await h.pump(tester, issuer: issuer, face: face);
    await h.toChipDirect(tester, testPassportMrz);
    await startRead(tester);
    expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
    expect(find.byType(FaceFrameIllustration), findsOneWidget);
    expect(issuer.issues, 0);

    await startFace(tester);
    expect(face.captures, 1);
    expect(face.language, "en");
    expect(issuer.issues, 1);
    expect(issuer.issued!.livenessTransactionId, "txn-1");
  }, variant: _ios);

  testWidgets("not now on the intro: on Android a new read starts by "
      "itself", (tester) async {
    final readers = <SucceedingPassportReader>[];
    await h.pump(
      tester,
      issuer: _RecordingIssuer(),
      face: _RecordingFaceService(),
      reader: () {
        final reader = _CountingReader();
        readers.add(reader);
        return reader;
      },
    );
    await h.toChipDirect(tester, testPassportMrz);
    await h.readChip(tester);
    expect(find.byType(FaceVerificationIntroScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel("Go back"));
    await h.readChip(tester);
    // The first reader went while the loader showed; the new one is read.
    expect(readers.map((r) => (r as _CountingReader).reads), [1, 1]);
  }, variant: _android);

  group("the issuer's error", () {
    Future<Set<String>> pictureFor(
      WidgetTester tester,
      String message, {
      bool face = true,
    }) async {
      await h.pump(
        tester,
        issuer: _RecordingIssuer(announce: face, issueError: message),
        face: PassingFaceService(),
      );
      await h.toChipDirect(tester, testPassportMrz);
      await startRead(tester);
      if (face) await startFace(tester);
      expect(find.byType(NfcReadingScreen), findsOneWidget);
      return _errorPictures(tester);
    }

    testWidgets("a 400 after a face check: the failed face", (tester) async {
      expect(await pictureFor(tester, "Store failed: 400 face mismatch"), {
        "packages/yivi_core/assets/error/failed_face_verification.svg",
      });
    }, variant: _ios);

    testWidgets("a 500 with 400 in its body: the general picture", (
      tester,
    ) async {
      expect(
        await pictureFor(
          tester,
          "Store failed: 500 internal error (request 400abc)",
        ),
        {"packages/yivi_core/assets/error/general_error_illustration.svg"},
      );
    }, variant: _ios);

    testWidgets("a 400 naming the wrong document type: the general picture", (
      tester,
    ) async {
      expect(
        await pictureFor(tester, "Store failed: 400 error:wrong-document-type"),
        {"packages/yivi_core/assets/error/general_error_illustration.svg"},
      );
    }, variant: _ios);

    testWidgets("a 400 without a face check: the general picture", (
      tester,
    ) async {
      expect(await pictureFor(tester, "Store failed: 400 bad", face: false), {
        "packages/yivi_core/assets/error/general_error_illustration.svg",
      });
    }, variant: _ios);
  });

  testWidgets("the wrong card: its texts, and nothing goes to the issuer", (
    tester,
  ) async {
    final issuer = _RecordingIssuer(announce: false);
    await h.pump(
      tester,
      type: DocumentType.residencePermit,
      issuer: issuer,
      overrides: [
        // A Dutch national's card: an ID card, not a residence permit.
        idCardReaderProvider.overrideWith2((_) => SucceedingPassportReader()),
      ],
    );
    await h.toChipDirect(
      tester,
      ScannedIdCardMrz(
        documentNumber: "AB1234567",
        countryCode: "NLD",
        dateOfBirth: DateTime(1990, 1, 1),
        dateOfExpiry: DateTime(2030, 12, 31),
        documentType: DocumentType.residencePermit,
      ),
    );
    await startRead(tester);
    expect(issuer.issues, 0);
    expect(find.text("This is an ID-card"), findsWidgets);
    expect(find.text("Try again"), findsOneWidget);
  }, variant: _ios);

  testWidgets("the issuer fails to start while the page is up: the error "
      "in the page, no route pushed", (tester) async {
    final gate = Completer<StartValidationResult>();
    await h.pump(tester, issuer: GatedPassportIssuer(gate));
    await h.toChipDirect(tester, testPassportMrz);
    final depth = h.depth;
    await startRead(tester);
    gate.completeError(Exception("issuer unreachable"));
    await h.readChip(tester);
    expect(find.byType(NfcReadingScreen), findsOneWidget);
    expect(find.text("Could not read passport. Please try again."), findsOne);
    expect(h.depth, depth);
  }, variant: _ios);

  testWidgets("the sheet closed before the face check: a later failure is "
      "dropped", (tester) async {
    final gate = Completer<StartValidationResult>();
    await h.pump(tester, issuer: GatedPassportIssuer(gate));
    await h.toChipDirect(tester, testPassportMrz);
    await startRead(tester);
    Navigator.of(h.home).pop();
    await frames(tester);
    expect(find.byType(NfcReadingScreen), findsNothing);

    gate.completeError(Exception("issuer unreachable"));
    await h.readChip(tester);
    expect(find.text("home"), findsOneWidget);
    expect(find.textContaining("issuer unreachable"), findsNothing);
  }, variant: _ios);

  testWidgets("the page torn down during the liveness session: its failure "
      "replaces the top of the app", (tester) async {
    final gate = Completer<RegulaLivenessResult>();
    await h.pump(
      tester,
      issuer: _RecordingIssuer(),
      face: GatedFaceService(gate),
    );
    await h.toChipDirect(tester, testPassportMrz);
    await startRead(tester);
    await startFace(tester);
    // Regula's native screen tears the page down on some devices; closing
    // the sheet does the same.
    Navigator.of(h.home).pop();
    await frames(tester);
    expect(find.byType(NfcReadingScreen), findsNothing);
    final depth = h.depth;

    gate.completeError(Exception("liveness session blew up"));
    await h.readChip(tester);
    expect(find.textContaining("liveness session blew up"), findsOneWidget);
    expect(h.depth, depth);
  }, variant: _ios);

  testWidgets("back from the chip ends its read", (tester) async {
    late SucceedingPassportReader reader;
    await h.pump(tester, reader: () => reader = SucceedingPassportReader());
    await h.toChip(tester);
    expect(find.byType(NfcReadingScreen), findsOneWidget);
    await tester.tap(find.bySemanticsLabel("Go back").last);
    await frames(tester);
    expect(find.byType(NfcReadingScreen), findsNothing);
    expect(reader.cancels, 1);
  }, variant: _ios);
}

class _CountingReader extends SucceedingPassportReader {
  var reads = 0;

  @override
  Future<(PassportData, RawDocumentData)?> readDocument({
    required IosNfcMessageMapper iosNfcMessages,
    NonceAndSessionId? activeAuthenticationParams,
  }) {
    reads++;
    return super.readDocument(
      iosNfcMessages: iosNfcMessages,
      activeAuthenticationParams: activeAuthenticationParams,
    );
  }
}
