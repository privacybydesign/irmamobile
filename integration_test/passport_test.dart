import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/data/passport_issuer.dart';
import 'package:irmamobile/src/data/passport_reader.dart';
import 'package:irmamobile/src/models/passport_data_result.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/providers/passport_repository_provider.dart';
import 'package:irmamobile/src/screens/add_data/add_data_details_screen.dart';
import 'package:irmamobile/src/screens/data/data_tab.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/screens/passport/mrz_reader_screen.dart';
import 'package:irmamobile/src/screens/passport/nfc_reading_screen.dart';
import 'package:irmamobile/src/screens/passport/widgets/mzr_scanner.dart';
import 'package:irmamobile/src/util/navigation.dart';
import 'package:mrz_parser/mrz_parser.dart';
import 'package:vcmrtd/vcmrtd.dart';

import 'helpers/helpers.dart';
import 'helpers/issuance_helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('passport', () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('adding passport credential opens MRZ scanner screen', (tester) async {
      await openPassportDetailsScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));

      await tester.waitFor(find.byType(MzrReaderScreen));
    });

    testWidgets('scanning MRZ for Dutch passport starts NFC reading flow', (tester) async {
      final fakeReader = FakePassportReader(
        statesDuringRead: [
          PassportReaderConnecting(),
          PassportReaderReadingCardAccess(),
          PassportReaderReadingCardSecurity(),
          PassportReaderReadingPassportData(dataGroup: 'DG1', progress: 0.0),
          PassportReaderSecurityVerification(),
          PassportReaderSuccess(result: PassportDataResult(dataGroups: {}, efSod: '')),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await openPassportDetailsScreen(
        tester,
        irmaBinding,
        overrides: [
          passportReaderProvider.overrideWith((ref) => fakeReader),
          passportIssuerProvider.overrideWithValue(fakeIssuer),
        ],
      );

      await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
      await tester.waitFor(find.byType(MzrReaderScreen));
      await tester.waitFor(find.byType(MRZScanner));

      final fakeMrz = _FakeMrzResult(
        documentNumber: 'XR0000001',
        birthDate: DateTime(1990, 1, 1),
        expiryDate: DateTime(2030, 12, 31),
        countryCode: 'NLD',
      );

      final scannerState = tester.state<MRZScannerState>(find.byType(MRZScanner));
      scannerState.widget.onSuccess(
          fakeMrz, const ['P<NLDTEST<<EXAMPLE<<<<<<<<<<<<<<<<<<<<', 'XR0000001NLD9001011M3012317<<<<<<<<<<<<<<00']);

      await tester.pumpAndSettle();

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key('bottom_bar_primary'));
      await tester.tapAndSettle(startScanningButton);

      expect(fakeReader.readCallCount, greaterThanOrEqualTo(1));
      expect(fakeReader.lastDocumentNumber, fakeMrz.documentNumber);
      expect(fakeReader.lastBirthDate, fakeMrz.birthDate);
      expect(fakeReader.lastExpiryDate, fakeMrz.expiryDate);
      expect(fakeReader.lastCountryCode, fakeMrz.countryCode);

      // await tester.waitFor(find.text('Read passport'));
    });

    testWidgets('user can cancel MRZ scanning and return to add data details', (tester) async {
      await openPassportDetailsScreen(tester, irmaBinding);

      await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
      await tester.waitFor(find.byType(MzrReaderScreen));

      final cancelButton = find.byKey(const Key('bottom_bar_secondary'));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.byType(AddDataDetailsScreen));
    });

    testWidgets('nfc failure after MRZ scan shows retry option', (tester) async {
      final fakeReader = FakePassportReader(
        statesDuringRead: [
          PassportReaderConnecting(),
          PassportReaderFailed(error: PassportReadingError.timeoutWaitingForTag),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await openPassportDetailsScreen(
        tester,
        irmaBinding,
        overrides: [
          passportReaderProvider.overrideWith((ref) => fakeReader),
          passportIssuerProvider.overrideWithValue(fakeIssuer),
        ],
      );

      await tester.tapAndSettle(find.byKey(const Key('bottom_bar_primary')));
      await tester.waitFor(find.byType(MzrReaderScreen));
      await tester.waitFor(find.byType(MRZScanner));

      final fakeMrz = _FakeMrzResult(
        documentNumber: 'XR0000001',
        birthDate: DateTime(1990, 1, 1),
        expiryDate: DateTime(2030, 12, 31),
        countryCode: 'NLD',
      );

      final scannerState = tester.state<MRZScannerState>(find.byType(MRZScanner));
      scannerState.widget.onSuccess(
          fakeMrz, const ['P<NLDTEST<<EXAMPLE<<<<<<<<<<<<<<<<<<<<', 'XR0000001NLD9001011M3012317<<<<<<<<<<<<<<00']);

      await tester.pumpAndSettle();

      // Start scanning
      await tester.waitFor(find.byType(NfcReadingScreen));
      await tester.tapAndSettle(find.text('Start scanning'));

      await tester.waitFor(find.text('Could not read passport. Please try again.'));
      await tester.waitFor(find.text('Timeout while waiting for Passport tag'));

      expect(fakeReader.readCallCount, 1);

      final retryButton = find.byKey(const Key('bottom_bar_primary'));
      await tester.tapAndSettle(retryButton);

      await tester.pumpAndSettle();

      expect(fakeReader.cancelCount, 1);
      expect(fakeReader.readCallCount, 2);
    });

    testWidgets('manual entry continues to NFC flow when NFC is enabled', (tester) async {
      final fakeResult = PassportDataResult(dataGroups: const {}, efSod: '');
      final readCompleter = Completer();
      final fakeReader = FakePassportReader(
        readDelayCompleter: readCompleter,
        statesDuringRead: [
          PassportReaderConnecting(),
          PassportReaderReadingCardAccess(),
          PassportReaderReadingCardSecurity(),
          PassportReaderReadingPassportData(dataGroup: 'DG1', progress: 0.0),
          PassportReaderSecurityVerification(),
          PassportReaderSuccess(result: fakeResult),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToNfcScreen(tester, irmaBinding, fakeReader, fakeIssuer);

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key('bottom_bar_primary'));
      await tester.tap(startScanningButton);

      expect(fakeIssuer.startSessionCount, 1);
      expect(fakeReader.readCalled, isTrue);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Passport reading completed successfully'), findsOneWidget);

      readCompleter.complete();
    });

    testWidgets('nfc disabled shows disabled UI and retry cancels current attempt', (tester) async {
      final fakeReader = FakePassportReader(initialState: PassportReaderNfcUnavailable());
      final fakeIssuer = FakePassportIssuer();

      await navigateToNfcScreen(tester, irmaBinding, fakeReader, fakeIssuer);

      expect(find.text('NFC disabled'), findsOneWidget);
      expect(
        find.text('NFC is disabled. Please enable NFC in the system settings and try again.'),
        findsOneWidget,
      );

      final retryButton = find.byKey(const Key('bottom_bar_primary'));
      await tester.tapAndSettle(retryButton);

      expect(fakeReader.cancelCount, 1);
    });

    testWidgets('user can cancel NFC reading flow', (tester) async {
      final cancelCompleter = Completer<void>();
      final fakeReader = FakePassportReader(
        statesDuringRead: [PassportReaderConnecting()],
        readDelayCompleter: cancelCompleter,
        onCancelCompleter: cancelCompleter,
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToNfcScreen(tester, irmaBinding, fakeReader, fakeIssuer);

      // Wait for NFC screen and press "Start scanning" button
      await tester.waitFor(find.byType(NfcReadingScreen));
      final startScanningButton = find.byKey(const Key('bottom_bar_primary'));
      await tester.tapAndSettle(startScanningButton);

      await tester.waitFor(find.text('Connecting to passport...'));

      final cancelButton = find.byKey(const Key('bottom_bar_secondary'));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.text('Cancel passport reading?'));
      await tester.tapAndSettle(find.text('Yes'));

      // cancelling the flow should return to the home page
      await tester.waitFor(find.byType(DataTab).hitTestable());

      expect(fakeReader.cancelCount, 1);
    });
  });
}

Future<void> navigateToNfcScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding,
  FakePassportReader reader,
  FakePassportIssuer issuer,
) async {
  await pumpAndUnlockApp(
    tester,
    binding.repository,
    null,
    [
      passportReaderProvider.overrideWith((ref) => reader),
      passportIssuerProvider.overrideWithValue(issuer),
    ],
  );

  final homeContext = tester.element(find.byType(HomeScreen));
  homeContext.pushPassportManualEnterScreen();
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('document_nr_input_field')), 'AB1234567');
  await tester.enterText(find.byKey(const Key('passport_dob_field')), '1990-01-01');
  await tester.enterText(find.byKey(const Key('passport_expiry_date_field')), '2030-12-31');

  final continueButton = find.byKey(const Key('bottom_bar_primary'));
  await tester.waitFor(continueButton.hitTestable());
  await tester.tapAndSettle(continueButton);

  await tester.pump(const Duration(seconds: 1));
}

Future<void> openPassportDetailsScreen(
  WidgetTester tester,
  IntegrationTestIrmaBinding binding, {
  List<Override> overrides = const [],
}) async {
  await pumpAndUnlockApp(
    tester,
    binding.repository,
    null,
    overrides.isEmpty ? null : overrides,
  );

  final addDataButton = find.byIcon(CupertinoIcons.add_circled_solid);
  await tester.tapAndSettle(addDataButton);

  final passportCredential =
      binding.repository.irmaConfiguration.credentialTypes.values.firstWhere((type) => type.id == 'passport');

  final passportTile = find.byKey(Key('${passportCredential.fullId}_tile'));
  await tester.scrollUntilVisible(
    passportTile,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tapAndSettle(passportTile);

  await tester.waitFor(find.byType(AddDataDetailsScreen));
}

class FakePassportIssuer implements PassportIssuer {
  int startSessionCount = 0;

  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async {
    startSessionCount += 1;
    return NonceAndSessionId(nonce: 'd4e5f6a7d4e5f6a7', sessionId: '4f3c2a1b5e6d7c8f9a0b1c2d3e4f5a6b');
  }

  @override
  Future<SessionPointer> startIrmaIssuanceSession(PassportDataResult passportDataResult) async {
    final attributes = createMunicipalityPersonalDataAttributes(const Locale('en'));
    final session = await createIssuanceSession(attributes: attributes);
    return session;
  }
}

class FakePassportReader extends PassportReader {
  FakePassportReader({
    PassportReaderState? initialState,
    List<PassportReaderState> statesDuringRead = const [],
    this.readDelayCompleter,
    this.onCancelCompleter,
  })  : _initialState = initialState,
        _statesDuringRead = statesDuringRead,
        super(_FakeNfcProvider()) {
    if (_initialState != null) {
      state = _initialState;
    }
  }

  @override
  Future<void> checkNfcAvailability() async {
    await Future.delayed(Duration.zero);
  }

  final PassportReaderState? _initialState;
  final List<PassportReaderState> _statesDuringRead;
  final Completer<void>? readDelayCompleter;
  final Completer<void>? onCancelCompleter;

  bool readCalled = false;
  int readCallCount = 0;
  int cancelCount = 0;
  String? lastDocumentNumber;
  DateTime? lastBirthDate;
  DateTime? lastExpiryDate;
  String? lastCountryCode;

  @override
  Future<PassportDataResult?> readWithMRZ({
    required IosNfcMessages iosNfcMessages,
    required String documentNumber,
    required DateTime birthDate,
    required DateTime expiryDate,
    required String? countryCode,
    required String sessionId,
    required Uint8List nonce,
  }) async {
    readCalled = true;
    readCallCount += 1;
    lastDocumentNumber = documentNumber;
    lastBirthDate = birthDate;
    lastExpiryDate = expiryDate;
    lastCountryCode = countryCode;

    if (state is PassportReaderNfcUnavailable) {
      return null;
    }

    for (final next in _statesDuringRead) {
      state = next;
      await Future<void>.delayed(Duration(milliseconds: 10));
    }

    if (readDelayCompleter != null) {
      await readDelayCompleter!.future;
    }

    if (state case PassportReaderSuccess(result: final result)) {
      return result;
    }

    return null;
  }

  @override
  Future<void> cancel() async {
    cancelCount += 1;
    state = PassportReaderCancelling();
    await Future<void>.delayed(Duration.zero);
    state = PassportReaderCancelled();
    if (onCancelCompleter != null && !onCancelCompleter!.isCompleted) {
      onCancelCompleter!.complete();
    }
  }
}

class _FakeMrzResult implements MRZResult {
  _FakeMrzResult({
    required this.documentNumber,
    required this.birthDate,
    required this.expiryDate,
    required this.countryCode,
  });

  @override
  final String documentNumber;

  @override
  final DateTime birthDate;

  @override
  final DateTime expiryDate;

  @override
  final String countryCode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNfcProvider extends NfcProvider {
  bool _connected = false;

  @override
  Future<void> connect({Duration? timeout, String iosAlertMessage = ''}) async {
    _connected = true;
  }

  @override
  Future<void> disconnect({String? iosAlertMessage, String? iosErrorMessage}) async {
    _connected = false;
  }

  @override
  bool isConnected() => _connected;

  @override
  Future<void> setIosAlertMessage(String message) async {
    // Do nothing.
  }
}
