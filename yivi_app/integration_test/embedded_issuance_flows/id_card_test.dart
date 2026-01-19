import "dart:async";

import "package:flutter/cupertino.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";
import "package:mrz_parser/mrz_parser.dart";
import "package:vcmrtd/vcmrtd.dart";
import "package:yivi_core/src/providers/document_reader_providers.dart";
import "package:yivi_core/src/providers/passport_issuer_provider.dart";
import "package:yivi_core/src/screens/add_data/add_data_details_screen.dart";
import "package:yivi_core/src/screens/data/data_tab.dart";
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

  group("id_card", () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets("adding id_card credential opens MRZ scanner screen", (
      tester,
    ) async {
      await openIdCardDetailsScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));

      await tester.waitFor(find.byType(MrzReaderScreen<IdCardMrzParser>));
      // move back to close the camera feed...
      await tester.tapAndSettle(find.byType(YiviBackButton));
    });

    testWidgets("scanning MRZ for Dutch id card starts NFC reading flow", (
      tester,
    ) async {
      final fakeReader = FakePassportReader(
        mrzResult: fakeIdCardMrz,
        statesDuringRead: [
          DocumentReaderConnecting(),
          DocumentReaderReadingCardAccess(),
          DocumentReaderReadingDataGroup(dataGroup: "DG1", progress: 0.0),
          DocumentReaderActiveAuthentication(),
          DocumentReaderSuccess(),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await openIdCardDetailsScreen(
        tester,
        irmaBinding,
        overrides: [
          idCardReaderProvider.overrideWith((ref, mrz) {
            fakeReader.setMrz(mrz);
            return fakeReader;
          }),
          passportIssuerProvider.overrideWithValue(fakeIssuer),
        ],
      );

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(MrzReaderScreen<IdCardMrzParser>));

      final fakeMrz = PassportMrzResult(
        documentNumber: "XR0000001",
        birthDate: DateTime(1990, 1, 1),
        expiryDate: DateTime(2030, 12, 31),
        countryCode: "NLD",
        documentType: "I",
        surnames: "",
        givenNames: "",
        nationalityCountryCode: "",
        sex: .male,
        personalNumber: "",
      );

      final scannerState = tester.state<MrzReaderScreenState>(
        find.byType(MrzReaderScreen<IdCardMrzParser>),
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
      await openIdCardDetailsScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(MrzReaderScreen<IdCardMrzParser>));

      final cancelButton = find.byKey(const Key("bottom_bar_secondary"));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.byType(AddDataDetailsScreen));
    });

    testWidgets("nfc failure after MRZ scan shows retry option", (
      tester,
    ) async {
      final fakeReader = FakePassportReader(
        mrzResult: fakeIdCardMrz,
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

      await openIdCardDetailsScreen(
        tester,
        irmaBinding,
        overrides: [
          idCardReaderProvider.overrideWith((ref, mrz) {
            fakeReader.setMrz(mrz);
            return fakeReader;
          }),
          passportIssuerProvider.overrideWithValue(fakeIssuer),
        ],
      );

      await tester.tapAndSettle(find.byKey(const Key("bottom_bar_primary")));
      await tester.waitFor(find.byType(MrzReaderScreen<IdCardMrzParser>));

      final fakeMrz = PassportMrzResult(
        documentNumber: "XR0000001",
        birthDate: DateTime(1990, 1, 1),
        expiryDate: DateTime(2030, 12, 31),
        countryCode: "NLD",
        documentType: "I",
        surnames: "",
        givenNames: "",
        nationalityCountryCode: "",
        sex: .male,
        personalNumber: "",
      );

      final scannerState = tester.state<MrzReaderScreenState>(
        find.byType(MrzReaderScreen<IdCardMrzParser>),
      );
      scannerState.widget.onSuccess(fakeMrz);

      await tester.pumpAndSettle();

      // Start scanning
      await tester.waitFor(find.byType(NfcReadingScreen));
      await tester.tapAndSettle(find.text("Start scanning"));

      await tester.waitFor(
        find.text("Could not read ID-card. Please try again."),
      );
      await tester.waitFor(find.text("Timeout while waiting for ID-card tag"));

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
        mrzResult: fakeIdCardMrz,
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

      await navigateToIdCardNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tap(startScanningButton);

      expect(fakeIssuer.startSessionCount, 1);
      expect(fakeReader.readCalled, isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Success"), findsOneWidget);
      expect(
        find.text("Reading ID-card completed successfully"),
        findsOneWidget,
      );

      readCompleter.complete();
    });

    testWidgets(
      "nfc disabled shows disabled UI and retry cancels current attempt",
      (tester) async {
        final fakeReader = FakePassportReader(
          mrzResult: fakeIdCardMrz,
          initialState: DocumentReaderNfcUnavailable(),
        );
        final fakeIssuer = FakePassportIssuer();

        await navigateToIdCardNfcReadingScreen(
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
        mrzResult: fakeIdCardMrz,
        statesDuringRead: [DocumentReaderConnecting()],
        readDelayCompleter: cancelCompleter,
        onCancelCompleter: cancelCompleter,
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToIdCardNfcReadingScreen(
        tester,
        irmaBinding,
        fakeReader,
        fakeIssuer,
      );

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key("bottom_bar_primary"));
      await tester.tapAndSettle(startScanningButton);

      await tester.waitFor(find.text("Connecting to ID-card..."));

      final cancelButton = find.byKey(const Key("bottom_bar_secondary"));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.text("Cancel reading ID-card?"));
      await tester.tapAndSettle(find.text("Yes"));

      // cancelling the flow should return to the home page
      await tester.waitFor(find.byType(DataTab).hitTestable());

      expect(fakeReader.cancelCount, 1);
    });

    testWidgets("creating issuance session fails should show error", (
      tester,
    ) async {
      final fakeReader = FakePassportReader(
        mrzResult: fakeIdCardMrz,
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

      await navigateToIdCardNfcReadingScreen(
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
        find.text("Could not read ID-card. Please try again."),
      );
    });
  });
}
