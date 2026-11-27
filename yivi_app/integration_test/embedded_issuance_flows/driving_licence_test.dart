import "dart:async";

import "package:cupertino_ui/cupertino_ui.dart";
import "package:flutter/foundation.dart" show defaultTargetPlatform;
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/document_instruction_screen.dart";
import "package:yivi_core/src/screens/embedded_issuance_flows/documents/mrz_reader_screen.dart";
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

  group("driving_licence", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("adding driving licence credential opens MRZ scanner screen", (
      tester,
    ) async {
      await openDrivingLicenceInstructionScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      await tester.waitFor(
        find.byType(MrzReaderScreen<DrivingLicenceMrzParser>),
      );
      // move back to close the camera feed...
      await tester.tapAndSettle(find.byType(YiviBackButton));
    });

    testWidgets(
      "scanning MRZ for Dutch driving licence starts NFC reading flow",
      (tester) async {
        final fakeReader = FakeDrivingLicenceReader(
          statesDuringRead: [
            DocumentReaderConnecting(),
            DocumentReaderReadingCardAccess(),
            DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
            DocumentReaderActiveAuthentication(),
            DocumentReaderSuccess(),
          ],
        );
        final fakeIssuer = FakePassportIssuer();

        await openDrivingLicenceInstructionScreen(
          tester,
          irmaBinding,
          overrides: [
            drivingLicenceReaderProvider.overrideWith2((mrz) {
              fakeReader.setMrz(mrz);
              return fakeReader;
            }),
            passportIssuerProvider.overrideWithValue(fakeIssuer),
          ],
        );

        await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
        await tester.waitFor(
          find.byType(MrzReaderScreen<DrivingLicenceMrzParser>),
        );

        final fakeMrz = DrivingLicenceMrzResult(
          documentType: "dl",
          configuration: "config",
          countryCode: "NLD",
          version: "version",
          documentNumber: "doc",
          randomData: "rand",
        );

        final scannerState = tester.state<MrzReaderScreenState>(
          find.byType(MrzReaderScreen<DrivingLicenceMrzParser>),
        );
        scannerState.widget.onSuccess(fakeMrz);

        await tester.pumpAndSettle();

        await startNfcReading(tester);

        expect(fakeReader.readCallCount, greaterThanOrEqualTo(1));
        expect(fakeReader.lastDocumentNumber, fakeMrz.documentNumber);
        expect(fakeReader.lastConfiguration, fakeMrz.configuration);
        expect(fakeReader.lastRandomData, fakeMrz.randomData);
        expect(fakeReader.lastCountryCode, fakeMrz.countryCode);
        expect(fakeReader.lastVersion, fakeMrz.version);
      },
    );

    testWidgets("user can cancel MRZ scanning and return to the instructions", (
      tester,
    ) async {
      await openDrivingLicenceInstructionScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(
        find.byType(MrzReaderScreen<DrivingLicenceMrzParser>),
      );

      final cancelButton = find.byKey(const Key("bottom_bar_secondary"));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.byType(DocumentInstructionScreen));
    });

    testWidgets("nfc failure after MRZ scan shows retry option", (
      tester,
    ) async {
      final fakeReader = FakeDrivingLicenceReader(
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

      await openDrivingLicenceInstructionScreen(
        tester,
        irmaBinding,
        overrides: [
          drivingLicenceReaderProvider.overrideWith2((mrz) => fakeReader),
          passportIssuerProvider.overrideWithValue(fakeIssuer),
        ],
      );

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(
        find.byType(MrzReaderScreen<DrivingLicenceMrzParser>),
      );

      final fakeMrz = DrivingLicenceMrzResult(
        documentType: "dl",
        configuration: "config",
        countryCode: "NLD",
        version: "version",
        documentNumber: "doc",
        randomData: "rand",
      );

      final scannerState = tester.state<MrzReaderScreenState>(
        find.byType(MrzReaderScreen<DrivingLicenceMrzParser>),
      );

      scannerState.widget.onSuccess(fakeMrz);

      await tester.pumpAndSettle();

      await startNfcReading(tester);

      await tester.waitFor(
        find.text("Could not read driving licence. Please try again."),
      );
      // A lost tag asks to put the phone back.
      await tester.waitFor(
        find.textContaining("Lift your phone off your driving licence"),
      );

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
      final fakeReader = FakeDrivingLicenceReader(
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

      await navigateToDrivingLicenceNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      await startNfcReading(tester, settle: false);
      // The read runs behind a privacy-screen suspension, so it takes a
      // platform-channel round trip to get going — more than the microtasks
      // the tap itself drains.
      await tester.pumpUntil(() => fakeReader.readCalled);

      expect(fakeIssuer.startSessionCount, 1);
      expect(fakeReader.readCalled, isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Your driving licence has been read"), findsOneWidget);

      readCompleter.complete();
    });

    testWidgets("nfc disabled asks to turn NFC on", (tester) async {
      final fakeReader = FakeDrivingLicenceReader(
        initialState: DocumentReaderNfcUnavailable(),
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToDrivingLicenceNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      expect(find.text("Turn on NFC"), findsOneWidget);
      expect(
        find.text(
          "Your phone uses it to read the chip in your driving licence.",
        ),
        findsOneWidget,
      );
      // Android can open the NFC settings; iOS has none to open. The test
      // does not tap it, as that would leave the app.
      expect(
        find.text("Open NFC settings"),
        defaultTargetPlatform == TargetPlatform.android
            ? findsOneWidget
            : findsNothing,
      );
      expect(find.byKey(const Key("bottom_bar_secondary")), findsOneWidget);
      expect(fakeReader.readCallCount, 0);
    });

    testWidgets("user can cancel NFC reading flow", (tester) async {
      final cancelCompleter = Completer<void>();
      final fakeReader = FakeDrivingLicenceReader(
        statesDuringRead: [DocumentReaderConnecting()],
        readDelayCompleter: cancelCompleter,
        onCancelCompleter: cancelCompleter,
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToDrivingLicenceNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      await startNfcReading(tester);

      await tester.waitFor(
        find.text("Place your phone on your driving licence"),
      );

      final cancelButton = find.byKey(const Key("bottom_bar_secondary"));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.text("Cancel reading driving licence?"));
      await tester.tapAndSettle(find.text("Yes"));

      // cancelling the flow should return to the home page
      await tester.waitFor(find.byType(DataTab).hitTestable());

      expect(fakeReader.cancelCount, 1);
    });

    testWidgets("creating issuance session fails should show error", (
      tester,
    ) async {
      final fakeReader = FakeDrivingLicenceReader(
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

      await navigateToDrivingLicenceNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      await startNfcReading(tester);

      await tester.waitFor(
        find.text("Could not read driving licence. Please try again."),
      );
    });
  });
}
