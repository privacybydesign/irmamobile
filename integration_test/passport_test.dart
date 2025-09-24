import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:irmamobile/src/data/passport_issuer.dart';
import 'package:irmamobile/src/data/passport_reader.dart';
import 'package:irmamobile/src/models/passport_data_result.dart';
import 'package:irmamobile/src/models/session.dart';
import 'package:irmamobile/src/providers/passport_repository_provider.dart';
import 'package:irmamobile/src/screens/home/home_screen.dart';
import 'package:irmamobile/src/util/navigation.dart';
import 'package:vcmrtd/vcmrtd.dart';

import 'helpers/helpers.dart';
import 'irma_binding.dart';
import 'util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final irmaBinding = IntegrationTestIrmaBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('passport', () {
    setUp(() => irmaBinding.setUp());
    tearDown(() => irmaBinding.tearDown());

    testWidgets('manual entry continues to NFC flow when NFC is enabled', (tester) async {
      final fakeResult = PassportDataResult(dataGroups: const {}, efSod: '');
      final fakeReader = FakePassportReader(
        statesDuringRead: [
          PassportReaderConnecting(),
          PassportReaderReadingCardAccess(),
          PassportReaderReadingCardSecurity(),
          PassportReaderReadingPassportData(dataGroup: 'DG1'),
          PassportReaderActiveAuthenticating(),
          PassportReaderSuccess(result: fakeResult),
        ],
      );
      final fakeIssuer = FakePassportIssuer();

      await navigateToNfcScreen(tester, irmaBinding, fakeReader, fakeIssuer);

      expect(fakeIssuer.startSessionCount, 1);
      expect(fakeReader.readCalled, isTrue);

      await tester.waitFor(find.text('NFC enabled'));
      await tester.waitFor(find.text('Success'));
      await tester.waitFor(find.text('Passport reading completed successfully'));
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

      await tester.waitFor(find.text('Connecting to passport...'));

      final cancelButton = find.byKey(const Key('bottom_bar_secondary'));
      await tester.tapAndSettle(cancelButton);

      await tester.waitFor(find.text('Cancel passport reading?'));
      await tester.tapAndSettle(find.text('Yes'));

      await tester.waitFor(find.text('Cancelled'));

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

  await tester.pumpAndSettle();
}

class FakePassportIssuer implements PassportIssuer {
  int startSessionCount = 0;

  @override
  Future<NonceAndSessionId> startSessionAtPassportIssuer() async {
    startSessionCount += 1;
    return NonceAndSessionId(nonce: '0011', sessionId: 'session-123');
  }

  @override
  Future<SessionPointer> startIrmaIssuanceSession(PassportDataResult passportDataResult) async {
    return SessionPointer(u: 'https://example.com', irmaqr: 'issue', continueOnSecondDevice: true);
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
        super(_FakeNfcProvider());

  final PassportReaderState? _initialState;
  final List<PassportReaderState> _statesDuringRead;
  final Completer<void>? readDelayCompleter;
  final Completer<void>? onCancelCompleter;

  bool readCalled = false;
  int cancelCount = 0;

  @override
  Future<void> checkNfcAvailability() async {
    if (_initialState != null) {
      state = _initialState!;
    }
  }

  @override
  Future<PassportDataResult?> readWithMRZ({
    required String documentNumber,
    required DateTime birthDate,
    required DateTime expiryDate,
    required String? countryCode,
    required String sessionId,
    required Uint8List nonce,
  }) async {
    readCalled = true;
    if (state is PassportReaderNfcUnavailable) {
      return null;
    }

    for (final next in _statesDuringRead) {
      state = next;
      await Future<void>.delayed(Duration.zero);
    }

    if (readDelayCompleter != null) {
      await readDelayCompleter!.future;
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

class _FakeNfcProvider extends NfcProvider {
  bool _connected = false;

  @override
  Future<void> connect({String? iosAlertMessage}) async {
    _connected = true;
  }

  @override
  Future<void> disconnect({String? iosErrorMessage}) async {
    _connected = false;
  }

  @override
  bool isConnected() => _connected;

  @override
  void setIosAlertMessage(String message) {}
}
