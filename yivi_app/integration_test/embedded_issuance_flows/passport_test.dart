import "dart:async";

import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/screens/add_data/schemaless_add_data_details_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/face_verification_intro_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/mrz_reader_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/nfc_reading_screen.dart";
import "package:yivi_core/src/widgets/irma_app_bar.dart";

import "../helpers/document_reading_helpers.dart";
import "../irma_binding.dart";
import "../util.dart";

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // this line makes sure the text entering works on Firebase iOS on-device integration tests
  binding.testTextInput.register();

  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group("passport", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("adding passport credential opens MRZ scanner screen", (
      tester,
    ) async {
      await openPassportDetailsScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      await tester.waitFor(find.byType(MrzReaderScreen<PassportMrzParser>));
      // move back to close the camera feed...
      await tester.tapAndSettle(find.byType(YiviBackButton));
    });

    testWidgets("scanning MRZ for Dutch passport starts NFC reading flow", (
      tester,
    ) async {
      final fakeReader = FakePassportReader(
        mrzResult: fakePassportMrz,
        statesDuringRead: [
          DocumentReaderConnecting(),
          DocumentReaderReadingCardAccess(),
          DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
          DocumentReaderActiveAuthentication(),
          DocumentReaderSuccess(),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await openPassportDetailsScreen(
        tester,
        irmaBinding,
        overrides: [
          passportReaderProvider.overrideWith2((mrz) {
            fakeReader.setMrz(mrz);
            return fakeReader;
          }),
          passportIssuerProvider.overrideWithValue(fakeIssuer),
        ],
      );

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(MrzReaderScreen<PassportMrzParser>));

      final fakeMrz = PassportMrzResult(
        documentNumber: "XR0000001",
        birthDate: DateTime(1990, 1, 1),
        expiryDate: DateTime(2030, 12, 31),
        countryCode: "NLD",
        documentType: "P",
        surnames: "",
        givenNames: "",
        nationalityCountryCode: "",
        sex: .male,
        personalNumber: "",
      );

      final scannerState = tester.state<MrzReaderScreenState>(
        find.byType(MrzReaderScreen<PassportMrzParser>),
      );
      scannerState.widget.onSuccess(fakeMrz);

      await tester.pumpAndSettle();

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tapAndSettle(startScanningButton);

      expect(fakeReader.readCallCount, greaterThanOrEqualTo(1));
      expect(fakeReader.lastDocumentNumber, fakeMrz.documentNumber);
      expect(fakeReader.lastBirthDate, fakeMrz.birthDate);
      expect(fakeReader.lastExpiryDate, fakeMrz.expiryDate);
      expect(fakeReader.lastCountryCode, fakeMrz.countryCode);
    });

    testWidgets("user can cancel MRZ scanning and return to add data details", (
      tester,
    ) async {
      await openPassportDetailsScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(MrzReaderScreen<PassportMrzParser>));

      final cancelButton = find.byKey(const Key("bottom_bar_secondary"));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.byType(SchemalessAddDataDetailsScreen));
    });

    testWidgets("nfc failure after MRZ scan shows retry option", (
      tester,
    ) async {
      final fakeReader = FakePassportReader(
        mrzResult: fakePassportMrz,
        statesDuringRead: [
          DocumentReaderConnecting(),
          DocumentReaderFailed(
            error: .timeoutWaitingForTag,
            logs: "",
            sensitiveLogs: "",
          ),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await openPassportDetailsScreen(
        tester,
        irmaBinding,
        overrides: [
          passportReaderProvider.overrideWith2((mrz) {
            fakeReader.setMrz(mrz);
            return fakeReader;
          }),
          passportIssuerProvider.overrideWithValue(fakeIssuer),
        ],
      );

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(MrzReaderScreen<PassportMrzParser>));

      final fakeMrz = PassportMrzResult(
        documentNumber: "XR0000001",
        birthDate: DateTime(1990, 1, 1),
        expiryDate: DateTime(2030, 12, 31),
        countryCode: "NLD",
        documentType: "P",
        surnames: "",
        givenNames: "",
        nationalityCountryCode: "",
        sex: .male,
        personalNumber: "",
      );

      final scannerState = tester.state<MrzReaderScreenState>(
        find.byType(MrzReaderScreen<PassportMrzParser>),
      );
      scannerState.widget.onSuccess(fakeMrz);

      await tester.pumpAndSettle();

      // Start scanning
      await tester.waitFor(find.byType(NfcReadingScreen));
      await tester.tapAndSettle(find.text("Start scanning"));

      await tester.waitFor(
        find.text("Could not read passport. Please try again."),
      );
      await tester.waitFor(find.text("Timeout while waiting for passport tag"));

      expect(fakeReader.readCallCount, 1);

      final retryButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tapAndSettle(retryButton);

      await tester.pumpAndSettle();

      expect(fakeReader.cancelCount, 1);
      expect(fakeReader.readCallCount, 2);
    });

    testWidgets("manual entry continues to NFC flow when NFC is enabled", (
      tester,
    ) async {
      final readCompleter = Completer();
      final fakeReader = FakePassportReader(
        mrzResult: fakePassportMrz,
        readDelayCompleter: readCompleter,
        statesDuringRead: [
          DocumentReaderConnecting(),
          DocumentReaderReadingCardAccess(),
          DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
          DocumentReaderActiveAuthentication(),
          DocumentReaderSuccess(),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToPassportNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tap(startScanningButton);
      // The read runs behind a privacy-screen suspension, so it takes a
      // platform-channel round trip to get going — more than the microtasks
      // the tap itself drains.
      await tester.pumpUntil(() => fakeReader.readCalled);

      expect(fakeIssuer.startSessionCount, 1);
      expect(fakeReader.readCalled, isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Success"), findsOneWidget);
      expect(
        find.text("Passport reading completed successfully"),
        findsOneWidget,
      );

      readCompleter.complete();
    });

    testWidgets(
      "face verification attaches the liveness transaction id to the issuance request",
      (tester) async {
        final fakeReader = FakePassportReader(
          mrzResult: fakePassportMrz,
          statesDuringRead: [
            DocumentReaderConnecting(),
            DocumentReaderReadingCardAccess(),
            DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
            DocumentReaderActiveAuthentication(),
            DocumentReaderSuccess(),
          ],
        );
        final fakeIssuer = FakePassportIssuer();
        final fakeFace = FakeRegulaFaceService(transactionId: "txn-passport-1");

        await navigateToPassportNfcReadingScreen(
          tester,
          irmaBinding,
          fakeReader,
          fakeIssuer,
          regulaFaceService: fakeFace,
        );

        await tester.waitFor(find.byType(NfcReadingScreen));
        // "Start scanning" on the NFC screen; the readout then succeeds.
        await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

        // The Yivi face-verification intro appears after the successful readout.
        await tester.waitFor(find.byType(FaceVerificationIntroScreen));
        // Its "Start" button launches the (fake) liveness session.
        await tester.tapAndSettle(
          find.descendant(
            of: find.byType(FaceVerificationIntroScreen),
            matching: find.byKey(const Key("bottom_bar_primary")),
          ),
        );
        // The readout and the issuance call sit behind platform-channel round
        // trips that schedule no frames, so pumpAndSettle can return before the
        // issuer has been reached.
        await tester.pumpUntil(() => fakeIssuer.lastIssuedData != null);

        // Liveness must have run and its transaction id must reach the issuer,
        // and the active language must have been forwarded to the SDK.
        expect(fakeFace.captureCount, 1);
        expect(fakeFace.lastLanguageCode, isNotNull);
        expect(fakeIssuer.lastIssuedData, isNotNull);
        expect(
          fakeIssuer.lastIssuedData!.livenessTransactionId,
          "txn-passport-1",
        );
      },
    );

    testWidgets(
      "face verification is skipped when the build has no face service",
      (tester) async {
        final fakeReader = FakePassportReader(
          mrzResult: fakePassportMrz,
          statesDuringRead: [
            DocumentReaderConnecting(),
            DocumentReaderReadingCardAccess(),
            DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
            DocumentReaderActiveAuthentication(),
            DocumentReaderSuccess(),
          ],
        );
        final fakeIssuer = FakePassportIssuer();

        // The issuer does announce face verification here; what is missing is a
        // liveness service, as in the FOSS build. No regulaFaceService override
        // => regulaFaceServiceProvider keeps its null default.
        await navigateToPassportNfcReadingScreen(
          tester,
          irmaBinding,
          fakeReader,
          fakeIssuer,
        );

        await tester.waitFor(find.byType(NfcReadingScreen));
        await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
        // Reaching the issuer at all proves the step was skipped: an intro
        // screen would sit there waiting for a tap that never comes.
        await tester.pumpUntil(() => fakeIssuer.lastIssuedData != null);

        // Straight to issuance: no intro screen, and no transaction id on the
        // issuance request.
        expect(find.byType(FaceVerificationIntroScreen), findsNothing);
        expect(fakeIssuer.lastIssuedData, isNotNull);
        expect(fakeIssuer.lastIssuedData!.livenessTransactionId, isNull);
      },
    );

    testWidgets(
      "face verification is skipped when the issuer does not announce it",
      (tester) async {
        final fakeReader = FakePassportReader(
          mrzResult: fakePassportMrz,
          statesDuringRead: [
            DocumentReaderConnecting(),
            DocumentReaderReadingCardAccess(),
            DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
            DocumentReaderActiveAuthentication(),
            DocumentReaderSuccess(),
          ],
        );
        // The issuer decides whether face verification applies, never the
        // wallet: without an announcement the step is skipped even though a
        // fully capable liveness service is injected.
        final fakeIssuer = FakePassportIssuer(faceVerification: null);
        final fakeFace = FakeRegulaFaceService(transactionId: "txn-unused");

        await navigateToPassportNfcReadingScreen(
          tester,
          irmaBinding,
          fakeReader,
          fakeIssuer,
          regulaFaceService: fakeFace,
        );

        await tester.waitFor(find.byType(NfcReadingScreen));
        await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
        // Reaching the issuer at all proves the step was skipped: an intro
        // screen would sit there waiting for a tap that never comes.
        await tester.pumpUntil(() => fakeIssuer.lastIssuedData != null);

        // Straight to issuance: no intro screen, no liveness session, no
        // transaction id on the issuance request.
        expect(find.byType(FaceVerificationIntroScreen), findsNothing);
        expect(fakeFace.captureCount, 0);
        expect(fakeIssuer.lastIssuedData, isNotNull);
        expect(fakeIssuer.lastIssuedData!.livenessTransactionId, isNull);
      },
    );

    testWidgets(
      "nfc disabled shows disabled UI and retry cancels current attempt",
      (tester) async {
        final fakeReader = FakePassportReader(
          mrzResult: fakePassportMrz,
          initialState: DocumentReaderNfcUnavailable(),
        );
        final fakeIssuer = FakePassportIssuer();

        await navigateToPassportNfcReadingScreen(
          tester,
          irmaBinding,
          fakeReader,
          fakeIssuer,
        );

        expect(find.text("NFC disabled"), findsOneWidget);
        expect(
          find.text(
            "NFC is disabled. Please enable NFC in the system settings and try again.",
          ),
          findsOneWidget,
        );

        final retryButton = find.byKey(const Key("bottom_bar_primary"));
        await tester.tapAndSettle(retryButton);

        expect(fakeReader.cancelCount, 1);
      },
    );

    testWidgets("user can cancel NFC reading flow", (tester) async {
      final cancelCompleter = Completer<void>();
      final fakeReader = FakePassportReader(
        mrzResult: fakePassportMrz,
        statesDuringRead: [DocumentReaderConnecting()],
        readDelayCompleter: cancelCompleter,
        onCancelCompleter: cancelCompleter,
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToPassportNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tapAndSettle(startScanningButton);

      await tester.waitFor(find.text("Connecting to passport..."));

      final cancelButton = find.byKey(const Key("bottom_bar_secondary"));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.text("Cancel passport reading?"));
      await tester.tapAndSettle(find.text("Yes"));

      // cancelling the flow should return to the home page
      await tester.waitFor(find.byType(DataTab).hitTestable());

      expect(fakeReader.cancelCount, 1);
    });

    testWidgets("creating issuance session fails should show error", (
      tester,
    ) async {
      final fakeReader = FakePassportReader(
        mrzResult: fakePassportMrz,
        statesDuringRead: [
          DocumentReaderConnecting(),
          DocumentReaderReadingCardAccess(),
          DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
          DocumentReaderActiveAuthentication(),
          DocumentReaderSuccess(),
        ],
      );
      final fakeIssuer = FakePassportIssuer(
        errorToThrowOnIssuance: "Failed to create issuance session",
      );

      await navigateToPassportNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tapAndSettle(startScanningButton);

      await tester.waitFor(
        find.text("Could not read passport. Please try again."),
      );
    });
  });
}
